import 'package:flutter/material.dart';
import 'package:my_app/auth/login_screen.dart';
import 'package:my_app/learner/learner_home_screen.dart';
import 'package:my_app/helper/helper_home_screen.dart';
import 'package:my_app/screen/basic_info_screen.dart'; // 👈 Add import for BasicInfoScreen
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

    // ❌ Not logged in → LoginScreen
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

      // ✅ NEW USER → profile null → go to BasicInfoScreen
      if (profile == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BasicInfo()),
        );
        return;
      }

      final role = profile['role'];

      // ✅ HELPER
      if (role == "helper") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HelperAdminHome()),
        );
      }
      // ✅ LEARNER
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LearnerHome()),
        );
      }
    } catch (e) {
      // ❌ If any error → fallback LearnerHome
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LearnerHome()),
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
              "LU SkillSwap",
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
