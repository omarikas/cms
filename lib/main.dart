import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ntlm/ntlm.dart';

import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:html/parser.dart' as parser;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class Course {
  final String name;
  final String status;
  final String season;

  Course({required this.name, required this.status, required this.season});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Course> _counter = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      NTLMClient client = NTLMClient(
        username: "omar.sayed",
        password: "?",
      );
      final response = await client.get(Uri.parse("https://cms.guc.edu.eg/apps/student/HomePageStn.aspx"));

      setState(() {
        final document = parser.parse(response.body);
        final table = document.getElementById('ContentPlaceHolderright_ContentPlaceHoldercontent_GridViewcourses');
        if (table == null) return;

        final rows = table.getElementsByTagName('tr');
        for (var i = 1; i < rows.length; i++) {
          final cells = rows[i].getElementsByTagName('td');
          if (cells.length >= 4) {
            final name = cells[1].text.trim();
            final status = cells[2].text.trim();
            final season = cells[3].text.trim();

            _counter.add(Course(name: name, status: status, season: season));
          }
        }
      });
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Courses")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16.0,
                      dataRowHeight: 60.0,
                      columns: [
                        DataColumn(label: Expanded(child: Text("Name", textAlign: TextAlign.center))),
                        DataColumn(label: Expanded(child: Text("Status", textAlign: TextAlign.center))),
                        DataColumn(label: Expanded(child: Text("Season", textAlign: TextAlign.center))),
                      ],
                      rows: _counter
                          .map(
                            (course) => DataRow(
                              cells: [
                                DataCell(Center(child: Text(course.name))),
                                DataCell(Center(child: Text(course.status))),
                                DataCell(Center(child: Text(course.season))),
                              ],
                              onSelectChanged: (selected) {
                                if (selected == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseDetailScreen(
                                        title: extractCourseId(course.name),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String extractCourseId(String input) {
  final regex = RegExp(r'\((\d+)\)');
  final match = regex.firstMatch(input);
  return match != null ? match.group(1)! : '';
}

class CourseDetailScreen extends StatefulWidget {
  CourseDetailScreen({super.key, required this.title});

  final String title;

  @override
  State<CourseDetailScreen> createState() => CourseDetailScreenState();
}

class CourseDetailScreenState extends State<CourseDetailScreen> {
  late String title;
  List<WeekContent> weeks = <WeekContent>[];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    fetchData();
  }

  void fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      NTLMClient client = NTLMClient(
        username: "omar.sayed",
        password: "?",
      );
      final response = await client.get(Uri.parse('https://cms.guc.edu.eg/apps/student/CourseViewStn.aspx?id=$title&sid=64'));

      setState(() {
        final document = parser.parse(response.body);
        final weekDivs = document.getElementsByClassName('card mb-5 weeksdata');

        for (var weekDiv in weekDivs) {
          final descriptionElement = weekDiv.querySelector('p.m-2.p2');
          final weekDescription = descriptionElement?.text.trim() ?? 'No description';

          final contentCards = weekDiv.querySelectorAll('.card.mb-4');
          for (var contentCard in contentCards) {
            final contentElement = contentCard.querySelector('div[id^="content"]');
            final contentDescription = contentElement?.text.trim() ?? 'No content description';

            final downloadButton = contentCard.querySelector('a.btn.btn-primary.contentbtn');
            final downloadLink = downloadButton?.attributes['href'] ?? 'No link';

            weeks.add(WeekContent(
              weekDescription: weekDescription,
              contentDescription: contentDescription,
              downloadLink: downloadLink,
            ));
          }
        }
      });
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Week Content')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                final weekContent = weeks[index];

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekContent.weekDescription,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          weekContent.contentDescription,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              NTLMClient client = NTLMClient(
                                username: "omar.sayed",
                                password: "?",
                              );
                              final response = await client.get(Uri.parse("https://cms.guc.edu.eg" + weekContent.downloadLink));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HtmlInWebViewPage(html: response.bodyBytes),
                                  ));
                            } catch (error) {
                              print(error);
                            }
                          },
                          icon: Icon(Icons.download),
                          label: Text('Download'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class WeekContent {
  final String weekDescription;
  final String contentDescription;
  final String downloadLink;

  WeekContent({
    required this.weekDescription,
    required this.contentDescription,
    required this.downloadLink,
  });
}

class HtmlInWebViewPage extends StatefulWidget {
  HtmlInWebViewPage({required this.html});

  Uint8List html;

  @override
  _HtmlInWebViewPageState createState() => _HtmlInWebViewPageState();
}

class _HtmlInWebViewPageState extends State<HtmlInWebViewPage> {
  late Uint8List? html;

  @override
  void initState() {
    super.initState();
    html = widget.html;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView Example'),
      ),
      body: PDFView(
        pdfData: html,
      ),
    );
  }
}
