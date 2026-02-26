import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'package:flutter/services.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  final confirmPasswordC = TextEditingController();
  final resettokenC = TextEditingController();

  bool _isLoading = false;

  final formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      emailC.text = widget.email!;
    }
  }

  Future<void> _resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = emailC.text.trim();
      final otp = resettokenC.text.trim();
      final newPassword = passwordC.text.trim();

      final res = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      if (res.session == null) {
        throw "Invalid or expired OTP";
      }

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successful")),
      );

      await supabase.auth.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Reset New Password"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Text(
                  "Create new password",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Enter the reset token from your email and set a new password.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: resettokenC,
                  decoration: InputDecoration(
                    hintText: "Reset Token",
                    prefixIcon: const Icon(Icons.vpn_key_off_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: () async {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        if (data?.text != null) {
                          resettokenC.text = data!.text!.trim();
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Reset token required" : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: emailC,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Email required";
                    if (!v.contains("@")) return "Invalid email";
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordC,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "New Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? "Min 6 characters" : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: confirmPasswordC,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v != passwordC.text) {
                      return "Password does not match";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Reset Password",
                            style: TextStyle(fontSize: 16),
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
}
