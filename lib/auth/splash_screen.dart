import 'package:flutter/material.dart';
import 'package:my_app/auth/login_screen.dart';
import 'package:my_app/screen/home_screen.dart';
import 'package:my_app/profile/basic_info_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nextScreen();
  }

  Future<void> _nextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    final session = supabase.auth.currentSession;

    if (session == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final user = supabase.auth.currentUser;

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user!.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BasicInfo()),
        );
        return;
      }

      final role = profile['role'];

      if (role == "helper") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      }
      //  LEARNER
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 45, 19, 131),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 25),
            const Text(
              "CampusMentor",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
