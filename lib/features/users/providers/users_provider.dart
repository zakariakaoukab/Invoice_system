import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_repository.dart';
import '../../../models/app_user.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(usersRepositoryProvider).watchAllUsers();
});

class UsersNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(usersRepositoryProvider).createUser(
            email: email,
            password: password,
            name: name,
            role: role,
          ),
    );
  }
}

final usersNotifierProvider =
    AsyncNotifierProvider<UsersNotifier, void>(UsersNotifier.new);
