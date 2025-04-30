import 'package:flutter/material.dart';

class AvailableRoomsPage extends StatefulWidget {
  const AvailableRoomsPage({Key? key}) : super(key: key);

  @override
  State<AvailableRoomsPage> createState() => _AvailableRoomsPageState();
}

class _AvailableRoomsPageState extends State<AvailableRoomsPage> {
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 7));

  final List<String> buildings = ['All', 'Building A', 'Building B', 'Building C'];
  final List<String> floors = ['All', '1st Floor', '2nd Floor', '3rd Floor'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rooms'),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Building Filter
                DropdownButtonFormField<String>(
                  value: selectedBuilding,
                  decoration: const InputDecoration(
                    labelText: 'Building',
                    border: OutlineInputBorder(),
                  ),
                  items: buildings.map((String building) {
                    return DropdownMenuItem<String>(
                      value: building,
                      child: Text(building),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBuilding = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Floor Filter
                DropdownButtonFormField<String>(
                  value: selectedFloor,
                  decoration: const InputDecoration(
                    labelText: 'Floor',
                    border: OutlineInputBorder(),
                  ),
                  items: floors.map((String floor) {
                    return DropdownMenuItem<String>(
                      value: floor,
                      child: Text(floor),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFloor = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Range Filter
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null && picked != startDate) {
                            setState(() {
                              startDate = picked;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate;
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${startDate.day}/${startDate.month}/${startDate.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null && picked != endDate) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${endDate.day}/${endDate.month}/${endDate.year}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rooms List
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Replace with actual room count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.meeting_room),
                    title: Text('Room ${index + 101}'),
                    subtitle: Text('Building ${String.fromCharCode(65 + (index % 3))} - Floor ${(index % 3) + 1}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/room-detail',
                        arguments: {
                          'roomId': index + 101,
                          'building': String.fromCharCode(65 + (index % 3)),
                          'floor': (index % 3) + 1,
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 