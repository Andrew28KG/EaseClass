import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/class_model.dart';
import '../../models/booking_model.dart';
import '../../theme/app_colors.dart';

class TopBookedClassesPage extends StatefulWidget {
  const TopBookedClassesPage({Key? key}) : super(key: key);

  @override
  State<TopBookedClassesPage> createState() => _TopBookedClassesPageState();
}

class _TopBookedClassesPageState extends State<TopBookedClassesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _topBookedClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchTopBookedClasses();
  }

  Future<void> _fetchTopBookedClasses() async {
    try {
      // Get all bookings
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      
      // Count bookings per class
      Map<String, int> bookingCounts = {};
      for (var doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromFirestore(doc);
        bookingCounts[booking.roomId] = (bookingCounts[booking.roomId] ?? 0) + 1;
      }

      // Get class details for each class
      List<Map<String, dynamic>> topClasses = [];
      for (var entry in bookingCounts.entries) {
        final classDoc = await _firestore.collection('classes').doc(entry.key).get();
        if (classDoc.exists) {
          final classData = classDoc.data() as Map<String, dynamic>;
          topClasses.add({
            'class': ClassModel.fromFirestore(classDoc),
            'bookingCount': entry.value,
          });
        }
      }

      // Sort by booking count
      topClasses.sort((a, b) => b['bookingCount'].compareTo(a['bookingCount']));

      setState(() {
        _topBookedClasses = topClasses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching top booked classes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Top Booked Classrooms'),
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _topBookedClasses.length,
              itemBuilder: (context, index) {
                final classData = _topBookedClasses[index];
                final classModel = classData['class'] as ClassModel;
                final bookingCount = classData['bookingCount'] as int;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: classModel.imageUrl != null && classModel.imageUrl!.isNotEmpty
                              ? Image.network(
                                  classModel.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.class_,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.primary,
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
                      ),
                      // Class Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    classModel.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${classModel.building} - Floor ${classModel.floor}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Booked $bookingCount times',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (classModel.capacity != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Capacity: ${classModel.capacity} people',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (classModel.features != null && classModel.features!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: classModel.features!.map((feature) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
} 