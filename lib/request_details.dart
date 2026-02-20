import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsPage extends StatefulWidget {
  final String requestId;

  const RequestDetailsPage({super.key, required this.requestId});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final supabase = Supabase.instance.client;

  Map? request;
  bool loading = true;
  bool updating = false;

  @override
  void initState() {
    super.initState();
    fetchRequestDetails();
  }

  // ================= FETCH DATA =================
  Future<void> fetchRequestDetails() async {
    final data = await supabase
        .from('request')
        .select('''
          id,
          title,
          description,
          subject,
          status,
          attachment_url,
          created_at,

          helper:profiles!helper_id (
            id,
            full_name,
            department,
            batch,
            avatar_url
          )
        ''')
        .eq('id', widget.requestId)
        .single();

    setState(() {
      request = data;
      loading = false;
    });
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(String newStatus) async {
    setState(() => updating = true);

    await supabase
        .from('request')
        .update({'status': newStatus})
        .eq('id', widget.requestId);

    await fetchRequestDetails();

    setState(() => updating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Request $newStatus successfully"),
        backgroundColor: newStatus == "accepted" ? Colors.green : Colors.red,
      ),
    );
  }

  // ================= DOWNLOAD FILE =================
  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : request == null
          ? const Center(child: Text("No Data Found"))
          : buildBody(),
    );
  }

  Widget buildBody() {
    final helper = request!['helper'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ================= PROFILE CARD =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          helper['avatar_url'] != null &&
                              helper['avatar_url'].toString().isNotEmpty
                          ? NetworkImage(helper['avatar_url'])
                          : null,
                      child: helper['avatar_url'] == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helper['full_name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${helper['department']} • ${helper['batch']} Year",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // STATUS BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          request!['status'],
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request!['status'].toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(request!['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Posted ${_formatDateTime(request!['created_at'])}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= DETAILS CARD =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SUBJECT BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request!['subject'] ?? '',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // TITLE
                Text(
                  request!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // DESCRIPTION
                Text(
                  request!['description'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),

                const SizedBox(height: 24),

                const Text(
                  "ATTACHMENT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 10),

                if (request!['attachment_url'] != null &&
                    request!['attachment_url'] != '')
                  InkWell(
                    onTap: () => downloadFile(request!['attachment_url']),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              request!['attachment_url']
                                  .toString()
                                  .split('/')
                                  .last,
                            ),
                          ),
                          const Icon(Icons.download),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= ACCEPT BUTTON =================
          if (request!['status'] == "pending")
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: updating ? null : () => updateStatus("accepted"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: updating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Accept Request →",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // ================= REJECT BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: updating ? null : () => updateStatus("rejected"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Reject Request",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDateTime(String date) {
    final dt = DateTime.parse(date).toLocal();

    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;

    return "${dt.day}/${dt.month}/${dt.year}  $hour:$minute $period";
  }
}
