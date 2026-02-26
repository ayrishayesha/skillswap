import 'package:flutter/material.dart';
import 'package:my_app/profile/edit_profile.dart';

import 'package:my_app/profile/edit_skill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:my_app/screen/home_screen.dart';
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

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Homepage()),
    );
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
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    const SizedBox(height: 5),

                    CircleAvatar(
                      radius: 55,
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      child: avatar.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),

                    const SizedBox(height: 5),

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
                      style: const TextStyle(
                        color: Color.fromARGB(255, 100, 98, 98),
                      ),
                    ),

                    const SizedBox(height: 5),

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

                    const SizedBox(height: 50),

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

                    const SizedBox(height: 40),

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

                    Container(
                      padding: const EdgeInsets.all(20),
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
                            activeColor: Colors.blue,
                            onChanged: (v) => updateRole(v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xfffdeaea), // soft red
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: logout,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildBox(Widget valueWidget, String title) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            valueWidget,
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
