import 'package:flutter/material.dart';
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
        learner_id
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

      // Navigate to chat if accepted
      if (status == 'accepted') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatsScreen(
              requestId: id,
              currentUserId: supabase.auth.currentUser!.id,
              otherUserId: learnerId,
              otherUserName: 'Learner', // optionally fetch name from profiles
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("UPDATE ERROR => $e");
    }
  }

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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => searchText = v),
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
                          onSelected: (_) =>
                              setState(() => selectedSubject = s),
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

  Widget _buildCard(dynamic r) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {}, // optionally show details page
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
            Text(
              r['title'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              r['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (r['status'] == "pending") ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        updateStatus(r['id'], 'accepted', r['learner_id']),
                    child: const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(178, 233, 59, 47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        updateStatus(r['id'], 'rejected', r['learner_id']),
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
