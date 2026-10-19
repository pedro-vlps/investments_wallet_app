import 'package:flutter/material.dart';
import '../domain/report_document.dart';

class ReportIssuesList extends StatelessWidget {
  const ReportIssuesList({required this.issues, super.key});
  final List<ReportIssue> issues;
  @override
  Widget build(BuildContext context) => issues.isEmpty
      ? const SizedBox.shrink()
      : ExpansionTile(
          key: const PageStorageKey('ignored-lines-expanded'),
          title: Text('${issues.length} linha(s) ignorada(s)'),
          children: [
            SizedBox(
              height: 180,
              child: ListView.builder(
                key: const PageStorageKey('ignored-lines-scroll'),
                primary: false,
                itemCount: issues.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(issues[index].reason),
                  subtitle: Text(issues[index].location),
                ),
              ),
            ),
          ],
        );
}
