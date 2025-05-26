import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Status Card with gradient background
                  _buildStatusCard(),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room Details Card
                        _buildInfoCard(
                          'Room Details',
                          Icons.meeting_room,
                          [
                            _buildInfoRow('Room', widget.booking.roomDetails?['name'] ?? 'Room ${widget.booking.roomId}'),
                            _buildInfoRow('Building', widget.booking.roomDetails?['building'] ?? '-'),
                            _buildInfoRow('Floor', widget.booking.roomDetails?['floor']?.toString() ?? '-'),
                            _buildInfoRow('Capacity', '${widget.booking.roomDetails?['capacity'] ?? '-'} people'),
                            if (widget.booking.roomDetails?['features'] != null && 
                                widget.booking.roomDetails!['features'] is List)
                              _buildInfoRow(
                                'Features',
                                (widget.booking.roomDetails!['features'] as List).join(', '),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Booking Details Card
                        _buildInfoCard(
                          'Booking Details',
                          Icons.event,
                          [
                            _buildInfoRow('Date', widget.booking.date),
                            _buildInfoRow('Time', widget.booking.time),
                            _buildInfoRow('Purpose', widget.booking.purpose),
                            _buildInfoRow(
                              'Created At',
                              _formatTimestamp(widget.booking.createdAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Admin Response Card (if rejected)
                        if (widget.booking.status.toLowerCase() == 'rejected' && 
                            widget.booking.adminResponseReason != null)
                          _buildRejectionCard(),
                        
                        const SizedBox(height: 24),

                        // Cancel Button (only for active bookings)
                        if (widget.booking.isActive)
                          SizedBox(
                            width: double.infinity,
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

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (widget.booking.status.toLowerCase()) {
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
            'Booking ID: ${widget.booking.id}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
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
                Icon(icon, color: Theme.of(context).primaryColor),
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

  Widget _buildRejectionCard() {
    return Card(
              elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                Icon(Icons.info_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                        Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                widget.booking.adminResponseReason!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
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
} 