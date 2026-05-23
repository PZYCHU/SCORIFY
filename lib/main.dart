import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_regist/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'AHP-SAW Penilaian Siswa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthCheck(),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan auth state — hanya panggil listenToUser jika uid berubah
    _authService.authStateChanges.listen((user) {
      if (!mounted) return;

      final oldUid = _user?.uid;
      final newUid = user?.uid;

      setState(() {
        _user = user;
        _initialized = true;
      });

      // Hanya update Firestore subscription jika uid benar-benar berubah
      if (oldUid != newUid) {
        context.read<AppProvider>().listenToUser(newUid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading sampai auth state pertama kali diterima
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user != null) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

