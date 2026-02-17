import 'package:flutter/material.dart';
import 'package:my_app/learner/learner_home_screen.dart';
import 'package:my_app/learner/profile/learner_profile%20_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EditSkillpage extends StatefulWidget {
  const EditSkillpage({super.key});

  @override
  State<EditSkillpage> createState() => _EditSkillpageState();
}

class _EditSkillpageState extends State<EditSkillpage> {
  final List<String> suggestedSkills = const [
    "Python",
    "Java",
    "C++",
    "DSA",
    "DBMS",
    "OS",
    "OOP",
    "Algorithms",
    // "Web Development",
    "Machine Learning",
  ];

  final List<String> selectedSkills = [];

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

  /// ---------------- SEARCH SKILLS ----------------
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

  /// ---------------- SAVE SKILLS ----------------
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

      await supabase.from('profiles').upsert({
        'id': user.id,
        'role': role,
        'open_for_requests': helpOthers,
        'skills': selectedSkills,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      List<int> skillIds = [];

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully updated your skills"),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (role == "learner") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LearnerHome()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Learner_Profile_Page()),
        );
      }
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
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Edit Skills",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------- SEARCH FIELD ----------------
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search for skills (e.g. Python, Figma)",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ---------------- SEARCH RESULTS ----------------
            if (searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  "Searching...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            if (searchResults.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: searchResults.map((skill) {
                  final isSelected = selectedSkills.contains(skill);
                  return ChoiceChip(
                    label: Text(skill),
                    selected: isSelected,
                    // selectedColor: Colors.deepPurple,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    onSelected: (_) => _toggleSkill(skill),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            /// ---------------- SELECTED SKILLS ----------------
            if (selectedSkills.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "SELECTED SKILLS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "${selectedSkills.length} selected",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: selectedSkills.map((skill) {
                  return Chip(
                    label: Text(
                      skill,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: const Color.fromARGB(255, 81, 117, 227),
                    deleteIcon: const Icon(Icons.close, color: Colors.white),
                    onDeleted: () => _toggleSkill(skill),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
            ],

            /// ---------------- SUGGESTED SKILLS ----------------
            const Text(
              "SUGGESTED SKILLS",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
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
              ),
            ),

            const SizedBox(height: 15),

            /// ---------------- SAVE BUTTON ----------------
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 81, 117, 227),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: saving ? null : _finish,
                child: Text(
                  saving ? "Saving..." : "Save Skills",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
