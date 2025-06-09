import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/hive_service.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth State Provider - Stream of Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// UPDATED: Local User Provider - Gets user data from both local storage AND Firebase Auth
final localUserProvider = Provider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final firebaseUser = repository.currentUser;
  
  // Try to get from local storage first
  UserModel? localUser = repository.getCurrentUserLocal();
  
  // If we have a Firebase user but no local user, create one from Firebase data
  if (firebaseUser != null && localUser == null) {
    localUser = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? 'user@example.com',
      locationPreference: 'semarang', // Default
      createdAt: DateTime.now(),
    );
  }
  
  // If we have both, but local user has outdated info, update with Firebase data
  if (firebaseUser != null && localUser != null) {
    if (localUser.email != firebaseUser.email || 
        localUser.name != (firebaseUser.displayName ?? localUser.name)) {
      localUser = localUser.copyWith(
        email: firebaseUser.email ?? localUser.email,
        name: firebaseUser.displayName ?? localUser.name,
      );
    }
  }
  
  return localUser;
});

// Current Firebase User Provider (for real-time auth state)
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth Controller State
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth Controller Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState()) {
    _checkInitialAuthState();
  }

  void _checkInitialAuthState() {
    final currentUser = _repository.getCurrentUserLocal();
    final firebaseUser = _repository.currentUser;
    
    // Create user model from Firebase if available
    UserModel? userModel = currentUser;
    if (firebaseUser != null && currentUser == null) {
      userModel = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? 'user@example.com',
        locationPreference: 'semarang',
        createdAt: DateTime.now(),
      );
    }
    
    if (userModel != null || firebaseUser != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userModel,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      // Check if Hive is initialized (should be from main.dart)
      if (!HiveService().isInitialized) {
        throw Exception('App not properly initialized. Please restart the app.');
      }

      final user = await _repository.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign in was cancelled',
        );
      }
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = _getReadableErrorMessage(e.toString());
      
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  String _getReadableErrorMessage(String error) {
    String lowerError = error.toLowerCase();
    
    if (lowerError.contains('network')) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (lowerError.contains('google')) {
      return 'Google sign-in failed. Please try again.';
    } else if (lowerError.contains('credential')) {
      return 'Authentication credentials are invalid. Please try again.';
    } else if (lowerError.contains('disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (lowerError.contains('cancelled')) {
      return 'Sign-in was cancelled. Please try again.';
    } else if (lowerError.contains('hive') || lowerError.contains('database')) {
      return 'Database error. Please restart the app and try again.';
    } else if (lowerError.contains('initialization') || lowerError.contains('initialized')) {
      return 'App initialization error. Please restart the app.';
    } else {
      return 'Sign-in failed. Please try again later.';
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      await _repository.signOut();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getReadableErrorMessage(e.toString()),
      );
    }
  }

  Future<void> updateLocationPreference(String location) async {
    try {
      if (state.user != null) {
        await _repository.updateLocationPreference(state.user!.uid, location);
        final updatedUser = state.user!.copyWith(locationPreference: location);
        state = state.copyWith(user: updatedUser);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getReadableErrorMessage(e.toString()),
      );
    }
  }

  void clearError() {
    state = state.copyWith(
      status: state.user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}