import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class BookingDetailPage extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onBookingUpdated;

  const BookingDetailPage({
    Key? key,
    required this.booking,
    this.onBookingUpdated,
  }) : super(key: key);

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final BookingService _bookingService = BookingService();
  late BookingModel currentBooking;
  bool _isLoading = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentBooking = widget.booking;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),
            
            // Room Information Card
            _buildRoomInfoCard(),
            const SizedBox(height: 16),
            
            // Booking Information Card
            _buildBookingInfoCard(),
            const SizedBox(height: 16),            // User Information Card
            _buildUserInfoCard(),
            const SizedBox(height: 24),
            
            // Action Buttons (only for pending bookings)
            if (currentBooking.status == 'pending') _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (currentBooking.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending Approval';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.block;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = 'Unknown';
    }

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Removed Booking ID as requested
                  // Text(
                  //   'Booking ID: ${currentBooking.id}',
                  //   style: TextStyle(
                  //     color: Colors.grey.shade600,
                  //     fontSize: 14,
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    final roomDetails = currentBooking.roomDetails;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Room Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Room Name', roomDetails?['name'] ?? 'Room ${currentBooking.roomId}'),
            _buildDetailRow('Building', roomDetails?['building'] ?? 'N/A'),
            _buildDetailRow('Floor', roomDetails?['floor']?.toString() ?? 'N/A'),
            _buildDetailRow('Capacity', '${roomDetails?['capacity'] ?? 'N/A'} people'),
            if (roomDetails?['features'] != null && roomDetails!['features'] is List)
              _buildDetailRow('Features', (roomDetails['features'] as List).join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Booking Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', currentBooking.date),
            _buildDetailRow('Time', _formatTimeWithDuration(currentBooking.time, currentBooking.duration ?? 1)),
            _buildDetailRow('Purpose', currentBooking.purpose),
            _buildDetailRow(
              'Created At', 
              _formatTimestamp(currentBooking.createdAt),
            ),
            if (currentBooking.rating != null)
              _buildDetailRow('Rating', '${currentBooking.rating}/5.0 ⭐'),
            if (currentBooking.feedback != null && currentBooking.feedback!.isNotEmpty)
              _buildDetailRow('Feedback', currentBooking.feedback!),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final userDetails = currentBooking.userDetails;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('User Name', userDetails?['name'] ?? 'Anonymous'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleApprove,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showRejectDialog,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove() async {
    setState(() => _isLoading = true);
    try {
      await _bookingService.approveBooking(currentBooking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking approved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this booking:'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              _handleReject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject() async {
    setState(() => _isLoading = true);
    try {
      await _bookingService.rejectBooking(
        currentBooking.id,
        _rejectionReasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rejected successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
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

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper to format time with duration
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
}
