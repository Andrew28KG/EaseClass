import 'package:flutter/material.dart';

/// Helper class to handle navigation in the app with the nested navigation structure
class NavigationHelper {
  /// Navigate to a route within the current tab
  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a specific tab and reset to its root
  static void navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed('/home', arguments: tabIndex);
  }

  /// Navigate back within the current tab
  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  /// Navigate to room detail page
  static void navigateToRoomDetail(BuildContext context, Map<String, dynamic> arguments) {
    navigateTo(context, '/room-detail', arguments: arguments);
  }
  
  /// Navigate to booking confirmation page
  static void navigateToBookingConfirmation(BuildContext context, Map<String, dynamic> arguments) {
    navigateTo(context, '/booking-confirmation', arguments: arguments);
  }
  
  /// Navigate to progress detail page
  static void navigateToProgressDetail(BuildContext context, Map<String, dynamic> arguments) {
    navigateTo(context, '/progress-detail', arguments: arguments);
  }
  
  /// Navigate to rating page
  static void navigateToRating(BuildContext context, Map<String, dynamic> arguments) {
    navigateTo(context, '/rating', arguments: arguments);
  }
  
  /// Navigate to home tab
  static void navigateToHome(BuildContext context) {
    navigateToTab(context, 0);
  }
  
  /// Navigate to available rooms tab
  static void navigateToAvailableRooms(BuildContext context, {Map<String, dynamic>? applyFilter}) {
    navigateToTab(context, 1);
    // If we have filters to apply, handle them after navigation
    if (applyFilter != null) {
      // This implementation uses a global static variable to pass filter information
      // between navigation events. In a production app, you would use a state management
      // solution like Provider, Riverpod, or Bloc instead.
      pendingRoomFilters = applyFilter;
    }
  }
  
  // Static variable to hold pending filters between navigation events
  // Note: This is a simple approach. A better solution would use proper state management.
  static Map<String, dynamic>? pendingRoomFilters;
  
  /// Check if there are pending filters to apply
  static Map<String, dynamic>? consumePendingFilters() {
    final filters = pendingRoomFilters;
    pendingRoomFilters = null; // Clear after consuming
    return filters;
  }
  
  /// Navigate to progress tab
  static void navigateToProgress(BuildContext context) {
    navigateToTab(context, 2);
  }
  
  /// Navigate to settings tab
  static void navigateToSettings(BuildContext context) {
    navigateToTab(context, 3);
  }
  
  /// Navigate to user login page
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/user-login', (route) => false);
  }
} 