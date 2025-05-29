import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/class_model.dart';
import '../../models/review.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/navigation_helper.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';

class ClassDetailPage extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailPage({
    Key? key,
    required this.classModel,
  }) : super(key: key);

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final BookingService _bookingService = BookingService();
  DateTime selectedDate = DateTime.now();
  String? selectedStartTime;
  int selectedDuration = 1;
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _extraItemsNotesController = TextEditingController();
  bool _isLoading = false;
  List<BookingModel> _existingBookingsForDate = [];
  List<String> _currentAvailableStartTimes = [];

  final List<String> _allPossibleStartTimes = List.generate(11, (index) {
    final hour = index + 7;
    final time = TimeOfDay(hour: hour, minute: 0);
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final displayHour = (hour12 == 0 || hour12 == 12) ? 12 : hour12;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${displayHour.toString().padLeft(2, '0')}:00 $period';
  });

  final List<int> _availableDurations = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _fetchBookingsAndCalculateAvailableTimes(selectedDate);
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _extraItemsNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingsAndCalculateAvailableTimes(DateTime date) async {
    setState(() {
      _isLoading = true;
      _existingBookingsForDate = [];
      _currentAvailableStartTimes = [];
      selectedStartTime = null;
    });

    try {
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      final bookings = await _bookingService.getBookingsForRoomAndDate(widget.classModel.id, formattedDate);

      setState(() {
        _existingBookingsForDate = bookings;
        _calculateAvailableStartTimes();
      });

    } catch (e) {
      print('Error fetching bookings and calculating available times: $e');
    } finally {
       setState(() {
         _isLoading = false;
       });
    }
  }

  void _calculateAvailableStartTimes() {
    final availableTimes = <String>[];
    final bookedSlots = <DateTime>[];

    // Only consider approved bookings
    final approvedBookings = _existingBookingsForDate.where((b) => b.status == 'approved').toList();

    for (var booking in approvedBookings) {
      try {
        final timeParts = booking.time.split(' ');
        final hourMinute = timeParts[0].split(':');
        final hour = int.parse(hourMinute[0]);
        final minute = int.parse(hourMinute[1]);
        final period = timeParts[1];

        int twentyFourHour = hour;
        if (period == 'PM' && hour != 12) {
          twentyFourHour += 12;
        } else if (period == 'AM' && hour == 12) {
          twentyFourHour = 0;
        }

        final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, twentyFourHour, minute);
        final end = start.add(Duration(hours: booking.duration));

        for (int i = 0; i < booking.duration; i++) {
          bookedSlots.add(start.add(Duration(hours: i)));
        }
      } catch (e) {
        print('Error parsing booking time or duration: $e');
      }
    }

    // Prepare study schedule slots for the selected day
    final String selectedDay = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ][selectedDate.weekday - 1];
    final studySlots = (widget.classModel.timeSlots ?? [])
        .where((slot) => slot.day == selectedDay)
        .toList();

    for (var startTimeString in _allPossibleStartTimes) {
      try {
        final timeParts = startTimeString.split(' ');
        final hourMinute = timeParts[0].split(':');
        final hour = int.parse(hourMinute[0]);
        final minute = int.parse(hourMinute[1]);
        final period = timeParts[1];

        int twentyFourHour = hour;
        if (period == 'PM' && hour != 12) {
          twentyFourHour += 12;
        } else if (period == 'AM' && hour == 12) {
          twentyFourHour = 0;
        }

        final potentialStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, twentyFourHour, minute);
        final potentialEnd = potentialStart.add(Duration(hours: selectedDuration));

        bool isConflict = false;

        // Check for conflict with approved bookings
        for (var bookedSlot in bookedSlots) {
          if (potentialStart.isBefore(bookedSlot.add(const Duration(hours: 1))) && potentialEnd.isAfter(bookedSlot)) {
            isConflict = true;
            break;
          }
        }

        // Check for conflict with study schedule
        for (var slot in studySlots) {
          // slot.startTime and slot.endTime are strings like '08:00 AM'
          final slotStartParts = slot.startTime.split(' ');
          final slotStartHourMinute = slotStartParts[0].split(':');
          int slotStartHour = int.parse(slotStartHourMinute[0]);
          int slotStartMinute = int.parse(slotStartHourMinute[1]);
          String slotStartPeriod = slot.startTime.contains('PM') ? 'PM' : 'AM';
          if (slotStartPeriod == 'PM' && slotStartHour != 12) slotStartHour += 12;
          if (slotStartPeriod == 'AM' && slotStartHour == 12) slotStartHour = 0;

          final slotEndParts = slot.endTime.split(' ');
          final slotEndHourMinute = slotEndParts[0].split(':');
          int slotEndHour = int.parse(slotEndHourMinute[0]);
          int slotEndMinute = int.parse(slotEndHourMinute[1]);
          String slotEndPeriod = slot.endTime.contains('PM') ? 'PM' : 'AM';
          if (slotEndPeriod == 'PM' && slotEndHour != 12) slotEndHour += 12;
          if (slotEndPeriod == 'AM' && slotEndHour == 12) slotEndHour = 0;

          final slotStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, slotStartHour, slotStartMinute);
          final slotEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, slotEndHour, slotEndMinute);

          if (potentialStart.isBefore(slotEnd) && potentialEnd.isAfter(slotStart)) {
            isConflict = true;
            break;
          }
        }

        if (!isConflict) {
          availableTimes.add(startTimeString);
        }
      } catch (e) {
        print('Error parsing possible start time: $e');
      }
    }

    setState(() {
      _currentAvailableStartTimes = availableTimes;
      if (selectedStartTime != null && !_currentAvailableStartTimes.contains(selectedStartTime)) {
        selectedStartTime = null;
      }
    });
  }

  Future<void> _bookClass() async {
    if (_purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a purpose for booking')),
      );
      return;
    }

    if (selectedStartTime == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time')),
      );
      return;
    }

    final isAvailableNow = await _checkAvailabilityBeforeBooking();
    if (!isAvailableNow) {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The selected time slot is no longer available. Please choose another time.')),
            );
            _fetchBookingsAndCalculateAvailableTimes(selectedDate);
        }
       return;
     }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final timeParts = selectedStartTime!.split(' ');
      final hourMinute = timeParts[0].split(':');
      final hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      final period = timeParts[1];

      int twentyFourHour = hour;
      if (period == 'PM' && hour != 12) {
        twentyFourHour += 12;
      } else if (period == 'AM' && hour == 12) {
        twentyFourHour = 0;
      }

      final bookingDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, twentyFourHour, minute);

      final booking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        roomId: widget.classModel.id,
        date: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
        time: selectedStartTime!,
        purpose: _purposeController.text,
        status: 'pending',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        roomDetails: {
          'name': widget.classModel.name,
          'building': widget.classModel.building,
          'floor': widget.classModel.floor,
          'capacity': widget.classModel.capacity,
          'features': widget.classModel.features,
        },
        extraItemsNotes: _extraItemsNotesController.text.isNotEmpty ? _extraItemsNotesController.text : null,
        duration: selectedDuration,
      );

      await _bookingService.createBooking(booking);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Booking Successful'),
              content: const Text('Your booking request has been submitted.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/available-classes');
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _checkAvailabilityBeforeBooking() async {
     final formattedDate = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
     final bookings = await _bookingService.getBookingsForRoomAndDate(widget.classModel.id, formattedDate);

    // Only consider approved bookings
    final approvedBookings = bookings.where((b) => b.status == 'approved').toList();
    final bookedSlots = <DateTime>[];
    for (var booking in approvedBookings) {
      try {
         final timeParts = booking.time.split(' ');
        final hourMinute = timeParts[0].split(':');
        final hour = int.parse(hourMinute[0]);
        final minute = int.parse(hourMinute[1]);
        final period = timeParts[1];

        int twentyFourHour = hour;
        if (period == 'PM' && hour != 12) {
          twentyFourHour += 12;
        } else if (period == 'AM' && hour == 12) {
          twentyFourHour = 0;
        }

        final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, twentyFourHour, minute);
        for (int i = 0; i < booking.duration; i++) {
             bookedSlots.add(start.add(Duration(hours: i)));
        }
      } catch (e) {
        print('Error parsing booking time or duration during availability check: $e');
      }
    }

    try {
        final timeParts = selectedStartTime!.split(' ');
        final hourMinute = timeParts[0].split(':');
        final hour = int.parse(hourMinute[0]);
        final minute = int.parse(hourMinute[1]);
        final period = timeParts[1];

        int twentyFourHour = hour;
        if (period == 'PM' && hour != 12) {
          twentyFourHour += 12;
        } else if (period == 'AM' && hour == 12) {
          twentyFourHour = 0;
        }
        final potentialStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, twentyFourHour, minute);
        final potentialEnd = potentialStart.add(Duration(hours: selectedDuration));

         for (var bookedSlot in bookedSlots) {
            if (potentialStart.isBefore(bookedSlot.add(const Duration(hours: 1))) && potentialEnd.isAfter(bookedSlot)) {
                return false;
            }
        }

        return true;

    } catch (e) {
       print('Error parsing selected time or duration during availability check: $e');
       return false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchBookingsAndCalculateAvailableTimes(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.classModel.name,
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
              background: widget.classModel.imageUrl != null && widget.classModel.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.classModel.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.secondary.withOpacity(0.1),
                        child: Icon(
                          Icons.meeting_room,
                          size: 48,
                          color: AppColors.secondary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.secondary.withOpacity(0.1),
                      child: Icon(
                        Icons.meeting_room,
                        size: 48,
                        color: AppColors.secondary,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Class Details'),
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
                          Row(
                            children: [
                              Icon(Icons.business, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Building: ${widget.classModel.building}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                             children: [
                              Icon(Icons.stairs, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Floor: ${widget.classModel.floor}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                           const SizedBox(height: 8),
                          Row(
                             children: [
                              Icon(Icons.people, size: 18, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Capacity: ${widget.classModel.capacity} people',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (widget.classModel.description.isNotEmpty) ...[
                            Text(
                              widget.classModel.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (widget.classModel.features.isNotEmpty) ...[
                            const Text(
                              'Features:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.classModel.features.map((feature) => Chip(
                                label: Text(feature),
                                backgroundColor: AppColors.secondary.withOpacity(0.1),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Top Reviews'),
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.classModel.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall Rating',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Based on ${widget.classModel.totalReviews} reviews',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.classModel.reviews.length > 3 ? 3 : widget.classModel.reviews.length,
                            itemBuilder: (context, index) {
                              final review = widget.classModel.reviews[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          child: Text(
                                            review.userName[0].toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    review.rating.toString(),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          review.createdAt.toDate().toString().split(' ')[0],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review.comment,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('Book This Class'),
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
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Select Date'),
                            subtitle: Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            ),
                            onTap: () => _selectDate(context),
                          ),
                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: _isLoading ? 'Checking availability...' : 'Select Start Time (7 AM - 5 PM)',
                                border: const OutlineInputBorder(),
                              ),
                              value: selectedStartTime,
                              hint: _isLoading ? const Text('Loading...') : const Text('Choose a time'),
                              items: _isLoading ? [] : _allPossibleStartTimes.map((String time) {
                                 bool isAvailable = _currentAvailableStartTimes.contains(time);
                                return DropdownMenuItem<String>(
                                  value: time,
                                  enabled: isAvailable,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      color: isAvailable ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _isLoading ? null : (String? newValue) {
                                setState(() {
                                  selectedStartTime = newValue;
                                });
                              },
                            ),
                          ),
                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Duration (hours)',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedDuration,
                              hint: const Text('Choose duration'),
                              items: _availableDurations.map((int duration) {
                                return DropdownMenuItem<int>(
                                  value: duration,
                                  child: Text('$duration hour${duration > 1 ? 's' : ''}'),
                                );
                              }).toList(),
                              onChanged: _isLoading ? null : (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedDuration = newValue;
                                    _calculateAvailableStartTimes();
                                  });
                                }
                              },
                            ),
                          ),
                          const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextField(
                              controller: _purposeController,
                              decoration: const InputDecoration(
                                labelText: 'Purpose of Booking',
                                hintText: 'Enter the purpose of your booking',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ),
                           const Divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextField(
                              controller: _extraItemsNotesController,
                              decoration: const InputDecoration(
                                labelText: 'Extra Items Notes (Optional)',
                                hintText: 'e.g., 5 extra chairs, projector needed',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ),
                           SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _bookClass,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Book Now'),
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
      padding: const EdgeInsets.only(bottom: 12.0, top: 16.0),
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
} 