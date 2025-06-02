import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart'; // Although not strictly needed for history, might be useful for future expansion
import '../../theme/app_colors.dart';
import '../admin/admin_booking_detail_page.dart'; // Assuming this is used for admin response

class UserHistoryBookingDetailPage extends StatefulWidget {
  final BookingModel booking;

  const UserHistoryBookingDetailPage({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<UserHistoryBookingDetailPage> createState() => _UserHistoryBookingDetailPageState();
}

class _UserHistoryBookingDetailPageState extends State<UserHistoryBookingDetailPage> {
  // Helper function to format timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper function to format time with duration
  String _formatTimeWithDuration(String startTime, int duration) {
    // Parse the start time
    final parts = startTime.split(' ');
    if (parts.length != 2) return startTime; // Return original if format is unexpected

    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return startTime; // Return original if format is unexpected

    final period = parts[1];
    
    int hour = int.parse(timeParts[0]);
    // Convert 12-hour to 24-hour format
    if (period.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (period.toUpperCase() == 'AM' && hour == 12) hour = 0; // Midnight case
    
    // Calculate end time
    final endHour = hour + duration;
    
    // Format end time back to 12-hour format
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final displayEndHour = endHour % 12 == 0 ? 12 : endHour % 12;
    final displayEndHourPadded = displayEndHour.toString().padLeft(2, '0');
    
    return '$startTime - ${displayEndHourPadded}:00 $endPeriod';
  }

  // Helper function for info rows
  Widget _buildInfoRow(String label, String value) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

   // Helper function for building info cards
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
                Icon(icon, color: Theme.of(context).colorScheme.primary),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

    // Helper function for building the timeline card
  Widget _buildTimelineCard() {
    final status = widget.booking.status.toLowerCase();
    // No need for createdAt and updatedAt as they are not shown in labels/descriptions

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

              // Highlight current step more prominently
              if (isCurrent) {
                iconColor = AppColors.primary;
                textColor = AppColors.primary;
                descriptionColor = AppColors.primary;
                textWeight = FontWeight.bold;
                iconContainerColor = AppColors.primary.withOpacity(0.2);
              } else if (isCompleted) {
                 // Keep completed steps in primary color, but less prominent than current
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

  // Helper function for displaying features
    Widget _buildFeaturesRow(List features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                feature.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

   // Helper function for displaying purpose
  Widget _buildPurposeRow(String purpose) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Maintain padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to start
        children: [
          SizedBox(
            width: 100, // Match width of label SizedBox in _buildInfoRow
            child: const Text(
              'Purpose',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              purpose,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for displaying extra items
   Widget _buildExtraItemsRow(String extraItems) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Maintain padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to start
        children: [
          SizedBox(
            width: 100, // Match width of label SizedBox in _buildInfoRow
            child: const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              extraItems,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

    // Helper function for displaying rejection reason
   Widget _buildRejectionCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.booking.adminResponseReason!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
      ),
    );
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

             // Booking Timeline
            _buildTimelineCard(),
            const SizedBox(height: 16),
            
            // Room Information Card
            _buildInfoCard(
              'Room Details',
              Icons.meeting_room,
              [
                _buildInfoRow('Room Name', widget.booking.roomDetails?['name'] ?? 'Room ${widget.booking.roomId}'),
                _buildInfoRow('Building', widget.booking.roomDetails?['building'] ?? 'N/A'),
                _buildInfoRow('Floor', widget.booking.roomDetails?['floor']?.toString() ?? 'N/A'),
                _buildInfoRow('Capacity', '${widget.booking.roomDetails?['capacity'] ?? 'N/A'} people'),
                if (widget.booking.roomDetails?['features'] != null && widget.booking.roomDetails!['features'] is List)
                  _buildFeaturesRow(widget.booking.roomDetails!['features'] as List),
              ]
            ),
            const SizedBox(height: 16),
            
            // Booking Information Card
            _buildInfoCard(
              'Booking Information',
              Icons.event,
              [
                _buildInfoRow('Date', widget.booking.date),
                _buildInfoRow('Time', _formatTimeWithDuration(widget.booking.time, widget.booking.duration ?? 1)), // Use new format function
                 _buildPurposeRow(widget.booking.purpose), // Use new purpose row
                if (widget.booking.extraItemsNotes != null && widget.booking.extraItemsNotes!.isNotEmpty)
                  _buildExtraItemsRow(widget.booking.extraItemsNotes!), // Use new extra items row
                _buildInfoRow(
                  'Created At',
                  _formatTimestamp(widget.booking.createdAt),
                ),
                if (widget.booking.rating != null)
                  _buildInfoRow('Rating', '${widget.booking.rating}/5.0 ⭐'),
                if (widget.booking.feedback != null && widget.booking.feedback!.isNotEmpty)
                  _buildInfoRow('Feedback', widget.booking.feedback!),
              ]
            ),
            const SizedBox(height: 16),

            // Admin Response Card (if rejected)
            if (widget.booking.status.toLowerCase() == 'rejected' && 
                widget.booking.adminResponseReason != null)
              _buildRejectionCard(),
            
            const SizedBox(height: 24),
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
        ],
      ),
    );
  }
} 