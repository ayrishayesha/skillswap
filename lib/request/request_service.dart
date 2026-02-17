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
      // 1️⃣ Duplicate check
      final existing = await supabase
          .from('request')
          .select()
          .eq('learner_id', user.id)
          .eq('helper_id', helperId);

      if (existing.isNotEmpty) {
        _showMessage(context, "Already Requested");
        return;
      }

      // 2️⃣ Insert request
      await supabase.from('request').insert({
        'learner_id': user.id,
        'helper_id': helperId,
        'status': 'pending',
      });

      _showMessage(context, "Request Sent Successfully ✅");
    } catch (e) {
      _showMessage(context, "Error: $e");
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
