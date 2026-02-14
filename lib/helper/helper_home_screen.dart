import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:my_app/showcase_skills.dart';
import 'package:my_app/screen/showcase_skills.dart';

class HelperAdminHome extends StatefulWidget {
  const HelperAdminHome({super.key});

  @override
  State<HelperAdminHome> createState() => _HelperAdminHomeState();
}

class _HelperAdminHomeState extends State<HelperAdminHome>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool loading = false;

  late TabController _tabCtrl;

  // Add Helper Controllers
  final nameCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final skillCtrl = TextEditingController();
  final ratingCtrl = TextEditingController(text: "4.5");
  final sessionsCtrl = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    nameCtrl.dispose();
    deptCtrl.dispose();
    skillCtrl.dispose();
    ratingCtrl.dispose();
    sessionsCtrl.dispose();
    super.dispose();
  }

  // ================= HELPERS =================

  Future<List<Map<String, dynamic>>> fetchHelpers() async {
    final data = await supabase
        .from('helpers')
        .select('id, name, department, skill, rating, sessions, created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addHelper() async {
    final name = nameCtrl.text.trim();
    final dept = deptCtrl.text.trim();
    final skill = skillCtrl.text.trim();

    final rating = double.tryParse(ratingCtrl.text.trim());
    final sessions = int.tryParse(sessionsCtrl.text.trim());

    if (name.isEmpty || dept.isEmpty || skill.isEmpty) {
      _snack("Name/Department/Skill required");
      return;
    }
    if (rating == null) {
      _snack("Rating must be a number (ex: 4.7)");
      return;
    }
    if (sessions == null) {
      _snack("Sessions must be a number");
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('helpers').insert({
        'name': name,
        'department': dept,
        'skill': skill,
        'rating': rating,
        'sessions': sessions,
      });

      if (!mounted) return;

      Navigator.pop(context);
      _clearAddForm();
      _snack("Helper added ✅");
      setState(() {});
    } catch (e) {
      _snack("Add failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteHelper(String id) async {
    setState(() => loading = true);
    try {
      await supabase.from('helpers').delete().eq('id', id);
      _snack("Deleted ✅");
      setState(() {});
    } catch (e) {
      _snack("Delete failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _clearAddForm() {
    nameCtrl.clear();
    deptCtrl.clear();
    skillCtrl.clear();
    ratingCtrl.text = "4.5";
    sessionsCtrl.text = "0";
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Helper"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Helper Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: "Department"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: skillCtrl,
                decoration: const InputDecoration(labelText: "Main Skill"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ratingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Rating (ex: 4.9)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sessionsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Sessions (ex: 42)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: loading ? null : addHelper,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Helper?"),
        content: Text("Are you sure you want to delete $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteHelper(id);
            },
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );
  }

  // ================= REQUESTS =================

  /// Fetch requests + helper info (join)
  Future<List<Map<String, dynamic>>> fetchRequests() async {
    final data = await supabase
        .from('requests')
        .select('id, learner_id, helper_id, status, created_at, helpers(name)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    setState(() => loading = true);
    try {
      await supabase
          .from('requests')
          .update({'status': status})
          .eq('id', requestId);

      _snack("Request $status ✅");
      setState(() {});
    } catch (e) {
      _snack("Update failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI COMMON =================

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Helper Admin"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ShowcaseSkillsPage()),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: "Helpers"),
            Tab(text: "Requests"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: _tabCtrl.index == 0
          ? FloatingActionButton(
              onPressed: loading ? null : _openAddDialog,
              child: const Icon(Icons.add),
            )
          : null,

      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // -------- Helpers tab
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchHelpers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }

              final helpers = snap.data ?? [];
              if (helpers.isEmpty) {
                return const Center(child: Text("No helpers added yet."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: helpers.length,
                itemBuilder: (context, i) {
                  final h = helpers[i];
                  final id = h['id'].toString();
                  final name = (h['name'] ?? '').toString();
                  final dept = (h['department'] ?? '').toString();
                  final skill = (h['skill'] ?? '').toString();
                  final rating = (h['rating'] ?? '').toString();
                  final sessions = (h['sessions'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        "$dept • $skill\nRating: $rating • Sessions: $sessions",
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: loading
                            ? null
                            : () => _confirmDelete(id, name),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // -------- Requests tab
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchRequests(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }

              final reqs = snap.data ?? [];
              if (reqs.isEmpty) {
                return const Center(child: Text("No requests yet."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: reqs.length,
                itemBuilder: (context, i) {
                  final r = reqs[i];
                  final requestId = r['id'].toString();
                  final learnerId = (r['learner_id'] ?? '').toString();
                  final status = (r['status'] ?? 'pending').toString();
                  final helperName = (r['helpers']?['name'] ?? 'Helper')
                      .toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                    ),
                    child: ListTile(
                      title: Text(
                        "Request for $helperName",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text("Learner: $learnerId\nStatus: $status"),
                      isThreeLine: true,
                      trailing: status == "pending"
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () => updateRequestStatus(
                                          requestId,
                                          "rejected",
                                        ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () => updateRequestStatus(
                                          requestId,
                                          "accepted",
                                        ),
                                ),
                              ],
                            )
                          : Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: status == "accepted"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
