import 'package:flutter/material.dart';
import 'package:my_app/request_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperNotificationPage extends StatefulWidget {
  const HelperNotificationPage({super.key});

  @override
  State<HelperNotificationPage> createState() => _HelperNotificationPageState();
}

class _HelperNotificationPageState extends State<HelperNotificationPage> {
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

  // ================= FETCH =================
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
        created_at
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

  // ================= UPDATE =================
  Future<void> updateStatus(String id, String status) async {
    try {
      await supabase.from('request').update({'status': status}).eq('id', id);

      await fetchRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request $status"),
          backgroundColor: status == "accepted" ? Colors.green : Colors.red,
        ),
      );
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

  // ================= TIME =================
  String formatTime(String date) {
    final utcTime = DateTime.parse(date).toUtc();
    final localTime = utcTime.toLocal();

    final now = DateTime.now();
    final diff = now.difference(localTime);

    if (diff.isNegative) {
      return "Just now";
    }

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
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
          : Column(
              children: [
                // -------- SEARCH --------
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) {
                      setState(() => searchText = v);
                    },
                    decoration: InputDecoration(
                      hintText: "Search requests...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // -------- SUBJECT FILTER --------
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: subjects.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, i) {
                      final s = subjects[i];
                      final selected = selectedSubject == s;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => selectedSubject = s);
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // -------- LIST --------
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      final r = filteredRequests[index];

                      return _buildCard(r);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ================= CARD =================
  Widget _buildCard(dynamic r) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      // 👉 Card click = Details Page
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(
              requestId: r['id'], // ✅ শুধু id পাঠাতে হবে
            ),
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
            // ----- SUBJECT + TIME -----
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

            const SizedBox(height: 10),

            // ----- TITLE -----
            Text(
              r['title'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            // ----- DESCRIPTION (2 lines) -----
            Text(
              r['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 10),

            // ----- ATTACHMENT COUNT -----
            Row(
              children: [
                const Icon(Icons.attach_file, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  r['attachment_url'] != null
                      ? "1 Attachment"
                      : "No Attachment",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ----- BUTTONS -----
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (r['status'] == "pending") ...[
                  // ACCEPT
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => updateStatus(r['id'], 'accepted'),
                    child: const Text(
                      "Accept",
                      style: TextStyle(
                        color: Color.fromARGB(255, 251, 251, 251),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // REJECT
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(178, 233, 59, 47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => updateStatus(r['id'], 'rejected'),
                    child: const Text(
                      "Reject",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ] else
                  // STATUS TEXT
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
