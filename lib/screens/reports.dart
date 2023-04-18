import 'reportView.dart';
import 'upload_document.dart';
import 'package:flutter/material.dart';

const List<String> typeOfReports = [
  "Electrocardiogram (ECG)",
  "Blood Test",
  "CT scan",
  "MRI scan",
  "X-ray",
  "Ultrasound",
  "General Report",
];

class Reports extends StatefulWidget {
  const Reports({super.key});
  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadDocument(),
            ),
          );
        },
        child: Icon(
          Icons.add,
          size: 30.0,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 20.0,
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(12.0),
              child: Text(
                "Your uploaded reports by categories : ",
                style: TextStyle(
                  fontSize: 22.0,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return ReportListItem(
                    parentContext: context,
                    name: typeOfReports[index],
                  );
                },
                itemCount: typeOfReports.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportListItem extends StatelessWidget {
  final BuildContext parentContext;
  final String name;

  ReportListItem({required this.parentContext, required this.name});

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          parentContext,
          MaterialPageRoute(
            builder: (context) => ReportView(reportType: name),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.all(12.0),
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            border: Border.all(
              width: 1.0,
              color: Theme.of(parentContext).primaryColor,
            ),
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(parentContext).primaryColor.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                  color: Colors.black,
                  offset: const Offset(5.0, 5.0),
                  blurRadius: 8.0)
            ]),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              child: Icon(
                Icons.file_copy_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 10.0,
            ),
            Text(
              "$name",
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
