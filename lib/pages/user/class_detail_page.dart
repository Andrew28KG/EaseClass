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
import '../../services/firestore_service.dart';
import 'class_reviews_page.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Image
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: widget.classModel.imageUrl != null && widget.classModel.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.classModel.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.class_,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating Section
                        _buildRatingSection(),
                        const SizedBox(height: 16),
                        // Class Information
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Class Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(Icons.business, 'Building ${widget.classModel.building}'),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.stairs, 'Floor ${widget.classModel.floor}'),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.people, 'Capacity: ${widget.classModel.capacity} people'),
                                const SizedBox(height: 8),
                                _buildInfoRow(Icons.description, widget.classModel.description),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Features
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Features',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.classModel.features.map((feature) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        feature,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Booking Form
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Book This Class',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Date Selection
                                const Text(
                                  'Select Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                      });
                                      _fetchBookingsAndCalculateAvailableTimes(picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.calendar_today),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Time Selection
                                const Text(
                                  'Select Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<String>(
                                    value: selectedStartTime,
                                    isExpanded: true,
                                    hint: const Text('Select a time'),
                                    underline: const SizedBox(),
                                    items: _currentAvailableStartTimes.map((String time) {
                                      return DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedStartTime = newValue;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Duration Selection
                                const Text(
                                  'Duration (hours)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<int>(
                                    value: selectedDuration,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: _availableDurations.map((int duration) {
                                      return DropdownMenuItem<int>(
                                        value: duration,
                                        child: Text('$duration hour${duration > 1 ? 's' : ''}'),
                                      );
                                    }).toList(),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedDuration = newValue;
                                          _calculateAvailableStartTimes();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Purpose
                                const Text(
                                  'Purpose',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _purposeController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter the purpose of your booking',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                // Extra Items Notes
                                const Text(
                                  'Additional Notes (Optional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _extraItemsNotesController,
                                  decoration: InputDecoration(
                                    hintText: 'Any additional requirements or notes',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 24),
                                // Book Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _bookClass,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text(
                                            'Book Now',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.classModel.rating?.toStringAsFixed(1) ?? '0.0',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassReviewsPage(
                          classId: widget.classModel.id,
                          className: widget.classModel.name,
                          averageRating: widget.classModel.rating ?? 0.0,
                          totalReviews: widget.classModel.totalRatings ?? 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text('View All Reviews'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on ${widget.classModel.totalRatings ?? 0} reviews',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Review>>(
              future: _firestoreService.getClassReviews(widget.classModel.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error loading reviews: ${snapshot.error}');
                }

                final reviews = snapshot.data ?? [];
                
                if (reviews.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Show user's review first if exists
                    ..._buildUserReview(reviews),
                    const Divider(height: 32),
                    // Show other reviews
                    ...reviews
                        .where((review) => review.userId != Provider.of<AuthService>(context, listen: false).currentUser?.uid)
                        .map((review) => _buildReviewCard(review))
                        .toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserReview(List<Review> reviews) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    if (currentUser == null) return [];

    final userReview = reviews.firstWhere(
      (review) => review.userId == currentUser.uid,
      orElse: () => Review(
        id: '',
        classId: '',
        userId: '',
        bookingId: '',
        userName: '',
        rating: 0,
        comment: '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      ),
    );

    if (userReview.id.isEmpty) return [];

    return [
      const Text(
        'Your Review',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      _buildReviewCard(userReview),
    ];
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
            softWrap: true,
          ),
        ),
      ],
    );
  }
} 