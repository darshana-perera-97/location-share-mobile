import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const String baseUrl = "http://localhost:3000"; // Same as in main.dart

class UserMapScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserMapScreen({required this.userId, required this.userName});

  @override
  _UserMapScreenState createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  late GoogleMapController mapController;
  List<Marker> _markers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocations();
  }

  Future<void> _loadUserLocations() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/locations/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Marker> markers = [];

        for (int i = 0; i < data.length; i++) {
          final loc = data[i];
          final lat = loc['location']['lat'];
          final lng = loc['location']['lng'];

          markers.add(
            Marker(
              markerId: MarkerId("loc_$i"),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: loc['timestamp'].toString()),
            ),
          );
        }

        setState(() {
          _markers = markers;
          _loading = false;
        });
      } else {
        throw Exception("Failed to load user locations");
      }
    } catch (e) {
      print("❌ Error loading map: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userName}'s Location History")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _markers.isNotEmpty
                    ? _markers.last.position
                    : LatLng(0, 0),
                zoom: 14,
              ),
              markers: Set<Marker>.of(_markers),
            ),
    );
  }
}
