import 'package:firebase_auth/firebase_auth.dart';

/// Short, user-facing messages for common Firebase Auth errors.
String messageForFirebaseAuth(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address doesn’t look valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset it in Firebase Console.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect.';
      case 'operation-not-allowed':
        return 'Email/password sign-in isn’t enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? e.code;
    }
  }
  return e.toString();
}
