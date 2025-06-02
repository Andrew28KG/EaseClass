import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A simplified version of the dashboard components with less elements

// Simple Card Header
Widget buildSimpleCardHeader(String title, Color color, IconData icon) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// Simple Review List Item
Widget buildSimpleReviewItem(Map<String, dynamic> review, int index) {
  final Color color = Colors.blue;

  return ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Text((index + 1).toString(), style: TextStyle(color: color)),
    ),
    title: Text(
      review['room']?['name'] ?? 'Unknown Room',
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text('${review['rating']?.toStringAsFixed(1) ?? 'N/A'}'),
      ],
    ),
    trailing: Container(
      constraints: const BoxConstraints(maxWidth: 80),
      child: Text(
        review['user']?['name'] ?? 'Anonymous',
        style: TextStyle(
          fontSize: 12, 
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

// Simple Popular Room Item
Widget buildSimpleRoomItem(Map<String, dynamic> roomData, int index) {
  final Color color = Colors.purple;
  
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Text((index + 1).toString(), style: TextStyle(color: color)),
    ),
    title: Text(
      roomData['name'] ?? 'Unknown Room',
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    subtitle: Text(
      'Building: ${roomData['building'] ?? 'N/A'}',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    trailing: Container(
      constraints: const BoxConstraints(maxWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '${roomData['bookingCount'] ?? 0}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// Format timestamp
String formatTimestamp(Timestamp timestamp) {
  final date = timestamp.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

// Approval buttons in a vertical layout
Widget buildApprovalButtons({
  required Function() onApprove,
  required Function() onReject,
}) {  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 70),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onApprove,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onReject,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
            ),
          ),
        ),
      ],
    ),
  );
}
