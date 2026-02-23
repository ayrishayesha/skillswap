import 'package:flutter/material.dart';
import 'package:my_app/request_details.dart';
import 'package:my_app/screen/chats_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperRequestsPage extends StatefulWidget {
  const HelperRequestsPage({super.key});

  @override
  State<HelperRequestsPage> createState() => _HelperRequestsPageState();
}

class _HelperRequestsPageState extends State<HelperRequestsPage> {
  final supabase = Supabase.instance.client;

  List requests = [];
  bool loading = true;

  String selectedSubject = "All";
  String searchText = "";

  final subjects = ["All", "Python", "DSA", "DBMS", "OS"];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH REQUEST =================
  Future<void> fetchRequests() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final data = await supabase
          .from('request')
          .select('''
        id,
        subject,
        title,
        description,
        attachment_url,
        status,
        created_at,
        learner_id,

        learner:profiles!learner_id (
          id,
          full_name,
          batch,
          avatar_url
        )
      ''')
          .eq('helper_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        requests = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR => $e");
      setState(() => loading = false);
    }
  }

  // ================= SHOW CONFIRM POPUP =================
  Future<void> showConfirmDialog(dynamic r) async {
    final learner = r['learner'];

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),

            // ================= POPUP UI =================
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 40, color: Colors.blue),

                const SizedBox(height: 10),

                const Text(
                  "You will start a 15-minute help session",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 20),

                // ================= LEARNER INFO =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            learner?['avatar_url'] != null &&
                                learner['avatar_url'].toString().isNotEmpty
                            ? NetworkImage(learner['avatar_url'])
                            : null,
                        child: learner?['avatar_url'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              learner?['full_name'] ?? "Learner",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Subject
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r['subject'] ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // Title
                            Text(
                              r['title'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ================= BUTTONS =================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true); // Confirm
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // Cancel
                    },
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // ================= IF CONFIRMED =================
    if (result == true) {
      updateStatus(r['id'], 'accepted', r['learner_id']);
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(String id, String status, String learnerId) async {
    try {
      await supabase.from('request').update({'status': status}).eq('id', id);

      await fetchRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request $status"),
          backgroundColor: status == "accepted" ? Colors.blue : Colors.red,
        ),
      );

      // ================= NAVIGATE TO CHAT =================
      if (status == 'accepted') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatsScreen(
              requestId: id,
              currentUserId: supabase.auth.currentUser!.id,
              otherUserId: learnerId,
              otherUserName: 'Learner',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE ERROR => $e");
    }
  }

  // ================= FILTER =================
  List get filteredRequests {
    return requests.where((r) {
      final subject = r['subject'] ?? '';
      final title = r['title'] ?? '';

      final matchSubject =
          selectedSubject == "All" || subject == selectedSubject;

      final matchSearch = title.toLowerCase().contains(
        searchText.toLowerCase(),
      );

      return matchSubject && matchSearch;
    }).toList();
  }

  // ================= TIME FORMAT =================
  String formatTime(String date) {
    final utcTime = DateTime.parse(date).toUtc();
    final localTime = utcTime.toLocal();
    final now = DateTime.now();

    final diff = now.difference(localTime);

    if (diff.isNegative) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";

    return "${diff.inDays}d ago";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Requests", style: TextStyle(color: Colors.black)),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final r = filteredRequests[index];
                return _buildCard(r);
              },
            ),
    );
  }

  // ================= CARD =================
  Widget _buildCard(dynamic r) {
    final learner = r['learner'];

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(requestId: r['id']),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(.1), blurRadius: 8),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= SUBJECT + TIME =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _subjectBadge(r['subject']),

                Text(
                  formatTime(r['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= PROFILE =================
            Row(
              children: [
                CircleAvatar(
                  radius: 22,

                  backgroundImage:
                      learner?['avatar_url'] != null &&
                          learner['avatar_url'].toString().isNotEmpty
                      ? NetworkImage(learner['avatar_url'])
                      : null,

                  child: learner?['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner?['full_name'] ?? "Learner",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    Text(
                      "Batch: ${learner?['batch'] ?? '-'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= TITLE =================
            Text(
              r['title'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // ================= DESC =================
            Text(
              r['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 12),

            // ================= BUTTON =================
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (r['status'] == "pending") ...[
                  ElevatedButton(
                    // 🔥 Accept → Popup
                    onPressed: () => showConfirmDialog(r),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),

                    child: const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton(
                    onPressed: () =>
                        updateStatus(r['id'], 'rejected', r['learner_id']),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ] else
                  Text(
                    r['status'].toUpperCase(),

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: r['status'] == 'accepted'
                          ? Colors.blue
                          : Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUBJECT BADGE =================
  Widget _subjectBadge(String? subject) {
    Color color = Colors.blue;

    switch (subject) {
      case "Python":
        color = Colors.orange;
        break;
      case "DSA":
        color = Colors.purple;
        break;
      case "DBMS":
        color = Colors.red;
        break;
      case "OS":
        color = Colors.indigo;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        subject ?? "General",

        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
