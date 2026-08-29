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
  static const background = Color(0xFF0F0F13);
  static const surface = Color(0xFF1A1A22);
  static const surfaceElevated = Color(0xFF22222E);
  static const surfaceHighlight = Color(0xFF2A2A38);

  // Brand — Orange Blossom Gold
  static const primary = Color(0xFFD4A017);
  static const primaryLight = Color(0xFFEDBE3F);
  static const primaryDark = Color(0xFFA07A0E);
  static const primaryContainer = Color(0xFF2E2410);

  // Accent — Soft White
  static const onPrimary = Color(0xFF1A1400);
  static const onSurface = Color(0xFFEFEFEF);
  static const onSurfaceMuted = Color(0xFF9090A8);

  // Semantic
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFE74C3C);
  static const warning = Color(0xFFF39C12);
  static const info = Color(0xFF3498DB);

  // Divider
  static const divider = Color(0xFF2E2E3E);

  // Sidebar
  static const sidebarBg = Color(0xFF13131A);
  static const sidebarActive = Color(0xFF2A2418);
  static const sidebarBorder = Color(0xFF25252F);
}
