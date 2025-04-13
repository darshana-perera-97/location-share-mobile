import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = "http://localhost:3000";

class AllUsersMapScreen extends StatefulWidget {
  @override
  _AllUsersMapScreenState createState() => _AllUsersMapScreenState();
}

class _AllUsersMapScreenState extends State<AllUsersMapScreen> {
  late GoogleMapController mapController;
  List<Marker> _markers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserLocations();
  }

  Future<void> _loadAllUserLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations'));

      if (response.statusCode == 200) {
        final allUsers = jsonDecode(response.body);

        // Group locations by userId
        Map<String, dynamic> latestLocations = {};
        for (var entry in allUsers) {
          final id = entry['userId'];
          latestLocations[id] = entry; // overwrites to get latest
        }

        List<Marker> markers = [];

        int count = 0;
        latestLocations.forEach((userId, entry) {
          final lat = entry['location']['lat'];
          final lng = entry['location']['lng'];

          markers.add(
            Marker(
              markerId: MarkerId("user_$count"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: userId,
                snippet: entry['timestamp'].toString(),
              ),
            ),
          );
          count++;
        });

        setState(() {
          _markers = markers;
          _loading = false;
        });
      } else {
        throw Exception("Failed to load locations");
      }
    } catch (e) {
      print("❌ Error loading all user locations: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Users on Map")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _markers.isNotEmpty
                    ? _markers.last.position
                    : LatLng(20, 77), // Default to India if empty
                zoom: 4,
              ),
              markers: Set<Marker>.of(_markers),
            ),
    );
  }
}
