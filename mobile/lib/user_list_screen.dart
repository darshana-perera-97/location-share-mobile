import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'user_map_screen.dart';

const String baseUrl = "http://localhost:3000";

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/locations'));
      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        throw Exception("Failed to load users");
      }
    } catch (e) {
      print("❌ Error loading users: $e");
      setState(() => _loading = false);
    }
  }

  void _goToUserMap(BuildContext context, String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserMapScreen(userId: userId, userName: userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Registered Users")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text("No users registered yet."))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final item = _users[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text("${item['name']} (${item['number']})"),
                        subtitle: Text("User ID: ${item['id']}"),
                        trailing: ElevatedButton(
                          onPressed: () => _goToUserMap(
                            context,
                            item['id'],
                            item['name'],
                          ),
                          child: Text("View Locations"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
