import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/setup/presentation/setup_wizard_screen.dart';
import '../features/users/presentation/users_screen.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/widgets/splash_screen.dart';

// Route paths
class AppRoutes {
  static const splash = '/splash';
  static const setup = '/setup';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const pos = '/pos';
  static const orders = '/orders';
  static const products = '/products';
  static const users = '/users';
  static const reports = '/reports';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final hasAdmin = ref.watch(hasAdminUserProvider);
  final currentUser = ref.watch(currentAppUserProvider);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authState.isLoading || hasAdmin.isLoading) {
        return AppRoutes.splash;
      }
    
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login;
      final isSetupRoute = state.matchedLocation == AppRoutes.setup;
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;

      // Check if admin exists (setup wizard)
      final adminExists = hasAdmin.valueOrNull ?? true;
      
      if (!adminExists && !isSetupRoute) {
        return AppRoutes.setup;
      }
      
      if (adminExists && isSetupRoute) {
        return AppRoutes.login;
      }

      // Not logged in → go to login (if not already on login or setup)
      if (!isLoggedIn && !isAuthRoute && !isSetupRoute) {
        return AppRoutes.login;
      }

      // Logged in → redirect away from splash, login, or setup
      if (isLoggedIn && (isSplashRoute || isAuthRoute || isSetupRoute)) {
        if (currentUser.isLoading) {
          // If we are loading user profile, show splash
          return AppRoutes.splash; 
        }
        
        final user = currentUser.valueOrNull;
        if (user != null) {
          return user.isAdmin ? AppRoutes.dashboard : AppRoutes.pos;
        } else {
          // If user is null but not loading, they don't have a Firestore profile.
          // This shouldn't happen unless DB is out of sync. Log them out.
          return AppRoutes.login; // Wait, they are logged in via Auth, but no doc. 
        }
      }

      // Admin-only route guard
      final isAdminRoute = state.matchedLocation == AppRoutes.dashboard ||
          state.matchedLocation == AppRoutes.users ||
          state.matchedLocation == AppRoutes.reports;
      if (isLoggedIn && isAdminRoute) {
        if (currentUser.isLoading) return AppRoutes.splash;
        final user = currentUser.valueOrNull;
        if (user != null && !user.isAdmin) {
          return AppRoutes.pos;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (ctx, state) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (ctx, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.pos,
            builder: (ctx, state) => const PosScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (ctx, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.products,
            builder: (ctx, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: AppRoutes.users,
            builder: (ctx, state) => const UsersScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (ctx, state) => const ReportsScreen(),
          ),
        ],
      ),
    ],
  );

  // Trigger router refresh whenever auth/user state changes
  ref.listen(firebaseAuthStateProvider, (_, __) => router.refresh());
  ref.listen(hasAdminUserProvider, (_, __) => router.refresh());
  ref.listen(currentAppUserProvider, (_, __) => router.refresh());

  return router;
});

