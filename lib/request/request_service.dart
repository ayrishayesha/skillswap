import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_app/request/create_request_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ================= POPUP =================
  Future<void> showRequestPopup({
    required BuildContext context,
    required String helperId,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Send Request"),
          content: const Text(
            "Do you want to create a new request for this helper?",
          ),
          actions: [
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("Cancel"),
            ),

            // Go to Create Page
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateRequestPage(helperId: helperId),
                  ),
                );
              },
              child: const Text("Create Request"),
            ),
          ],
        );
      },
    );
  }

  // ================= SEND FINAL REQUEST =================
  Future<void> sendFinalRequest({
    required BuildContext context,
    required String helperId,
    required String title,
    required String description,
    required String subject,
    PlatformFile? file,
  }) async {
    if (!context.mounted) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      _showMessage(context, "User not logged in ❌");
      return;
    }

    try {
      // ================= CHECK LAST REQUEST =================
      final lastRequest = await supabase
          .from('request')
          .select('status')
          .eq('learner_id', user.id)
          .eq('helper_id', helperId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Block if already pending
      if (lastRequest != null && lastRequest['status'] == 'pending') {
        _showMessage(context, "Already Pending ⏳");
        return;
      }

      String? fileUrl;

      // ================= FILE UPLOAD =================
      if (file != null && file.bytes != null) {
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

        await supabase.storage
            .from('request-files')
            .uploadBinary(fileName, file.bytes!);

        fileUrl = supabase.storage.from('request-files').getPublicUrl(fileName);
      }

      // ================= INSERT REQUEST =================
      await supabase.from('request').insert({
        'learner_id': user.id,
        'helper_id': helperId,
        'title': title,
        'description': description,
        'subject': subject,
        'status': 'pending',
        'attachment_url': fileUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      _showMessage(context, "Request Sent Successfully ✅");

      Navigator.pop(context); // Back after send
    } catch (e) {
      debugPrint("REQUEST ERROR => $e");
      _showMessage(context, "Something went wrong ❌");
    }
  }

  // ================= SNACKBAR =================
  void _showMessage(BuildContext context, String msg) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
