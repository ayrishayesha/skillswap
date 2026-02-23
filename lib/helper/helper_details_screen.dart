import 'package:flutter/material.dart';
import 'package:my_app/request/request_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperDetailsPage extends StatefulWidget {
  final String helperId;

  const HelperDetailsPage({super.key, required this.helperId});

  @override
  State<HelperDetailsPage> createState() => _HelperDetailsPageState();
}

class _HelperDetailsPageState extends State<HelperDetailsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  String name = "";
  String dept = "";
  String bio = "";
  int batch = 0;
  String? avatarUrl;
  List<String> skills = [];

  @override
  void initState() {
    super.initState();
    loadHelperData();
  }

  /// -------- LOAD DATA FROM DATABASE ----------
  Future<void> loadHelperData() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, department, batch, avatar_url, skills, bio')
          .eq('id', widget.helperId)
          .maybeSingle();

      if (data != null) {
        name = data['full_name'] ?? "";
        dept = data['department'] ?? "";
        batch = data['batch'] ?? 0;
        avatarUrl = data['avatar_url'];
        bio = data['bio'] ?? "";

        final skill = data['skills'];

        if (skill != null && skill is List) {
          skills = skill.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint("Load helper error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Helper Details"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),

                  const SizedBox(height: 20),

                  /// Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// Dept + Batch
                  Text(
                    "$dept, $batch batch",
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),

                  const SizedBox(height: 15),

                  /// University (Static for now)
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
                        Icon(Icons.school, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Leading University",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// Expertise
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

                  const SizedBox(height: 5),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: skills.map((s) {
                      return Chip(
                        label: Text(s),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  /// Session Info
                  sessionBox(),

                  const SizedBox(height: 25),

                  /// About
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "About Me",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // const SizedBox(height: 5),
                  Text(
                    bio.isNotEmpty ? bio : "No bio added yet.",
                    style: const TextStyle(
                      color: Color.fromARGB(255, 72, 70, 70),
                    ),
                  ),
                  const SizedBox(height: 30),

                  /// Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        RequestService().showRequestPopup(
                          context: context,
                          helperId: widget.helperId,
                        );
                      },
                      icon: const Icon(Icons.handshake, color: Colors.white),
                      label: const Text(
                        "Request",
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// ---------- Widgets ----------

  Widget statBox(String value, String title, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget sessionBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.timer, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "15-minute help session",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Quick focused session for problem solving.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
