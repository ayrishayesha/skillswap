import 'package:flutter/material.dart';
import 'package:my_app/page/chats_page.dart';
import 'package:my_app/page/profile_page.dart';
import 'package:my_app/page/requests_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearnerHome extends StatefulWidget {
  const LearnerHome({super.key});

  @override
  State<LearnerHome> createState() => _LearnerHomeState();
}

class _LearnerHomeState extends State<LearnerHome> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;
  bool showAllHelpers = false;

  List helpers = [];
  List allHelpers = [];

  @override
  void initState() {
    super.initState();
    fetchHelpers();
  }

  Future<void> fetchHelpers() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('role', 'helper')
        .eq('open_for_requests', true);

    setState(() {
      allHelpers = data;
      helpers = data.take(4).toList(); // default only 4
    });
  }

  void viewAll() {
    setState(() {
      showAllHelpers = true;
      helpers = allHelpers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      body: IndexedStack(
        index: currentIndex,
        children: [
          homeScreen(),
          const RequestsPage(),
          const ChatsPage(),
          const ProfilePage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ================= HOME SCREEN =================

  Widget homeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "SkillSwap",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// SEARCH
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.search),
                hintText: "Search Python, DSA, DBMS...",
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// FILTER
          Row(
            children: [
              filterChip("All", true),
              filterChip("Python", false, Colors.yellow),
              filterChip("DSA", false, Colors.purple),
              filterChip("DBMS", false, Colors.orange),
            ],
          ),

          const SizedBox(height: 20),

          /// TOP HELPERS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Top Helpers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!showAllHelpers)
                GestureDetector(
                  onTap: viewAll,
                  child: const Text(
                    "View all",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: helpers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7, // slightly shorter cards
            ),
            itemBuilder: (_, i) => helperCard(helpers[i]),
          ),

          const SizedBox(height: 20),

          const Text(
            "Recently Active",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          recentTile("Mike T.", "DBMS", true),
          recentTile("Emily R.", "OS Design", false),
          recentTile("John D.", "ReactJS", false),
        ],
      ),
    );
  }

  // ================= UI PARTS =================

  Widget filterChip(String text, bool active, [Color? dotColor]) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: active ? Colors.white : Colors.black),
      ),
    );
  }

  Widget helperCard(Map h) {
    final batch = (h['batch'] != null && h['batch'].toString().isNotEmpty)
        ? h['batch']
        : "Null";

    final skills = (h['skills'] != null && h['skills'].toString().isNotEmpty)
        ? h['skills'].toString()
        : "No skills";

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ), // less padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30, // slightly smaller
            backgroundColor: Colors.grey.shade200,
            child:
                h['avatar_url'] != null && h['avatar_url'].toString().isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      h['avatar_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.person, size: 30),
          ),

          const SizedBox(height: 6), // reduced

          Text(
            h['full_name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 2), // reduced

          Text(
            "${h['department'] ?? ''} · Batch $batch",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 2), // reduced

          Text(
            "Skills: $skills",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6), // reduced

          SizedBox(
            width: double.infinity,
            height: 28, // reduced button height
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero, // removes extra padding
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {},
              child: const Text("Request"),
            ),
          ),
        ],
      ),
    );
  }

  Widget recentTile(String name, String skill, bool online) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ), // reduced
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
              if (online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Helping with $skill",
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 28, // smaller button
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              onPressed: () {},
              child: const Text("Request"),
            ),
          ),
        ],
      ),
    );
  }
}
