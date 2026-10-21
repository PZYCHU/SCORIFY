import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
import '../firebase_options.dart';

class AuthService {
  /// Bernilai true selama proses login/registrasi sedang memvalidasi akun ke Firestore,
  /// agar AuthCheck di main.dart tidak langsung memindahkan layar ke HomeScreen
  /// sebelum validasi selesai (mencegah efek "kepental" & hilangnya pop-up dialog).
  static bool isAuthFlowActive = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); 

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
    String? school,
  }) async {
    await _ensureFirebaseInitialized();
    isAuthFlowActive = true;
    try {
      if (kDebugMode) {
        debugPrint('📝 Attempting registration for email: $email');
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      await _saveUserToFirestore(
        uid: credential.user!.uid,
        name: name,
        email: email,
        school: school,
        photoUrl: null,
        provider: 'email',
      );
      // Kirim email verifikasi ke pengguna
      await credential.user!.sendEmailVerification();
      // Sign out agar tidak langsung masuk sebelum email diverifikasi
      await _auth.signOut();

      if (kDebugMode) {
        debugPrint('✅ Registration & verification email sent for user: ${credential.user?.email}');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Registration failed: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } finally {
      isAuthFlowActive = false;
    }
  }

  // ── Login dengan Email & Password ────────────────────────────────────────
  Future<UserCredential> signInWithEmail(String email, String password) async {
    await _ensureFirebaseInitialized();
    isAuthFlowActive = true;
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting login with email: $email');
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        try {
          await user.reload();
        } catch (_) {}
      }
      final freshUser = _auth.currentUser ?? user;
      if (freshUser != null && !freshUser.emailVerified) {
        // Keluarkan kembali jika email belum diverifikasi
        await _auth.signOut();
        throw EmailNotVerifiedException(freshUser.email ?? email);
      }

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isVerified': true,
        }, SetOptions(merge: true));
      }

      if (kDebugMode) {
        debugPrint('✅ Login successful for user: ${credential.user?.email}');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Login failed: ${e.code} - ${e.message}');
      }

      // 1. Akun pasti belum terdaftar di Firebase Auth
      if (e.code == 'user-not-found') {
        throw UserNotFoundException(email.trim());
      }

      // 2. Kredensial akun ada, tetapi password salah
      if (e.code == 'wrong-password') {
        throw 'Password yang Anda masukkan salah. Silakan periksa kembali kata sandi Anda.';
      }

      // 3. invalid-credential: di Firebase modern kode ini mewakili password salah atau kombinasi kredensial tidak cocok
      if (e.code == 'invalid-credential') {
        final exists = await checkEmailExistsInDatabase(email.trim());
        if (exists) {
          throw 'Password yang Anda masukkan salah. Silakan periksa kembali kata sandi Anda.';
        } else {
          // Karena Firebase mengaktifkan Email Enumeration Protection, jangan langsung memvonis akun belum terdaftar
          // agar pengguna yang hanya salah ketik password tidak kebingungan
          throw 'Email atau kata sandi tidak valid. Silakan periksa kembali kata sandi Anda, atau klik Daftar jika belum memiliki akun.';
        }
      }

      throw _handleAuthException(e);
    } finally {
      isAuthFlowActive = false;
    }
  }

  // ── Cek Apakah Email Terdaftar di Database (Firestore / Auth) ─────────────
  Future<bool> checkEmailExistsInDatabase(String email) async {
    final clean = email.trim();
    if (clean.isEmpty) return false;

    // 1. Cek query Firestore users collection (case-sensitive & lowercase)
    try {
      final q1 = await _firestore
          .collection('users')
          .where('email', isEqualTo: clean)
          .limit(1)
          .get();
      if (q1.docs.isNotEmpty) return true;

      final lower = clean.toLowerCase();
      if (lower != clean) {
        final q2 = await _firestore
            .collection('users')
            .where('email', isEqualTo: lower)
            .limit(1)
            .get();
        if (q2.docs.isNotEmpty) return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firestore checkEmailExistsInDatabase error: $e');
      }
    }

    // 2. Cek via Firebase Auth fetchSignInMethodsForEmail
    try {
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(clean);
      if (methods.isNotEmpty) return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchSignInMethodsForEmail error: $e');
      }
    }

    return false;
  }

  // ── Kirim Ulang Email Verifikasi ──────────────────────────────────────────
  Future<void> resendVerificationEmail(String email, [String? password]) async {
    isAuthFlowActive = true;
    try {
      if (password != null && password.isNotEmpty) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user?.sendEmailVerification();
        await _auth.signOut();
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final userCredential = await _auth.signInWithCredential(credential);
          await userCredential.user?.sendEmailVerification();
          await _auth.signOut();
          await _googleSignIn.signOut();
        }
      }
    } finally {
      isAuthFlowActive = false;
    }
  }

  // ── Register dengan Google ────────────────────────────────────────────────
  Future<String> registerWithGoogle({String? school}) async {
    await _ensureFirebaseInitialized();
    isAuthFlowActive = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Pendaftaran Google dibatalkan');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final email = user.email ?? '';

      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw 'Akun Google ($email) sudah terdaftar di sistem. Silakan langsung masuk melalui halaman Login.';
      }

      await _saveUserToFirestore(
        uid: user.uid,
        name: user.displayName ?? 'Guru',
        email: email,
        school: school,
        photoUrl: user.photoURL,
        provider: 'google',
        isVerified: true,
      );

      await _auth.signOut();
      await _googleSignIn.signOut();

      return email;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      isAuthFlowActive = false;
    }
  }

  // ── Login dengan Google ──────────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    await _ensureFirebaseInitialized();
    isAuthFlowActive = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login Google dibatalkan');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final email = (user.email ?? '').trim();

      final docRef = _firestore.collection('users').doc(user.uid);
      var docSnap = await docRef.get();

      // Fallback 1: Cek apakah data user ada di Firestore dengan email yang cocok (misal case atau doc ID lama)
      if (!docSnap.exists && email.isNotEmpty) {
        try {
          var q = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (q.docs.isEmpty && email.toLowerCase() != email) {
            q = await _firestore
                .collection('users')
                .where('email', isEqualTo: email.toLowerCase())
                .limit(1)
                .get();
          }
          if (q.docs.isNotEmpty) {
            final oldData = q.docs.first.data();
            await docRef.set({
              ...oldData,
              'uid': user.uid,
              'email': email,
              'isVerified': true,
              'lastLoginAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            docSnap = await docRef.get();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Query fallback email error: $e');
        }
      }

      // Jika dokumen Firestore tetap belum ada, berarti pengguna belum pernah mendaftar
      // melalui halaman Register (wajib mendaftar terlebih dahulu)
      if (!docSnap.exists) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
        await _googleSignIn.signOut();
        throw UserNotFoundException(email);
      }

      // Wajib verifikasi email jika belum diverifikasi
      if (!user.emailVerified) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        throw EmailNotVerifiedException(email);
      }

      await docRef.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isVerified': true,
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } finally {
      isAuthFlowActive = false;
    }
  }

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
    await _googleSignIn.signOut(); // ← uncomment
    await _auth.signOut();
  }

  // ── Ambil data profil guru dari Firestore ─────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Update Nama Tampilan ──────────────────────────────────────────────────
  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna tidak ditemukan.';
    try {
      await user.updateDisplayName(newName);
      await _firestore.collection('users').doc(user.uid).update({'name': newName});
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal memperbarui nama: $e';
    }
  }

  // ── Update Asal Sekolah ───────────────────────────────────────────────────
  Future<void> updateSchool(String newSchool) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Pengguna tidak ditemukan.';
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'school': newSchool.trim(),
        'asalSekolah': newSchool.trim(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Gagal memperbarui asal sekolah: $e';
    }
  }

  // ── Update Email ──────────────────────────────────────────────────────────
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw 'Pengguna tidak ditemukan.';
    try {
      // Re-autentikasi demi keamanan
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Kirim verifikasi sebelum email diubah
      await user.verifyBeforeUpdateEmail(newEmail);

      // Sinkronkan ke Firestore
      await _firestore.collection('users').doc(user.uid).update({'email': newEmail});
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal memperbarui email: $e';
    }
  }

  // ── Update Password ───────────────────────────────────────────────────────
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw 'Pengguna tidak ditemukan.';
    try {
      // Re-autentikasi demi keamanan
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal memperbarui password: $e';
    }
  }

  // ── Buat Kata Sandi Baru untuk Akun Google (Account Linking) ───────────────
  Future<void> linkPassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw 'Pengguna tidak ditemukan.';
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: newPassword,
      );
      await user.linkWithCredential(cred);
      await user.reload();
      await _firestore.collection('users').doc(user.uid).update({
        'provider': 'google_and_password',
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _auth.sendPasswordResetEmail(email: user.email!);
        throw 'Demi keamanan, tautan pembuatan kata sandi telah dikirim ke inbox ${user.email}. Silakan buka email Anda untuk mengatur kata sandi.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal membuat kata sandi: $e';
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────────────
  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    String? school,
    required String? photoUrl,
    required String provider,
    bool isVerified = false,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'school': school,
      'asalSekolah': school,
      'photoUrl': photoUrl,
      'provider': provider,
      'role': 'teacher',
      'isVerified': isVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

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

class EmailNotVerifiedException implements Exception {
  final String email;
  const EmailNotVerifiedException(this.email);

  @override
  String toString() => 'Email $email belum diverifikasi. Silakan periksa kotak masuk atau spam email Anda.';
}

class UserNotFoundException implements Exception {
  final String email;
  const UserNotFoundException(this.email);

  @override
  String toString() =>
      'Akun dengan email $email belum terdaftar di database Scorify. Silakan lakukan pendaftaran dan verifikasi email terlebih dahulu.';
}