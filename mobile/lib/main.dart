import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'user_list_screen.dart';
import 'user_map_screen.dart';
import 'all_users_map_screen.dart';

void main() {
  runApp(MyApp());
}

const String baseUrl = "http://localhost:3000"; // Use your IP on real device

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Registration App',
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
              child: Text("Register / Share Info"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllUsersMapScreen()),
                );
              },
              child: Text("View All Users"),
            ),
          ],
        ),
      ),
    );
  }
}

// Share Form Screen
class ShareFormScreen extends StatefulWidget {
  @override
  _ShareFormScreenState createState() => _ShareFormScreenState();
}

class _ShareFormScreenState extends State<ShareFormScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  bool _isLoading = false;

  Future<void> _shareNow() async {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter name and number")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/share-location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'number': number}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userId = responseData['data']['id'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(userId: userId),
          ),
        );
      } else {
        print("❌ Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register User")),
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
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _shareNow,
                    child: Text("Share Now"),
                  ),
          ],
        ),
      ),
    );
  }
}

// View Data Screen
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
      appBar: AppBar(title: Text("Registered Users")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(child: Text("No users yet."))
              : ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text("${item['name']} (${item['number']})"),
                      subtitle: Text("User ID: ${item['id']}"),
                      trailing:
                          Text(item['timestamp'].toString().split('T')[0]),
                    );
                  },
                ),
    );
  }
}

// Confirmation Screen
class ConfirmationScreen extends StatefulWidget {
  final String userId;

  const ConfirmationScreen({required this.userId});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  Timer? _locationTimer;
  bool _isSharing = false;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startSharingLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    _isSharing = true;

    _locationTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        final response = await http.post(
          Uri.parse('$baseUrl/send-location'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': widget.userId,
            'lat': position.latitude,
            'lng': position.longitude,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("📍 Sent location: ${data['data']}");
        } else {
          print("❌ Failed to send location.");
        }
      } catch (e) {
        print("❌ Location error: $e");
      }
    });
  }

  void _stopSharingLocation() {
    _locationTimer?.cancel();
    _isSharing = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Stopped sharing location")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registration Complete")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text("✅ Registration Successful!", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text("Your User ID:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              widget.userId,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: Text("Back to Home"),
            ),
            SizedBox(height: 10),
            _isSharing
                ? ElevatedButton(
                    onPressed: _stopSharingLocation,
                    child: Text("Stop Sharing Location"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                : ElevatedButton(
                    onPressed: _startSharingLocation,
                    child: Text("Start Sharing Location"),
                  ),
          ],
        ),
      ),
    );
  }
}
