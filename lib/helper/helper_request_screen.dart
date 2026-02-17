import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() {
      loading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('request')
        .select(
          'id, status, learner_id, profiles!inner(full_name, department, batch)',
        )
        .eq('helper_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      requests = data;
      loading = false;
    });
  }

  Future<void> updateRequest(String requestId, String newStatus) async {
    try {
      await supabase
          .from('request')
          .update({'status': newStatus})
          .eq('id', requestId);

      fetchRequests();
    } catch (e) {
      print("Error updating request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Requests")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No requests yet"))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, i) {
                final r = requests[i];
                final learner = r['profiles'];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(learner['full_name']),
                    subtitle: Text(
                      "${learner['department']} · Year ${learner['batch']}\nStatus: ${r['status']}",
                    ),
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
                                    updateRequest(r['id'], 'approved'),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    updateRequest(r['id'], 'rejected'),
                              ),
                            ],
                          )
                        : Text(
                            r['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: r['status'] == 'approved'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
