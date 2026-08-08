import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

OAuthCredential? _credential;

Future<FirebaseFirestore?> firebaseGetDBInstanceAnonymous() async {
  try {
    await FirebaseAuth.instance.signInAnonymously();
    return FirebaseFirestore.instance;
  } catch (e) {
    print("There was an error with firebase login");
    print(e.toString());
    return null;
  }
}

// returns null if authentication unsuccessful
Future<FirebaseFirestore?> firebaseGetDBInstance() async {
  if (_credential != null) {
    try {
      await FirebaseAuth.instance.signInWithCredential(_credential!);
      updateSettings(
        "currentUserEmail",
        FirebaseAuth.instance.currentUser!.email,
        pagesNeedingRefresh: [],
        updateGlobalState: false,
      );
      return FirebaseFirestore.instance;
    } catch (e) {
      print("There was an error with firebase login");
      print(e.toString());
      print("will retry with a new credential");
      _credential = null;
      googleUser = null;
      return await firebaseGetDBInstance();
    }
  } else {
    try {
      if (googleUser == null) {
        await signInGoogle(silentSignIn: true);
      }
      // GoogleSignInAccount? googleUser = googleUser;

      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      _credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      if (googleUser?.email != null) {
        updateSettings("currentUserEmail", googleUser!.email,
            updateGlobalState: true);
      }

      try {
        await FirebaseAuth.instance.signInWithCredential(_credential!);
        return FirebaseFirestore.instance;
      } catch (e) {
        print("Firebase Auth optional sync skipped: $e");
        return null;
      }
    } catch (e) {
      print("There was an error with google sign in: $e");
      print("NOTE: Google Sign-In usually fails with PlatformException(sign_in_failed) if the SHA-1 or SHA-256 certificate fingerprints are missing in the Firebase Console for your package (com.navlin.xpenzi). Please verify your Firebase project settings.");
      return null;
    }
  }
}
