import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Shared Google → Firebase sign-in used from Sign in / Sign up.
Future<UserCredential> signInWithGoogleToFirebase() async {
  await GoogleSignIn.instance.initialize();
  try {
    await GoogleSignIn.instance.signOut();
  } catch (_) {}

  final googleUser = await GoogleSignIn.instance.authenticate();
  final googleAuth = googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}
