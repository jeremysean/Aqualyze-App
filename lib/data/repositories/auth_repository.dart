import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/hive_service.dart';

class AuthRepository {
  final FirebaseService _firebaseService;
  final HiveService _hiveService;

  AuthRepository({
    FirebaseService? firebaseService,
    HiveService? hiveService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _hiveService = hiveService ?? HiveService();

  // Get current user
  User? get currentUser => _firebaseService.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Check if Hive is initialized before proceeding
      if (!_hiveService.isInitialized) {
        throw Exception(
            'App not properly initialized. Please restart the app.');
      }

      final userCredential = await _firebaseService.signInWithGoogle();
      if (userCredential?.user != null) {
        final userData =
            await _firebaseService.getUserData(userCredential!.user!.uid);
        if (userData != null) {
          // Try to save user to local storage, but don't fail if it doesn't work
          try {
            await _hiveService.saveUser(userData);
          } catch (hiveError) {
            // Log the error but don't fail the sign-in process
            print('Warning: Failed to save user locally: $hiveError');
            // Continue with sign-in even if local storage fails
          }
          return userData;
        }
      }
      return null;
    } catch (e) {
      // Re-throw with more context
      if (e.toString().contains('Hive') ||
          e.toString().contains('initialized')) {
        throw Exception(
            'App database error. Please restart the app and try again.');
      }
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();

      // Try to clear user from local storage, but don't fail if it doesn't work
      try {
        if (_hiveService.isInitialized) {
          await _hiveService.clearUser();
        }
      } catch (hiveError) {
        // Log the error but don't fail the sign-out process
        print('Warning: Failed to clear user locally: $hiveError');
      }
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Try to get from local storage first (but don't fail if Hive has issues)
      UserModel? localUser;
      try {
        if (_hiveService.isInitialized) {
          localUser = _hiveService.getCurrentUser();
          if (localUser != null && localUser.uid == uid) {
            return localUser;
          }
        }
      } catch (hiveError) {
        // Continue to Firebase if local storage fails
        print('Warning: Failed to get user from local storage: $hiveError');
      }

      // If not found locally, get from Firebase
      final userData = await _firebaseService.getUserData(uid);
      if (userData != null) {
        // Try to save to local storage, but don't fail if it doesn't work
        try {
          if (_hiveService.isInitialized) {
            await _hiveService.saveUser(userData);
          }
        } catch (hiveError) {
          print('Warning: Failed to save user locally: $hiveError');
        }
      }
      return userData;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Get current user from local storage
  UserModel? getCurrentUserLocal() {
    try {
      if (_hiveService.isInitialized) {
        return _hiveService.getCurrentUser();
      }
      return null;
    } catch (e) {
      // Return null if local storage fails
      print('Warning: Failed to get current user locally: $e');
      return null;
    }
  }

  // Update user location preference
  Future<void> updateLocationPreference(String uid, String location) async {
    try {
      await _firebaseService.updateUserLocationPreference(uid, location);

      // Try to update local user data, but don't fail if it doesn't work
      try {
        if (_hiveService.isInitialized) {
          final currentUser = _hiveService.getCurrentUser();
          if (currentUser != null) {
            final updatedUser =
                currentUser.copyWith(locationPreference: location);
            await _hiveService.saveUser(updatedUser);
          }
        }
      } catch (hiveError) {
        print('Warning: Failed to update user locally: $hiveError');
      }
    } catch (e) {
      throw Exception('Failed to update location preference: $e');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;

  // Get user display name
  String get userDisplayName => currentUser?.displayName ?? 'User';

  // Get user email
  String get userEmail => currentUser?.email ?? '';

  // Get user photo URL
  String? get userPhotoURL => currentUser?.photoURL;
}
