import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../models/app_user.dart';

// ── Repository Provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Firebase Auth State Stream ───────────────────────────────────────────────

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── Current AppUser (with role) ──────────────────────────────────────────────

final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return ref.read(authRepositoryProvider).fetchUserByUid(user.uid);
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Is Admin convenience provider ────────────────────────────────────────────

final isAdminProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentAppUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.isAdmin ?? false,
    orElse: () => false,
  );
});

// ── Setup wizard: whether admin exists yet ────────────────────────────────────

final hasAdminUserProvider = FutureProvider<bool>((ref) async {
  return ref.read(authRepositoryProvider).hasAdminUser();
});

// ── Auth Notifier (sign in / sign out) ───────────────────────────────────────

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email, password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>>(AuthNotifier.new);
