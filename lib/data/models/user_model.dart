import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String locationPreference;

  @HiveField(4)
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.locationPreference,
    required this.createdAt,
  });

  // Factory constructor from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      locationPreference: map['location_preference'] as String,
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'location_preference': locationPreference,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? locationPreference,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      locationPreference: locationPreference ?? this.locationPreference,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, '
        'locationPreference: $locationPreference, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.locationPreference == locationPreference &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      name,
      email,
      locationPreference,
      createdAt,
    );
  }
}
