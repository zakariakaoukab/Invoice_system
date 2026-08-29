import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/app_user.dart';
import '../../auth/data/auth_repository.dart';

class UsersRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;

  UsersRepository({
    FirebaseFirestore? firestore,
    AuthRepository? authRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepo = authRepo ?? AuthRepository();

  Stream<List<AppUser>> watchAllUsers() => _authRepo.watchAllUsers();

  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    return _authRepo.createUser(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': role});
  }
}
