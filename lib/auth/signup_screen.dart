import 'package:flutter/material.dart';
import 'package:my_app/auth/email_verification_screen.dart';
import 'package:my_app/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------- STRONG PASSWORD CHECK ----------
bool isStrongPassword(String password) {
  final regex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  return regex.hasMatch(password);
}

// ---------- UNIVERSITY EMAIL CHECK ----------
bool isUniversityEmail(String email) {
  return email.endsWith("@lus.ac.bd");
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool isPasswordHidden = true;

  final supabase = Supabase.instance.client;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await supabase.auth.signUp(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      if (!mounted) return;

      // ✅ Go to verification screen (we will save full_name AFTER verification)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: email.text.trim(),
            fullName: fullName.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  Center(
                    child: Column(
                      children: const [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFE9E7F5),
                          child: Icon(
                            Icons.school,
                            size: 40,
                            color: Color(0xFF2D1383),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Get quick help from students on campus.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "Full Name",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: fullName,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Full name is required";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      suffixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "University Email",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email is required";
                      }
                      if (!isUniversityEmail(value.trim())) {
                        return "Use university email (example@lus.ac.bd)";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "student@lus.ac.bd",
                      suffixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: password,
                    obscureText: isPasswordHidden,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Password is required";
                      }
                      if (!isStrongPassword(value.trim())) {
                        return "Min 8 chars, uppercase, lowercase, number & symbol";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "........",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => isPasswordHidden = !isPasswordHidden);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D1383),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: signup,
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                            color: Color(0xFF2D1383),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
