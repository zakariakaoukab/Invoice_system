import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// Signs in with email and password.
  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    // Check email verification
    if (cred.user != null && !cred.user!.emailVerified) {
      await _auth.signOut();
      throw Exception('يرجى التحقق من بريدك الإلكتروني أولاً (Email not verified).');
    }
    
    return cred;
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetches the AppUser document from Firestore for the given UID.
  Future<AppUser?> fetchUserByUid(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      // If offline or hanging, we can try to get it from cache
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (!doc.exists) return null;
        return AppUser.fromFirestore(doc);
      } catch (cacheError) {
        throw Exception('تعذر الاتصال بالخادم ولم يتم العثور على بيانات محلية.');
      }
    }
  }

  /// Creates a new user in Firebase Auth and saves their profile to Firestore.
  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final isSetup = _auth.currentUser == null;
    User? createdUser;

    if (isSetup) {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = credential.user;
    } else {
      // Use secondary app to prevent logging out the current admin
      final tempApp = await Firebase.initializeApp(
        name: 'temp_create_user_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = credential.user;
      await tempApp.delete();
    }

    // Send email verification
    await createdUser!.sendEmailVerification();

    // If it's setup, sign out immediately so they have to verify their email
    if (isSetup) {
      await _auth.signOut();
    }

    final uid = createdUser.uid;
    final newUser = AppUser(
      uid: uid,
      email: email.trim(),
      name: name.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(newUser.toFirestore());
        
    return newUser;
  }

  /// Checks if any admin user document exists in the users collection.
  Future<bool> hasAdminUser() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.roleAdmin)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      try {
        final snapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('role', isEqualTo: AppConstants.roleAdmin)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
        return snapshot.docs.isNotEmpty;
      } catch (_) {
        return true; // Default to true so it doesn't force setup offline
      }
    }
  }

  /// Returns a stream of all user documents (for user management screen).
  Stream<List<AppUser>> watchAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromFirestore).toList());
  }
}
