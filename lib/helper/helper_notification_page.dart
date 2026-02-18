import 'package:flutter/material.dart';
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
            status,
            created_at,
            learner:profiles!learner_id (
              id,
              full_name,
              avatar_url,
              department,
              batch
            )
          ''')
          .eq('helper_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        requests = data;
        loading = false;
      });
    } catch (e) {
      print("FETCH ERROR => $e");
      setState(() => loading = false);
    }
  }

  Future<void> updateStatus(String requestId, String status) async {
    try {
      await supabase
          .from('request')
          .update({'status': status})
          .eq('id', requestId);
      fetchRequests();
    } catch (e) {
      print("UPDATE ERROR => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Requests")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No requests"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                final learner = r['learner'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: learner['avatar_url'] != null
                          ? NetworkImage(learner['avatar_url'])
                          : null,
                      child: learner['avatar_url'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(learner['full_name'] ?? ''),
                    subtitle: Text("Status: ${r['status']}"),
                    trailing: r['status'] == 'pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () =>
                                    updateStatus(r['id'], 'accepted'),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    updateStatus(r['id'], 'rejected'),
                              ),
                            ],
                          )
                        : Text(r['status'].toString().toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
