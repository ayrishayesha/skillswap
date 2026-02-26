import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.fullName,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;

  bool checking = false;
  bool verified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkVerificationSilently();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerificationSilently();
    }
  }

  Future<void> _checkVerificationSilently() async {
    if (checking) return;

    setState(() => checking = true);

    try {
      await supabase.auth.refreshSession();
      final user = supabase.auth.currentUser;

      if (user != null && user.emailConfirmedAt != null) {
        verified = true;

        await supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': widget.fullName.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

        if (!mounted) return;

        Navigator.pop(context);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 52,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    "Verify your university email",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Go to your email and confirm the verification link to continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.alternate_email,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.email,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            checking
                                ? "Waiting for verification... (This page will update automatically when you return to the app)"
                                : "After clicking the verification link in your email, you will be redirected to the login page. Then, log in using your email and password.",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (checking) const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
