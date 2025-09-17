import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/civic_report.dart';

class JsonDataService {
  static List<CivicReport> _reports = [];
  static bool _loaded = false;

  static Future<List<CivicReport>> getAllReports() async {
    if (!_loaded) {
      try {
        final json = await rootBundle.loadString('complete_dummy_data.json');
        final data = jsonDecode(json);
        _reports = (data['reports'] as List)
            .map<CivicReport>((r) => CivicReport.fromJson(r))
            .toList();
        _loaded = true;
      } catch (e) {
        _reports = [];
        _loaded = true;
      }
    }
    return _reports;
  }

  static Future<List<CivicReport>> getRecentReports() async {
    final reports = await getAllReports();
    reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reports.take(5).toList();
  }
}
