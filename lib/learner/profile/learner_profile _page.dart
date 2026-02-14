import 'package:flutter/material.dart';
import 'package:my_app/learner/profile/edit_profile.dart';

import 'package:my_app/learner/profile/edit_skill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/helper/helper_home_page.dart';
import 'package:my_app/learner/learner_homepage.dart';
import 'package:my_app/auth/login_screen.dart';

class Learner_Profile_Page extends StatefulWidget {
  const Learner_Profile_Page({super.key});

  @override
  State<Learner_Profile_Page> createState() => _Learner_Profile_PageState();
}

class _Learner_Profile_PageState extends State<Learner_Profile_Page> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  String name = "";
  String dept = "";
  int batch = 0;
  String avatar = "";
  List skills = [];

  double rating = 4.9;
  int sessions = 24;

  bool helper = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ---------------- LOAD DATA ----------------
  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final res = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        name = res['full_name'] ?? "";
        dept = res['department'] ?? "";
        batch = res['batch'] ?? 0;
        avatar = res['avatar_url'] ?? "";
        skills = res['skills'] ?? [];
        helper = res['open_for_requests'] ?? true;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => loading = false);
  }

  // ---------------- UPDATE ROLE ----------------
  Future<void> updateRole(bool value) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final role = value ? "helper" : "learner";

    await supabase
        .from('profiles')
        .update({'open_for_requests': value, 'role': role})
        .eq('id', user.id);

    setState(() => helper = value);
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ---------------- BACK NAVIGATION ----------------
  void goBack() {
    if (helper) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Helper_Home_Page()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LearnerHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("My Profile"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ---------------- AVATAR ----------------
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "$dept, $batch Batch",
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school, size: 18),
                          SizedBox(width: 5),
                          Text("Leading University"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ---------------- RATING ----------------
                    Row(
                      children: [
                        buildBox("4.9 ⭐", "Rating"),
                        const SizedBox(width: 15),
                        buildBox("24", "Sessions"),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ---------------- SKILLS ----------------
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Expertise",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills.map<Widget>((e) {
                        return Chip(label: Text(e.toString()));
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // ---------------- BUTTONS ----------------
                    Row(
                      children: [
                        Expanded(
                          child: buildBtn("Edit Profile", Icons.edit, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfile(),
                              ),
                            ).then((_) => loadProfile());
                          }),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: buildBtn("Edit Skills", Icons.settings, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditSkillpage(),
                              ),
                            ).then((_) => loadProfile());
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ---------------- SWITCH ----------------
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Available to Help Others",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: helper,
                            activeColor: Colors.deepPurple,
                            onChanged: (v) => updateRole(v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ---------------- LOGOUT ----------------
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          "Log Out",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: logout,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ---------------- WIDGETS ----------------
  Widget buildBox(String value, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget buildBtn(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
      ),
    );
  }
}
