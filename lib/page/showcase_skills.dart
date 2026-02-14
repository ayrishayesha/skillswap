import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_home_page.dart';
import 'package:my_app/learner/learner_homepage.dart';
import 'package:my_app/splashscreen/splash_screen.dart';

import 'package:my_app/helper/helper_home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client
final supabase = Supabase.instance.client;

class ShowcaseSkillsPage extends StatefulWidget {
  const ShowcaseSkillsPage({super.key});

  @override
  State<ShowcaseSkillsPage> createState() => _ShowcaseSkillsPageState();
}

class _ShowcaseSkillsPageState extends State<ShowcaseSkillsPage> {
  final List<String> suggestedSkills = const [
    "Python",
    "Java",
    "C++",
    "DSA",
    "DBMS",
    "OS",
    "OOP",
    "Algorithms",
  ];

  final List<String> selectedSkills = [];

  // switch: true => helper, false => learner
  bool helpOthers = true;

  final TextEditingController searchCtrl = TextEditingController();
  List<String> searchResults = [];
  bool searching = false;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => searchResults = []);
      return;
    }

    if (mounted) setState(() => searching = true);

    try {
      final res = await supabase
          .from('skills')
          .select('name')
          .ilike('name', '%$q%')
          .limit(30);

      final names = (res as List)
          .map((e) => (e['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();

      if (mounted) setState(() => searchResults = names);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (selectedSkills.contains(skill)) {
        selectedSkills.remove(skill);
      } else {
        selectedSkills.add(skill);
      }
    });
  }

  Future<void> _finish() async {
    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select at least 1 skill")));
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() => saving = true);

    try {
      final role = helpOthers ? "helper" : "learner";

      // ✅ UPDATE PROFILE + SAVE SKILLS TEXT ARRAY
      await supabase.from('profiles').upsert({
        'id': user.id,
        'role': role,
        'open_for_requests': helpOthers,
        'skills': selectedSkills, // 👈 MAIN FIX
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      List<int> skillIds = [];

      // Existing logic (UNCHANGED)
      for (String skill in selectedSkills) {
        final existing = await supabase
            .from('skills')
            .select('id')
            .eq('name', skill)
            .maybeSingle();

        int skillId;

        if (existing == null) {
          final inserted = await supabase
              .from('skills')
              .insert({'name': skill})
              .select('id')
              .single();

          skillId = inserted['id'] as int;
        } else {
          skillId = existing['id'] as int;
        }

        skillIds.add(skillId);
      }

      await supabase.from('profile_skills').delete().eq('profile_id', user.id);

      final inserts = skillIds.map((id) {
        return {'profile_id': user.id, 'skill_id': id};
      }).toList();

      await supabase.from('profile_skills').insert(inserts);

      if (!mounted) return;

      if (role == "learner") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LearnerHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Helper_Home_Page()),
        );
      }
      if (!mounted) return;

      // ✅ DIRECT SPLASH PAGE (NO CONDITION)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "STEP 2 OF 2",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 40,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Showcase your\nexpertise",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Select the skills you can share with peers to\nstart building your profile.",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(height: 25),

                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Search skills (e.g. Python)...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (searching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            "Searching...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),

                      if (searchResults.isNotEmpty) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: searchResults.map((skill) {
                            final isSelected = selectedSkills.contains(skill);
                            return ChoiceChip(
                              label: Text(skill),
                              selected: isSelected,
                              selectedColor: Colors.deepPurple,
                              backgroundColor: Colors.grey.shade100,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              onSelected: (_) => _toggleSkill(skill),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: suggestedSkills.map((skill) {
                          final isSelected = selectedSkills.contains(skill);
                          return ChoiceChip(
                            label: Text(skill),
                            selected: isSelected,
                            selectedColor: Colors.deepPurple,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                            onSelected: (_) => _toggleSkill(skill),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "I want to help others",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Open your profile for peer requests",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: helpOthers,
                              activeColor: Colors.deepPurple,
                              onChanged: (v) => setState(() => helpOthers = v),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: saving ? null : _finish,
                          child: Text(
                            saving ? "Saving..." : "Finish",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
