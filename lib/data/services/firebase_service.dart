//lib/data/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/water_quality.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    hostedDomain: null,
  );

  User? get currentUser => _auth.currentUser;

  // FIXED: Use string timestamp comparison for your Firestore setup
  Future<List<WaterQuality>> getWaterQualityData({
    required String location,
    DateTime? lastSyncTime,
    int? limit,
  }) async {
    try {
      AppLogger.firestore('=== FIXED FIRESTORE QUERY ===');
      AppLogger.firestore('Getting water quality data for location: $location');

      String collection;
      if (location.toLowerCase() == 'semarang') {
        collection = 'water_quality';
      } else {
        collection = AppConstants.getWaterQualityCollection(location);
      }

      AppLogger.firestore('Using collection: $collection');

      Query query = _firestore
          .collection(collection)
          .orderBy('timestamp', descending: true);

      // FIXED: Use STRING comparison since your timestamps are stored as strings
      if (lastSyncTime != null) {
        final timestampString = lastSyncTime.toIso8601String();
        query = query.where(
          'timestamp',
          isGreaterThan: timestampString, // Use string, not Timestamp object
        );
        AppLogger.firestore(
            '✅ Added STRING timestamp filter: $timestampString');
      }

      if (limit != null) {
        query = query.limit(limit);
        AppLogger.firestore('Added limit: $limit');
      }

      AppLogger.firestore('Executing Firestore query...');
      final querySnapshot = await query.get();
      AppLogger.firestore(
          '✅ Query completed. Document count: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning(
            'No documents found with timestamp filter', 'FIRESTORE');
        return [];
      }

      // Process results
      final results = <WaterQuality>[];
      AppLogger.firestore(
          '📝 Processing ${querySnapshot.docs.length} documents...');

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        try {
          final doc = querySnapshot.docs[i];
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          final waterQuality = WaterQuality.fromMap(data);
          results.add(waterQuality);

          if (i < 3) {
            // Log first 3 for debugging
            AppLogger.firestore(
                '✅ Doc ${i + 1}: ${waterQuality.timestamp.toIso8601String()} - T:${waterQuality.temperature}°C');
          }
        } catch (e) {
          AppLogger.error(
              '❌ Error processing document ${querySnapshot.docs[i].id}: $e',
              'FIRESTORE');
          continue;
        }
      }

      AppLogger.firestore(
          '✅ Successfully processed ${results.length}/${querySnapshot.docs.length} documents');
      return results;
    } catch (e) {
      AppLogger.error('❌ Firestore query error: $e', 'FIRESTORE');
      throw Exception('Failed to get water quality data: $e');
    }
  }

  Future<WaterQuality?> getLatestWaterQuality(String location) async {
    try {
      AppLogger.firestore(
          'Getting latest water quality for location: $location');

      String collection;
      if (location.toLowerCase() == 'semarang') {
        collection = 'water_quality';
      } else {
        collection = AppConstants.getWaterQualityCollection(location);
      }

      final querySnapshot = await _firestore
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        try {
          final data = querySnapshot.docs.first.data();
          data['id'] = querySnapshot.docs.first.id;
          return WaterQuality.fromMap(data);
        } catch (e) {
          AppLogger.error('Error parsing latest reading', 'FIRESTORE', e);
          return null;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error(
          'Error getting latest water quality data', 'FIRESTORE', e);
      throw Exception('Failed to get latest water quality data: $e');
    }
  }

  // Test Firestore connection method
  Future<bool> testFirestoreConnection() async {
    try {
      AppLogger.firestore('Testing Firestore connection...');

      // Test 1: Basic connectivity
      final testQuery =
          await _firestore.collection('water_quality').limit(1).get();
      AppLogger.firestore(
          'Basic connectivity test successful. Documents found: ${testQuery.docs.length}');

      if (testQuery.docs.isNotEmpty && kDebugMode) {
        final sampleData = testQuery.docs.first.data();
        AppLogger.firestore('Sample document available for analysis');

        // Analyze the structure in debug mode only
        sampleData.forEach((key, value) {
          AppLogger.firestore('Field analysis - $key: ${value.runtimeType}');
        });
      }

      // Test 2: Try different collections (debug only)
      if (kDebugMode) {
        for (String collectionName in [
          'water_quality',
          'water_quality_semarang',
          'water_quality_malang'
        ]) {
          try {
            final testCollection =
                await _firestore.collection(collectionName).limit(1).get();
            AppLogger.firestore(
                'Collection "$collectionName": ${testCollection.docs.length} documents');
          } catch (e) {
            AppLogger.warning(
                'Collection "$collectionName": Error accessing', 'FIRESTORE');
          }
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Firestore connection test failed', 'FIRESTORE', e);
      return false;
    }
  }

  // Authentication methods (keeping existing implementation)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.isSignedIn();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-auth-token',
          message: 'Failed to obtain Google authentication tokens',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final userDoc =
          _firestore.collection(AppConstants.usersCollection).doc(user.uid);
      final docSnapshot = await userDoc.get();

      final userData = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Unknown',
        email: user.email ?? '',
        locationPreference: docSnapshot.exists && docSnapshot.data() != null
            ? docSnapshot.data()!['location_preference'] ??
                AppConstants.defaultLocation
            : AppConstants.defaultLocation,
        createdAt: docSnapshot.exists && docSnapshot.data() != null
            ? (docSnapshot.data()!['created_at'] as Timestamp).toDate()
            : DateTime.now(),
      );

      await userDoc.set(userData.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user document: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<void> updateUserLocationPreference(String uid, String location) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'location_preference': location},
      );
    } catch (e) {
      throw Exception('Failed to update location preference: $e');
    }
  }

  Stream<List<WaterQuality>> getWaterQualityStream(String location,
      {int limit = 10}) {
    String collection = location.toLowerCase() == 'semarang'
        ? 'water_quality'
        : AppConstants.getWaterQualityCollection(location);

    return _firestore
        .collection(collection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return WaterQuality.fromMap(data);
              } catch (e) {
                AppLogger.error(
                    'Error parsing document ${doc.id}', 'FIRESTORE', e);
                return null;
              }
            })
            .where((item) => item != null)
            .cast<WaterQuality>()
            .toList());
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => _auth.currentUser != null;
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;
}
