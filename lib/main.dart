import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/auth/forgot_password_screen.dart';
import 'package:my_app/auth/reset_password_screen.dart';
import 'package:my_app/learner/learner_homepage.dart';
import 'package:my_app/page/showcase_skills.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'auth/login_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: splashscreen()));
}

// ignore: camel_case_types
class splashscreen extends StatefulWidget {
  const splashscreen({super.key});

  @override
  State<splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<splashscreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo box
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
              "LU QuickHelp",
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
