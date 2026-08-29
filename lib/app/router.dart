import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/products/presentation/products_screen.dart';
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
        final user = currentUser.valueOrNull;
        if (user != null) {
          return user.isAdmin ? AppRoutes.dashboard : AppRoutes.pos;
        }
        return null; // wait for user data
      }

      // Admin-only route guard
      final isAdminRoute = state.matchedLocation == AppRoutes.dashboard ||
          state.matchedLocation == AppRoutes.users;
      if (isLoggedIn && isAdminRoute) {
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

