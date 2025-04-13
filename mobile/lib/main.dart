import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

const String baseUrl = "http://localhost:3000"; // Use your PC IP on real device http://localhost:3000/dashboard

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Share App',
      home: SplashScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          Center(child: Text('Splash Screen', style: TextStyle(fontSize: 24))),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  void _goToShareForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShareFormScreen()),
    );
  }

  void _goToViewData(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewDataScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _goToShareForm(context),
              child: Text("Share Info"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _goToViewData(context),
              child: Text("View Shared Data"),
            ),
          ],
        ),
      ),
    );
  }
}

// Share Form Screen (no location)
class ShareFormScreen extends StatefulWidget {
  @override
  _ShareFormScreenState createState() => _ShareFormScreenState();
}

class _ShareFormScreenState extends State<ShareFormScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  Future<void> _shareNow() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      print("❗ Name and number are required");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/share-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'number': number}),
      );

      if (response.statusCode == 200) {
        print("✅ Sent to backend:");
        print(jsonDecode(response.body));
      } else {
        print("❌ Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Share Info")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Phone Number"),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _shareNow,
              child: Text("Share Now"),
            ),
          ],
        ),
      ),
    );
  }
}

// View shared data
class ViewDataScreen extends StatefulWidget {
  @override
  _ViewDataScreenState createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends State<ViewDataScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations'));
      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("❌ Error loading data: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shared Data")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text("No data shared yet."))
              : ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text("${item['name']} (${item['number']})"),
                      subtitle: Text(
                          "Shared at: ${item['timestamp'].toString().split('T')[0]}"),
                    );
                  },
                ),
    );
  }
}
