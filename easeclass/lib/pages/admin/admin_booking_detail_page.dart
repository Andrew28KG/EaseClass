import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class AdminBookingDetailPage extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback onBookingUpdated;

  const AdminBookingDetailPage({
    Key? key,
    required this.booking,
    required this.onBookingUpdated,
  }) : super(key: key);

  @override
  State<AdminBookingDetailPage> createState() => _AdminBookingDetailPageState();
}

class _AdminBookingDetailPageState extends State<AdminBookingDetailPage> {
  final BookingService _bookingService = BookingService();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _approveBooking() async {
    setState(() => _isLoading = true);
    try {
      print('Attempting to approve booking: ${widget.booking.id}');
      await _bookingService.approveBooking(
        widget.booking.id,
        reason: _reasonController.text.trim(),
      );
      print('Booking approved successfully in service');
      if (mounted) {
        widget.onBookingUpdated();

        print('Attempting to pop after approval');
        Navigator.pop(context);
        print('Navigator.pop called after approval');
      }
    } catch (e) {
      if (mounted) {
        print('Error approving booking: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectBooking() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for rejection')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this booking? Please provide a reason:'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      print('Attempting to reject booking: ${widget.booking.id}');
      await _bookingService.rejectBooking(widget.booking.id, reason);
      print('Booking rejected successfully in service');
      if (mounted) {
        widget.onBookingUpdated();

        print('Attempting to pop after rejection');
        Navigator.pop(context);
        print('Navigator.pop called after rejection');
      }
    } catch (e) {
      if (mounted) {
        print('Error rejecting booking: ${e.toString()}');
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('Room Details', [
                    _buildInfoRow('Room', widget.booking.roomDetails?['name'] ?? 'Room ${widget.booking.roomId}'),
                    _buildInfoRow('Building', widget.booking.roomDetails?['building'] ?? '-'),
                    _buildInfoRow('Floor', widget.booking.roomDetails?['floor']?.toString() ?? '-'),
                    _buildInfoRow('Capacity', widget.booking.roomDetails?['capacity']?.toString() ?? '-'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Booking Details', [
                    _buildInfoRow('Date', widget.booking.date),
                    _buildInfoRow('Time', _formatTimeWithDuration(widget.booking.time, widget.booking.duration ?? 1)),
                    _buildInfoRow('Purpose', widget.booking.purpose),
                    _buildInfoRow('Status', widget.booking.status.toUpperCase()),
                    if (widget.booking.adminResponseReason != null)
                      _buildInfoRow('Admin Response', widget.booking.adminResponseReason!),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('User Details', [
                    _buildInfoRow('Name', widget.booking.userDetails?['name'] ?? 'Anonymous'),
                    _buildInfoRow('Email', widget.booking.userDetails?['email'] ?? '-'),
                  ]),
                  const SizedBox(height: 24),
                  if (widget.booking.status == 'pending') ...[
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Response Reason (Optional)',
                        hintText: 'Enter reason for approval/rejection',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _approveBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rejectBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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