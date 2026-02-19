import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> sendRequest({
    required BuildContext context,
    required String helperId,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showMessage(context, "User not logged in");
      return;
    }

    try {
      // 1️⃣ Get latest request between learner & helper
      final lastRequest = await supabase
          .from('request')
          .select('status')
          .eq('learner_id', user.id)
          .eq('helper_id', helperId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // 2️⃣ Block only if last is pending
      if (lastRequest != null && lastRequest['status'] == 'pending') {
        _showMessage(context, "Already Pending ⏳");
        return;
      }

      // 3️⃣ Insert new request
      await supabase.from('request').insert({
        'learner_id': user.id,
        'helper_id': helperId,
        'status': 'pending',
      });

      _showMessage(context, "Request Sent Successfully ✅");
    } catch (e) {
      print("SEND ERROR => $e");
      _showMessage(context, "Something went wrong ❌");
    }
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black87),
    );
  }
}
