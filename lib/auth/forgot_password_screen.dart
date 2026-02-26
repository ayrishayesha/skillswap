import 'package:flutter/material.dart';
import 'package:my_app/auth/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailC = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  bool isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Text(
                  "Forgot your PASSWORD?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter Your email address below and we will send a reset token.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),

                  decoration: InputDecoration(
                    hintText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "please enter your email";
                    } else if (!value.contains("@") || !value.contains(".")) {
                      return "please enter your valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isloading ? null : () => _requestResetToken(),

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: isloading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Send Reset Token",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info Box
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("What happens next?"),
                        SizedBox(height: 6),
                        Text("1. We will send a reset token"),
                        Text("2. Check your inbox"),
                        Text("3. Use token on next screen"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestResetToken() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isloading = true;
    });

    try {
      await supabase.auth.resetPasswordForEmail(
        emailC.text.trim(),
        redirectTo: 'http://localhost:59180',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Check Your Email"),
            content: const Text(
              "We have sent a reset token to your email. Please check.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ResetPasswordScreen(email: emailC.text.trim()),
                    ),
                  );
                },
                child: const Text("Continue"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }
}
