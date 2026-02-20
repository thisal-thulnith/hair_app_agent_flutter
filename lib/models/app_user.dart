import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String userType; // 'customer' or 'salon_owner'
  final bool ownsSalon;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.userType,
    required this.ownsSalon,
    required this.createdAt,
  });

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      userType: data['userType'] ?? 'customer',
      ownsSalon: data['ownsSalon'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'userType': userType,
      'ownsSalon': ownsSalon,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Google Sign-In data
  factory AppUser.fromGoogleSignIn({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required String userType,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      userType: userType,
      ownsSalon: userType == 'salon_owner',
      createdAt: DateTime.now(),
    );
  }
}
