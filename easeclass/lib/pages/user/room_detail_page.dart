import 'package:flutter/material.dart';
import '../../utils/navigation_helper.dart'; // Import navigation helper
import '../../theme/app_colors.dart'; // Import app colors
import '../../services/booking_service.dart';
import '../../models/booking_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({Key? key}) : super(key: key);

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  DateTime selectedDate = DateTime.now();
  String selectedTimeSlot = '';
  final TextEditingController _commentsController = TextEditingController();

  final List<String> timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
  ];

  // List of available equipment
  final List<String> availableEquipment = [
    'Projector',
    'Whiteboard',
    'Air Conditioning',
    'Computer',
    'Audio System',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // Since roomId could be a String or int in different parts of the app
    final roomId = args['roomId']; 
    final String building = args['building'];
    final dynamic floorValue = args['floor'];
    // Handle floor value which could be int or String
    final int floor = floorValue is int ? floorValue : int.tryParse(floorValue.toString()) ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Room $roomId', 
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or placeholder
                  Container(
                    color: AppColors.primary.withOpacity(0.7),
                    child: const Icon(
                      Icons.meeting_room,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.business, 'Building $building'),
                      _buildInfoChip(Icons.stairs, 'Floor $floor'),
                      _buildInfoChip(Icons.people, '30 students'),
                      _buildInfoChip(Icons.meeting_room, 'Classroom'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Room Details Section
                  _buildSectionHeader('Room Details'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Equipment section with expandable details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.computer, color: AppColors.secondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Available Equipment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Display equipment list in a wrap layout
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: availableEquipment.map((item) => 
                                        Chip(
                                          avatar: const Icon(
                                            Icons.check_circle, 
                                            size: 16, 
                                            color: Colors.green,
                                          ),
                                          label: Text(item),
                                          backgroundColor: Colors.grey.shade50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        )
                                      ).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          
                          // Status and availability info
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Room Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Available for booking',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Booking details section
                  _buildSectionHeader('Book This Room'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date selector
                          const Text(
                            'Select Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              // Prevent showing dialogs during build/layout phase
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                
                                // Use a bottom sheet instead of a date picker to prevent navigation issues
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (bottomSheetContext) => SafeArea(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                "Select Date",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () => Navigator.pop(bottomSheetContext),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Use a CalendarDatePicker to avoid navigation issues
                                          CalendarDatePicker(
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 30)),
                                            onDateChanged: (newDate) {
                                              if (mounted) {
                                                setState(() {
                                                  selectedDate = newDate;
                                                  selectedTimeSlot = ''; // Reset time slot when date changes
                                                });
                                                // Close the bottom sheet
                                                Navigator.pop(bottomSheetContext);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_getDayOfWeek(selectedDate)}, ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.calendar_today, color: AppColors.secondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Time slot selector
                          const Text(
                            'Select Time Slot',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timeSlots.map((timeSlot) {
                              final isSelected = timeSlot == selectedTimeSlot;
                              return ChoiceChip(
                                label: Text(timeSlot),
                                selected: isSelected,
                                selectedColor: AppColors.primary.withOpacity(0.2),
                                onSelected: (selected) {
                                  setState(() {
                                    selectedTimeSlot = selected ? timeSlot : '';
                                  });
                                },
                                avatar: Icon(
                                  Icons.access_time,
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                  size: 16,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Additional equipment and comments
                          const Text(
                            'Additional Requirements',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _commentsController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Specify any additional equipment or special requirements...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.note_add),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Book Button
                  if (selectedTimeSlot.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _handleBooking(roomId, building, floor);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Future<void> _handleBooking(String roomId, String building, int floor) async {
    if (selectedTimeSlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    try {
      final bookingService = BookingService();
      
      // Create the booking
      final booking = BookingModel(
        id: '', // Will be set by Firestore
        roomId: roomId,
        userId: '', // Will be set by the service
        date: selectedDate.toIso8601String().split('T')[0],
        time: selectedTimeSlot,
        purpose: _commentsController.text.isEmpty ? 'No purpose specified' : _commentsController.text,
        status: 'pending',
        createdAt: Timestamp.now(),
        roomDetails: {
          'name': 'Room $roomId',
          'building': building,
          'floor': floor,
        },
      );

      // Create the booking in Firestore
      await bookingService.createBooking(booking);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to booked rooms page
        Navigator.pushReplacementNamed(context, '/user/booked-rooms');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 