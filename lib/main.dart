import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ntlm/ntlm.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as html_dom;

void main() {
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false, 
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: false,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(
          title: 'Flutter Demo Home Page',
          username: username,
          password: password,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(

        padding: const EdgeInsets.all(16.0),
        child:Form(child:  Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),)
      ),
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
  const MyHomePage({super.key, required this.title, required this.username, required this.password});

  final String title;
  final String username;
  final String password;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<Course>> _counter = [];
  bool _isLoading = false;
  String season = "";

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
        username: widget.username,
        password: widget.password,
      );
      final response = await client.get(Uri.parse("https://cms.guc.edu.eg/apps/student/ViewAllCourseStn"));

      setState(() {
        final document = parser.parse(response.body);
        int id = 0;

        final regex = RegExp(r'Season\s*:\s*\d+');
        final matches = regex.allMatches(response.body);
        for (final match in matches) {
          print(match.group(0));
        }

        html_dom.Element? table = document.getElementById('ContentPlaceHolderright_ContentPlaceHoldercontent_r1_GridView1_0');
          if(table==null){
            showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Wrong user name or Password.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                },
              ),
            ],
          );
        },
      );
          }
        while (table != null) {
          List<Course> c = [];
          final rows = table.getElementsByTagName('tr');

          _counter.add([Course(name: matches.elementAtOrNull(id)!.group(0).toString(), status: '', season: '')]);

          for (var i = 1; i < rows.length; i++) {
            final cells = rows[i].getElementsByTagName('td');
            if (cells.length >= 4) {
              final name = cells[1].text.trim();
              final status = cells[2].text.trim();
              final seas = cells[3].text.trim();

              c.add(Course(name: name, status: status, season: matches.elementAtOrNull(id)!.group(0).toString().split(":")[1]));
            }
          }
          _counter.add(c);
          id++;

          print(id);
          table = document.getElementById('ContentPlaceHolderright_ContentPlaceHoldercontent_r1_GridView1_' + id.toString());
        }
      });
    } catch (error) {
     
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
        title: Text('Error'),
        content: Text('Error occured.'),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {// Go back one screen
            },
          ),
        ],
          );
        },
      );
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
                      rows: _counter.expand((courses) => courses).map(
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
                                        season: course.season,
                                        username: widget.username,
                                        password: widget.password,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ).toList(),
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
  CourseDetailScreen({super.key, required this.title, required this.season, required this.username, required this.password});

  final String title;
  final String season;
  final String username;
  final String password;

  @override
  State<CourseDetailScreen> createState() => CourseDetailScreenState();
}

class CourseDetailScreenState extends State<CourseDetailScreen> {
  late String title;
  List<WeekContent> weeks = <WeekContent>[];
  bool _isLoading = false;
  late String season;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    season = widget.season;
    fetchData();
  }

  void fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      NTLMClient client = NTLMClient(
        username: widget.username,
        password: widget.password,
      );
      final response = await client.get(Uri.parse('https://cms.guc.edu.eg/apps/student/CourseViewStn.aspx?id=$title&sid=$season'));

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
                                username: widget.username,
                                password: widget.password,
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
