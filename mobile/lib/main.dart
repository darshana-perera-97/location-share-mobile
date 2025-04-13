import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location App',
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
      body: Center(
        child: Text('Splash Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// Home Screen with two buttons
class HomeScreen extends StatelessWidget {
  void _goToShareForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShareLocationFormScreen()),
    );
  }

  Future<void> _viewLocations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('locations') ?? [];

    print("Shared Data:");
    for (var entry in data) {
      var decoded = jsonDecode(entry);
      print(
          "${decoded['name']} | ${decoded['number']} | ${decoded['lat']}, ${decoded['lng']}");
    }
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
              child: Text("Share Location"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _viewLocations,
              child: Text("View Locations"),
            ),
          ],
        ),
      ),
    );
  }
}

// New Page: Share Location Form
class ShareLocationFormScreen extends StatefulWidget {
  @override
  _ShareLocationFormScreenState createState() =>
      _ShareLocationFormScreenState();
}

class _ShareLocationFormScreenState extends State<ShareLocationFormScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  Future<void> _shareNow() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter name and number")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existing = prefs.getStringList('locations') ?? [];

    Map<String, dynamic> newEntry = {
      'name': name,
      'number': number,
      'lat': position.latitude,
      'lng': position.longitude,
    };

    existing.add(jsonEncode(newEntry));
    await prefs.setStringList('locations', existing);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location shared successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Share Your Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: Text("Share Location Now"),
            ),
          ],
        ),
      ),
    );
  }
}
