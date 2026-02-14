import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperAdminHomePage extends StatefulWidget {
  const HelperAdminHomePage({super.key});

  @override
  State<HelperAdminHomePage> createState() => _HelperAdminHomePageState();
}

class _HelperAdminHomePageState extends State<HelperAdminHomePage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Helper Admin Home")));
  }
}
