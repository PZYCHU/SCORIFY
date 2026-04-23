import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
// import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  // ── Stream status login ──────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Getter user saat ini ─────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;

  // ── Register dengan Email & Password ─────────────────────────────────────
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureFirebaseInitialized();
    try {
      if (kDebugMode) {
        debugPrint('📝 Attempting registration for email: $email');
      }
      // 1. Buat akun di Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update display name
      await credential.user!.updateDisplayName(name);

      // 3. Simpan data user ke Firestore
      await _saveUserToFirestore(
        uid: credential.user!.uid,
        name: name,
        email: email,
        photoUrl: null,
        provider: 'email',
      );

      if (kDebugMode) {
        debugPrint('✅ Registration successful for user: ${credential.user?.email}');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registration failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // ── Login dengan Email & Password ────────────────────────────────────────
  Future<UserCredential> signInWithEmail(String email, String password) async {
    await _ensureFirebaseInitialized();
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting login with email: $email');
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) {
        debugPrint('✅ Login successful for user: ${credential.user?.email}');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    }
  }

  // ── Login dengan Google ──────────────────────────────────────────────────
  // Future<UserCredential> signInWithGoogle() async {
  //   try {
  //     // 1. Tampilkan Google Sign-In picker
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) throw Exception('Login Google dibatalkan');

  //     // 2. Ambil authentication tokens
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     // 3. Buat credential Firebase dari Google token
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // 4. Sign in ke Firebase
  //     final userCredential = await _auth.signInWithCredential(credential);
  //     final user = userCredential.user!;

  //     // 5. Simpan/update data user ke Firestore
  //     // Cek apakah dokumen user sudah ada (login ulang) atau baru pertama kali
  //     final docRef = _firestore.collection('users').doc(user.uid);
  //     final docSnap = await docRef.get();

  //     if (!docSnap.exists) {
  //       // Pertama kali login dengan Google — buat dokumen baru
  //       await _saveUserToFirestore(
  //         uid: user.uid,
  //         name: user.displayName ?? 'Guru',
  //         email: user.email ?? '',
  //         photoUrl: user.photoURL,
  //         provider: 'google',
  //       );
  //     } else {
  //       // Sudah pernah login — update lastLoginAt saja
  //       await docRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
  //     }

  //     return userCredential;
  //   } on FirebaseAuthException catch (e) {
  //     throw _handleAuthException(e);
  //   }
  // }

  // ── Kirim email reset password ────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ── Sign out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // await _googleSignIn.signOut(); // sign out dari Google juga
    await _auth.signOut();
  }

  // ── Ambil data profil guru dari Firestore ─────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Simpan dokumen user ke koleksi 'users' di Firestore
  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    required String? photoUrl,
    required String provider,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,       // 'email' atau 'google'
      'role': 'teacher',          // default role untuk semua user di Scorify
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Konversi FirebaseAuthException ke pesan error yang ramah pengguna
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      case 'invalid-credential':
        return 'Email atau password tidak valid.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
