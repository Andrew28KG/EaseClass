import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../pages/admin/admin_main_page.dart';

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
  }  /// Navigate to available rooms tab
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
  
  /// Navigate to bookings/progress page
  static void navigateToProgress(BuildContext context) {
    navigateToTab(context, 2);
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
  
  /// Navigate to bookings tab (for both user and admin)
  static void navigateToBookings(BuildContext context) async {
    // Get the AuthService to check if user is admin
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = await authService.isCurrentUserAdmin();
    
    // For users, bookings is tab 2, for admins it's tab 3
    navigateToTab(context, isAdmin ? 3 : 2);
  }
  
  /// Navigate to settings/profile tab
  static void navigateToSettings(BuildContext context) async {
    // Get the AuthService to check if user is admin
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = await authService.isCurrentUserAdmin();
    
    // For users, settings is tab 3, for admins it's tab 4
    navigateToTab(context, isAdmin ? 4 : 3);
  }
  
  /// Navigate to management tab (admin only)
  static void navigateToManagement(BuildContext context) {
    // Only for admins, tab 2
    navigateToTab(context, 2);
  }
  
  /// Navigate to appropriate home page based on user role
  static Future<void> navigateToRoleBasedHome(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = await authService.isCurrentUserAdmin();
    
    if (isAdmin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminMainPage()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
    /// Navigate to login page
  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
  
  /// Navigate to admin dashboard (admin users only)
  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminMainPage()),
      (route) => false,
    );
  }
}