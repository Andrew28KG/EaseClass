import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';

class UserBookingDetailPage extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback onBookingUpdated;

  const UserBookingDetailPage({
    Key? key,
    required this.booking,
    required this.onBookingUpdated,
  }) : super(key: key);

  @override
  State<UserBookingDetailPage> createState() => _UserBookingDetailPageState();
}

class _UserBookingDetailPageState extends State<UserBookingDetailPage> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  late BookingModel _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _listenToBookingUpdates();
  }

  void _listenToBookingUpdates() {
    _bookingService.getBookingById(widget.booking.id).then((updatedBooking) {
      if (updatedBooking != null && mounted) {
        setState(() {
          _currentBooking = updatedBooking;
        });
      }
    });
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _bookingService.cancelBooking(widget.booking.id);
      if (mounted) {
        // Get the updated booking
        final updatedBooking = await _bookingService.getBookingById(widget.booking.id);
        if (updatedBooking != null) {
          setState(() {
            _currentBooking = updatedBooking;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        widget.onBookingUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Booking'),
        content: const Text('Are you sure you want to mark this booking as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _bookingService.completeBooking(widget.booking.id);
      if (mounted) {
        // Get the updated booking
        final updatedBooking = await _bookingService.getBookingById(widget.booking.id);
        if (updatedBooking != null) {
          setState(() {
            _currentBooking = updatedBooking;
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking marked as completed')),
        );
        widget.onBookingUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimelineCard(),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          'Class Information',
                          Icons.class_,
                          [
                            _buildInfoRow('Name', _currentBooking.roomDetails['name'] ?? 'N/A'),
                            _buildInfoRow('Building', _currentBooking.roomDetails['building'] ?? 'N/A'),
                            _buildInfoRow('Floor', (_currentBooking.roomDetails['floor'] ?? 'N/A').toString()),
                            _buildInfoRow('Capacity', '${_currentBooking.roomDetails['capacity'] ?? 'N/A'} people'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          'Booking Details',
                          Icons.event,
                          [
                            _buildInfoRow('Date', _currentBooking.date),
                            _buildInfoRow('Time', _formatTimeWithDuration(_currentBooking.time, _currentBooking.duration ?? 1)),
                            _buildPurposeRow(_currentBooking.purpose),
                            if (_currentBooking.extraItemsNotes != null && _currentBooking.extraItemsNotes!.isNotEmpty)
                              _buildExtraItemsRow(_currentBooking.extraItemsNotes!),
                            _buildInfoRow(
                              'Created At',
                              _formatTimestamp(_currentBooking.createdAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Admin Response Card (if rejected)
                        if (_currentBooking.status.toLowerCase() == 'rejected' && 
                            _currentBooking.adminResponseReason != null)
                          _buildRejectionCard(),
                        
                        const SizedBox(height: 24),

                        // Action Buttons
                        if (_currentBooking.isActive)
                          Column(
                            children: [
                              // Complete Button (only for approved bookings)
                              if (_currentBooking.status.toLowerCase() == 'approved')
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: _completeBooking,
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Complete Booking'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                        // Cancel Button (only for active bookings)
                              Container(
                            width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ElevatedButton.icon(
                              onPressed: _cancelBooking,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel Booking'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_currentBooking.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending Approval';
        statusDescription = 'Your booking request is being reviewed by the administrator.';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        statusDescription = 'Your booking has been approved. You can use the class at the scheduled time.';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completed';
        statusDescription = 'This booking has been completed.';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        statusDescription = 'This booking has been cancelled.';
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.block;
        statusText = 'Rejected';
        statusDescription = 'This booking request was not approved.';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = 'Unknown';
        statusDescription = 'The status of this booking is unknown.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: statusColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeRow(String purpose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: const Text(
              'Purpose',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              purpose,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraItemsRow(String notes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: const Text(
              'Additional Notes',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentBooking.adminResponseReason ?? 'No reason provided',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final status = _currentBooking.status.toLowerCase();

    final steps = [
      {
        'icon': Icons.pending_actions,
        'label': 'Pending Approval',
        'completed': status != 'pending',
        'description': 'Booking request submitted'
      },
      {
        'icon': Icons.check_circle,
        'label': 'Approved',
        'completed': status == 'approved' || status == 'completed',
        'description': status == 'approved' || status == 'completed' 
            ? 'Booking approved'
            : 'Waiting for approval'
      },
      {
        'icon': Icons.done_all,
        'label': 'Completed',
        'completed': status == 'completed',
        'description': status == 'completed' ? 'Booking completed' : 'Waiting for completion'
      },
    ];

    // Add cancelled/rejected step if applicable
    if (status == 'cancelled' || status == 'rejected') {
      steps.add({
        'icon': status == 'cancelled' ? Icons.cancel : Icons.block,
        'label': status == 'cancelled' ? 'Cancelled' : 'Rejected',
        'completed': true,
        'description': status == 'cancelled' ? 'Booking cancelled' : 'Booking rejected'
      });
    }

    // Determine the index of the current step
    int currentIndex = -1;
    if (status == 'pending') {
      currentIndex = 0;
    } else if (status == 'approved') {
      currentIndex = 1;
    } else if (status == 'completed') {
      currentIndex = 2;
    } else if (status == 'cancelled' || status == 'rejected') {
      currentIndex = 3;
    }

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
              children: [
                Icon(Icons.timeline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Booking Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == steps.length - 1;

              Color iconColor = Colors.grey;
              Color textColor = Colors.grey;
              Color descriptionColor = Colors.grey.shade600;
              FontWeight textWeight = FontWeight.normal;
              Color iconContainerColor = Colors.grey.withOpacity(0.1);

              if (isCurrent) {
                iconColor = AppColors.primary;
                textColor = AppColors.primary;
                descriptionColor = AppColors.primary;
                textWeight = FontWeight.bold;
                iconContainerColor = AppColors.primary.withOpacity(0.2);
              } else if (isCompleted) {
                iconColor = AppColors.primary.withOpacity(0.7);
                textColor = AppColors.primary.withOpacity(0.7);
                descriptionColor = AppColors.primary.withOpacity(0.5);
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconContainerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 40,
                              color: isCompleted ? AppColors.primary.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: textWeight,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['description'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: descriptionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatTimeWithDuration(String time, int duration) {
    final timeParts = time.split(' ');
    final timeValue = timeParts[0];
    final period = timeParts[1];
    
    // Parse the time
    final timeComponents = timeValue.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1]);
    
    // Calculate end time
    final startTime = DateTime(2024, 1, 1, hour, minute);
    final endTime = startTime.add(Duration(hours: duration));
    
    // Format end time
    final endHour = endTime.hour;
    final endMinute = endTime.minute;
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final formattedEndHour = endHour > 12 ? endHour - 12 : (endHour == 0 ? 12 : endHour);
    
    return '$time - ${formattedEndHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')} $endPeriod';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 