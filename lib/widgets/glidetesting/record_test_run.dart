import 'package:flutter/material.dart';
import 'package:skidpark/database/database.dart';

class RecordTestRun extends StatefulWidget {
  final StoredSkiData testSki;

  const RecordTestRun({super.key, required this.testSki});

  @override
  State<RecordTestRun> createState() => _RecordTestRunState();
}

class _RecordTestRunState extends State<RecordTestRun> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
