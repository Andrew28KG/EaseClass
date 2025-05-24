import 'package:flutter/material.dart';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({Key? key}) : super(key: key);

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  // Dummy data
  List<Map<String, dynamic>> rooms = [
    {'name': 'Ruang A', 'isActive': true},
    {'name': 'Ruang B', 'isActive': false},
    {'name': 'Ruang C', 'isActive': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Management'),
      ),
      body: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return SwitchListTile(
            title: Text(room['name']),
            subtitle: Text(room['isActive'] ? 'Aktif' : 'Tidak Aktif'),
            value: room['isActive'],
            onChanged: (bool value) {
              setState(() {
                rooms[index]['isActive'] = value;
              });
              // TODO: handle Firestore update
            },
          );
        },
      ),
    );
  }
}