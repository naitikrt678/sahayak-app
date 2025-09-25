import 'package:flutter/material.dart';

class CivicOfficersScreen extends StatefulWidget {
  const CivicOfficersScreen({super.key});

  @override
  State<CivicOfficersScreen> createState() => _CivicOfficersScreenState();
}

class _CivicOfficersScreenState extends State<CivicOfficersScreen> {
  // Mock data for civic officers - will be connected to backend later
  final List<CivicOfficer> _officers = [
    CivicOfficer(
      id: '1',
      name: 'Rajesh Kumar',
      designation: 'Sub-Divisional Officer',
      department: 'Public Works Department',
      office: 'PWD Office, Ranchi',
      address: 'Kutchery Road, Ranchi - 834001',
      phone: '+91 9876543210',
      email: 'rajesh.kumar@jharkhand.gov.in',
      distance: '2.3 km',
      availability: 'Available',
      profileImage: 'assets/images/officer1.jpg',
    ),
    CivicOfficer(
      id: '2',
      name: 'Priya Singh',
      designation: 'Municipal Engineer',
      department: 'Municipal Corporation',
      office: 'Ranchi Municipal Corporation',
      address: 'Upper Bazar, Ranchi - 834001',
      phone: '+91 9876543211',
      email: 'priya.singh@ranchimunicipal.gov.in',
      distance: '3.1 km',
      availability: 'Busy',
      profileImage: 'assets/images/officer2.jpg',
    ),
    CivicOfficer(
      id: '3',
      name: 'Amit Sharma',
      designation: 'Health Officer',
      department: 'Health Department',
      office: 'District Health Office',
      address: 'HEC Township, Ranchi - 834004',
      phone: '+91 9876543212',
      email: 'amit.sharma@health.jharkhand.gov.in',
      distance: '4.7 km',
      availability: 'Available',
      profileImage: 'assets/images/officer3.jpg',
    ),
    CivicOfficer(
      id: '4',
      name: 'Sunita Devi',
      designation: 'Social Welfare Officer',
      department: 'Social Welfare Department',
      office: 'Social Welfare Office',
      address: 'Kanke Road, Ranchi - 834008',
      phone: '+91 9876543213',
      email: 'sunita.devi@socialwelfare.jharkhand.gov.in',
      distance: '5.2 km',
      availability: 'Available',
      profileImage: 'assets/images/officer4.jpg',
    ),
    CivicOfficer(
      id: '5',
      name: 'Manoj Tiwari',
      designation: 'Traffic Inspector',
      department: 'Traffic Police',
      office: 'Traffic Police Station',
      address: 'Main Road, Ranchi - 834001',
      phone: '+91 9876543214',
      email: 'manoj.tiwari@jharkhandpolice.gov.in',
      distance: '1.8 km',
      availability: 'Available',
      profileImage: 'assets/images/officer5.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Civic Officers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF4CAF50),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search officers...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Officers near you',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_officers.length} found',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Officers List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _officers.length,
              itemBuilder: (context, index) {
                final officer = _officers[index];
                return _buildOfficerCard(officer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(CivicOfficer officer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Officer Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: Text(
                    officer.name.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        officer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        officer.designation,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            officer.distance,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: officer.availability == 'Available'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              officer.availability,
                              style: TextStyle(
                                fontSize: 10,
                                color: officer.availability == 'Available'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Department and Office
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          officer.department,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          officer.office,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callOfficer(officer),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _messageOfficer(officer),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _viewOfficerDetails(officer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callOfficer(CivicOfficer officer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call ${officer.name}'),
        content: Text('Call ${officer.phone}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual calling functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${officer.name}...'),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _messageOfficer(CivicOfficer officer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message ${officer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual messaging functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to ${officer.name}'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _viewOfficerDetails(CivicOfficer officer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  officer.name.split(' ').map((n) => n[0]).join(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    officer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    officer.designation,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.business, 'Department', officer.department),
            _buildDetailRow(Icons.place, 'Office', officer.office),
            _buildDetailRow(Icons.location_on, 'Address', officer.address),
            _buildDetailRow(Icons.phone, 'Phone', officer.phone),
            _buildDetailRow(Icons.email, 'Email', officer.email),
            _buildDetailRow(Icons.access_time, 'Distance', officer.distance),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CivicOfficer {
  final String id;
  final String name;
  final String designation;
  final String department;
  final String office;
  final String address;
  final String phone;
  final String email;
  final String distance;
  final String availability;
  final String profileImage;

  CivicOfficer({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.office,
    required this.address,
    required this.phone,
    required this.email,
    required this.distance,
    required this.availability,
    required this.profileImage,
  });
}
