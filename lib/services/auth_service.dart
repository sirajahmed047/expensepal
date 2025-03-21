import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
    signInOption: SignInOption.standard,
  );

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error registering with email: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In process...');
      
      // Check if there's any previous sign-in
      final currentUser = await _googleSignIn.signInSilently();
      if (currentUser != null) {
        debugPrint('Found previous sign-in, signing out first...');
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow
      debugPrint('Triggering Google Sign In flow...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('Google Sign In was cancelled by user');
        throw FirebaseAuthException(
          code: 'sign_in_cancelled',
          message: 'Google Sign In was cancelled by the user',
        );
      }

      debugPrint('Google Sign In successful for user: ${googleUser.email}');
      debugPrint('Display Name: ${googleUser.displayName}');
      debugPrint('Photo URL: ${googleUser.photoUrl}');

      // Obtain the auth details from the request
      debugPrint('Getting Google auth tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Failed to get Google auth tokens');
        throw FirebaseAuthException(
          code: 'missing_google_auth_token',
          message: 'Missing Google Auth Token',
        );
      }

      debugPrint('Successfully obtained Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Created Firebase credential, attempting to sign in...');

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Successfully signed in to Firebase with Google');
      debugPrint('User ID: ${userCredential.user?.uid}');
      debugPrint('Email: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e, stackTrace) {
      debugPrint('Error during Google sign in: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e is FirebaseAuthException) {
        debugPrint('Firebase Auth Error Code: ${e.code}');
        debugPrint('Firebase Auth Error Message: ${e.message}');
        rethrow;
      }
      
      if (e is PlatformException) {
        debugPrint('Platform Error Code: ${e.code}');
        debugPrint('Platform Error Message: ${e.message}');
        debugPrint('Platform Error Details: ${e.details}');
      }

      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: e.toString(),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('Starting sign out process...');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('Successfully signed out from both Firebase and Google');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
} 