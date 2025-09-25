import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/upload_diagnostic_service.dart';

class UploadDiagnosticScreen extends StatefulWidget {
  const UploadDiagnosticScreen({super.key});

  @override
  State<UploadDiagnosticScreen> createState() => _UploadDiagnosticScreenState();
}

class _UploadDiagnosticScreenState extends State<UploadDiagnosticScreen> {
  DiagnosticResult? _result;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final result = await UploadDiagnosticService.runDiagnostics();
      setState(() {
        _result = result;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Diagnostics',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isRunning ? null : _runDiagnostics,
          ),
        ],
      ),
      body: _isRunning ? _buildLoadingView() : _buildResultView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
          SizedBox(height: 20),
          Text(
            'Running Upload Diagnostics...',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          SizedBox(height: 10),
          Text(
            'Checking configuration, connections, and permissions',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_result == null) {
      return const Center(
        child: Text(
          'Failed to run diagnostics',
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(),

          const SizedBox(height: 20),

          // Individual Checks
          const Text(
            'Diagnostic Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 15),

          ...(_result!.checks.map((check) => _buildCheckCard(check))),

          const SizedBox(height: 20),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final result = _result!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            result.canUpload ? Icons.cloud_upload : Icons.cloud_off,
            size: 50,
            color: result.canUpload ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 15),

          Text(
            result.summary,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreItem('Passed', result.passedCount, Colors.green),
              _buildScoreItem('Failed', result.failedCount, Colors.red),
              _buildScoreItem(
                'Score',
                '${(result.overallScore * 100).round()}%',
                Colors.blue,
              ),
            ],
          ),

          if (result.criticalFailures > 0) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${result.criticalFailures} critical issue${result.criticalFailures > 1 ? 's' : ''} must be fixed before uploads will work',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildCheckCard(DiagnosticCheck check) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: check.color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(check.icon, color: check.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  check.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (check.critical)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CRITICAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            check.message,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          if (check.details != null) ...[
            const SizedBox(height: 8),
            Text(
              check.details!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (!check.passed && check.solution != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check.solution!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _runDiagnostics,
            icon: const Icon(Icons.refresh),
            label: const Text('Run Diagnostics Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Help Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            label: const Text('Troubleshooting Guide'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Troubleshooting'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Common Upload Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('1. Missing "reports" storage bucket in Supabase'),
              Text('2. Row Level Security blocking anonymous users'),
              Text('3. App in Mock Mode (saves locally only)'),
              Text('4. Network connectivity issues'),
              Text('5. Incorrect Supabase credentials'),
              SizedBox(height: 15),
              Text(
                'Quick Fixes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('• Create "reports" bucket in Supabase Dashboard'),
              Text('• Disable RLS on reports table temporarily'),
              Text('• Check Profile → Settings → "Use Mock Data"'),
              Text('• Verify internet connection'),
              Text('• Check .env file configuration'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(
                const ClipboardData(
                  text:
                      'UPLOAD_TROUBLESHOOTING.md - Check the troubleshooting guide in the project files',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Troubleshooting guide reference copied'),
                ),
              );
            },
            child: const Text('Copy Guide'),
          ),
        ],
      ),
    );
  }
}
