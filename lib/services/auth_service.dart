import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // For web, use Firebase's native signInWithPopup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // For mobile, use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google sign-in cancelled');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final User user = userCredential.user!;

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final appUser = AppUser.fromFirestore(userDoc);
        print('✅ Existing user found: ${appUser.displayName}');
        return {'isNewUser': false, 'user': appUser};
      } else {
        // Auto-create user profile (no modal needed)
        print('📝 New user, creating profile automatically...');
        final appUser = AppUser.fromGoogleSignIn(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName ?? 'User',
          photoURL: user.photoURL,
          userType: 'customer', // Everyone is a customer
        );

        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        print('✅ User profile created: ${appUser.displayName}');
        return {'isNewUser': false, 'user': appUser};
      }
    } catch (e) {
      print('❌ Google sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<AppUser> completeRegistration({
    required User firebaseUser,
    required String userType,
  }) async {
    try {
      final appUser = AppUser.fromGoogleSignIn(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName ?? 'User',
        photoURL: firebaseUser.photoURL,
        userType: userType,
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(appUser.toMap());
      return appUser;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // ============================================================================
  // EMAIL/PASSWORD AUTHENTICATION
  // ============================================================================

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = userCredential.user!;

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final appUser = AppUser.fromFirestore(userDoc);
        print('✅ Existing user found: ${appUser.displayName}');
        return {'isNewUser': false, 'user': appUser};
      } else {
        // Auto-create user profile
        print('📝 Creating user profile...');
        final appUser = AppUser.fromGoogleSignIn(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName ?? user.email!.split('@')[0],
          photoURL: user.photoURL,
          userType: 'customer',
        );

        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        print('✅ User profile created: ${appUser.displayName}');
        return {'isNewUser': false, 'user': appUser};
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign in failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Register with email and password
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = userCredential.user!;

      // Update display name
      await user.updateDisplayName(displayName);

      // Send email verification
      await user.sendEmailVerification();

      // Auto-create user profile
      print('📝 Creating new user profile for registration...');
      final appUser = AppUser.fromGoogleSignIn(
        uid: user.uid,
        email: user.email!,
        displayName: displayName,
        photoURL: user.photoURL,
        userType: 'customer',
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      print('✅ User profile created: ${appUser.displayName}');

      return {'isNewUser': false, 'user': appUser};
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          message = 'Password is too weak (minimum 6 characters)';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  /// Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw Exception('No user signed in or email already verified');
      }
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }
}
