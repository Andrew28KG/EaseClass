import 'package:flutter/material.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({Key? key}) : super(key: key);

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  DateTime selectedDate = DateTime.now();
  String selectedTimeSlot = '';

  final List<String> timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int roomId = args['roomId'];
    final String building = args['building'];
    final int floor = args['floor'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Room $roomId'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: const Center(
                  child: Icon(Icons.meeting_room, size: 100),
                ),
              ),
              const SizedBox(height: 20),

              // Room Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Room Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Building', building),
                      _buildInfoRow('Floor', 'Floor $floor'),
                      _buildInfoRow('Capacity', '30 students'),
                      _buildInfoRow('Equipment', 'Projector, Whiteboard, Air Conditioning'),
                      _buildInfoRow('Room Type', 'Classroom'),
                      _buildInfoRow('Status', 'Available'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                      selectedTimeSlot = ''; // Reset time slot when date changes
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Slots
              const Text(
                'Available Time Slots',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = timeSlots[index];
                  final isSelected = timeSlot == selectedTimeSlot;
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(timeSlot),
                      trailing: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedTimeSlot = timeSlot;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.blue : Colors.grey,
                        ),
                        child: Text(isSelected ? 'Selected' : 'Select'),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Book Button
              if (selectedTimeSlot.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking confirmation
                      Navigator.pushNamed(
                        context,
                        '/booking-confirmation',
                        arguments: {
                          'roomId': roomId,
                          'building': building,
                          'floor': floor,
                          'date': '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          'timeSlot': selectedTimeSlot,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Book This Room'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
} 