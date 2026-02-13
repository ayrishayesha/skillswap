import 'package:flutter/material.dart';
import 'package:my_app/auth/login_screen.dart';
import 'package:my_app/learner/profile/edit_profile.dart';
import 'package:my_app/learner/profile/edit_skill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/auth/login_screen.dart';

class LearnerProfilePage extends StatefulWidget {
  const LearnerProfilePage({super.key});

  @override
  State<LearnerProfilePage> createState() => _LearnerProfilePageState();
}

class _LearnerProfilePageState extends State<LearnerProfilePage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          profile = data;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Profile error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleAvailability(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('profiles')
          .update({'open_for_requests': value})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          profile?['open_for_requests'] = value;
        });
      }
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  /// ===== LOGOUT WITH REDIRECT =====
  Future<void> logout() async {
    await supabase.auth.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(), // <-- replace with your login widget
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return const Scaffold(body: Center(child: Text("Profile not found")));
    }

    final skills = List<String>.from(profile?['skills'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xfff4f5f7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ===== PROFILE HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profile?['avatar_url'] != null
                        ? NetworkImage(profile!['avatar_url'])
                        : null,
                    child: profile?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile?['full_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${profile?['department'] ?? ''}, Batch ${profile?['batch'] ?? ''}",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// ===== EXPERTISE SECTION =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // LEFT ALIGN
                children: [
                  const Text(
                    "Expertise",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  skills.isEmpty
                      ? const Text("No skills added")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: skills
                              .map(
                                (skill) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(skill),
                                ),
                              )
                              .toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// ===== EDIT BUTTONS =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: buildButton(
                      icon: Icons.edit,
                      text: "Edit Profile",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfile(),
                          ),
                        ).then((_) => fetchProfile());
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: buildButton(
                      icon: Icons.settings,
                      text: "Edit Skills",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditSkillpage(),
                          ),
                        ).then((_) => fetchProfile());
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// ===== TOGGLE =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Available to Help Others",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: profile?['open_for_requests'] ?? false,
                      onChanged: toggleAvailability,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ===== LOGOUT =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text(
                        "Log Out",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
