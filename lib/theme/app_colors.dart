import 'package:flutter/material.dart';

// Enhanced App Color Scheme and Design System
class AppColors {
  // Primary orange
  static const Color primary = Color(0xFFF26E21);
  static const Color primaryLight = Color(0xFFF58D4E);
  static const Color primaryDark = Color(0xFFD45A11);
  
  // Red accent 
  static const Color accent = Color(0xFFEC1C24);
  static const Color accentLight = Color(0xFFF04C53);
  static const Color accentDark = Color(0xFFCC1017);
  
  // Green secondary
  static const Color secondary = Color(0xFF0E6333);
  static const Color secondaryLight = Color(0xFF3A8959);
  static const Color secondaryDark = Color(0xFF084D24);
  
  // Amber/gold highlight
  static const Color highlight = Color(0xFFF9A121);
  static const Color highlightLight = Color(0xFFFBB44E);
  static const Color highlightDark = Color(0xFFD88811);
  
  // Common UI colors
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color grey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFAFAFA);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color error = Color(0xFFF44336);
  
  // Card gradients
  static const List<Color> primaryGradient = [
    Color(0xFFF26E21),
    Color(0xFFF58D4E),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF0E6333),
    Color(0xFF3A8959),
  ];
  
  // Shadow
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
  
  // Subtle shadow
  static BoxShadow subtleShadow = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
}

// Typography styles
class AppTypography {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// Common UI elements and styling
class AppStyles {
  // Border radius
  static BorderRadius borderRadius = BorderRadius.circular(12);
  static BorderRadius borderRadiusSmall = BorderRadius.circular(8);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(16);
  static BorderRadius borderRadiusExtraLarge = BorderRadius.circular(24);
  
  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: borderRadius,
    boxShadow: [AppColors.subtleShadow],
  );
  
  // Gradient card decoration
  static BoxDecoration gradientCardDecoration = BoxDecoration(
    gradient: const LinearGradient(
      colors: AppColors.primaryGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: borderRadius,
    boxShadow: [AppColors.cardShadow],
  );
  
  // Button style
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusSmall,
    ),
    elevation: 2,
  );
  
  // Secondary button style
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusSmall,
    ),
    elevation: 2,
  );
  
  // Text button style
  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadiusSmall,
    ),
  );
  
  // Standard padding
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24);
  
  // Standard edge insets
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);
}

// Extension to AppColors class for admin-specific colors and helpers
extension AdminColors on AppColors {
  // Admin-specific colors
  static const Color adminPrimary = AppColors.secondary; // Use orange as primary for admin
  static const Color adminPrimaryLight = AppColors.secondaryLight;
  static const Color adminPrimaryDark = AppColors.secondaryDark;
  
  // Helper method to get the appropriate color based on user role
  static Color getPrimaryColor(bool isAdmin) {
    return isAdmin ? adminPrimary : AppColors.primary;
  }
  
  static Color getPrimaryLightColor(bool isAdmin) {
    return isAdmin ? adminPrimaryLight : AppColors.primaryLight;
  }
  
  static Color getPrimaryDarkColor(bool isAdmin) {
    return isAdmin ? adminPrimaryDark : AppColors.primaryDark;
  }
}