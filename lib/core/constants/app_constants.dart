import 'package:flutter/material.dart';

/// Application-wide constants: colors, spacing, invoice prefix, etc.
class AppConstants {
  AppConstants._();

  // Invoice numbering
  static const invoicePrefix = 'FACT';

  // Firestore collection names
  static const usersCollection = 'users';
  static const productsCollection = 'products';
  static const ordersCollection = 'orders';
  static const counterCollection = 'counters';

  // User roles
  static const roleAdmin = 'admin';
  static const roleStandard = 'standard';

  // Desktop layout
  static const sidebarWidth = 240.0;
  static const contentPadding = 24.0;
  static const cardBorderRadius = 16.0;
  static const dialogMaxWidth = 520.0;
}

/// Color palette — Orange Blossom premium dark theme.
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF8F9FB);
  static const surfaceHighlight = Color(0xFFE8EAF0);

  // Brand — Enterprise Blue
  static const primary = Color(0xFF0052CC);
  static const primaryLight = Color(0xFF2684FF);
  static const primaryDark = Color(0xFF0747A6);
  static const primaryContainer = Color(0xFFDEEBFF);

  // Accent — Dark Charcoal
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF172B4D);
  static const onSurfaceMuted = Color(0xFF5E6C84);

  // Semantic
  static const success = Color(0xFF36B37E);
  static const error = Color(0xFFFF5630);
  static const warning = Color(0xFFFFAB00);
  static const info = Color(0xFF00B8D9);

  // Divider
  static const divider = Color(0xFFDFE1E6);

  // Sidebar
  static const sidebarBg = Color(0xFFFFFFFF);
  static const sidebarActive = Color(0xFFDEEBFF);
  static const sidebarBorder = Color(0xFFDFE1E6);
}
