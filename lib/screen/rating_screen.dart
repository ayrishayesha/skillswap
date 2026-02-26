import 'package:flutter/material.dart';
import 'package:my_app/screen/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RatingScreen extends StatefulWidget {
  final String helperId;

  const RatingScreen({super.key, required this.helperId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final supabase = Supabase.instance.client;

  int selectedRating = 0;
  bool isLoading = false;

  String helperName = "";
  String? avatarUrl;

  final TextEditingController feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchHelperInfo();
  }

  Future<void> fetchHelperInfo() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', widget.helperId)
          .single();

      setState(() {
        helperName = response['full_name'] ?? "Helper";
        avatarUrl = response['avatar_url'];
      });
    } catch (e) {
      debugPrint("Error fetching helper: $e");
    }
  }

  Future<void> submitRating() async {
    if (selectedRating == 0) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('ratings').upsert({
        'helper_id': widget.helperId,
        'learner_id': user!.id,
        'rating': selectedRating,
        'feedback': feedbackController.text.trim(),
      }, onConflict: 'helper_id,learner_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rating Submitted Successfully")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      }
    } catch (e) {
      debugPrint("Rating Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          selectedRating = index;
        });
      },
      icon: Icon(
        Icons.star,
        size: 36,
        color: index <= selectedRating ? Colors.amber : Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Rate Your Helper",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    helperName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Session Completed",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "How was your session?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a short feedback (optional)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            if (selectedRating > 0)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C8CF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Rating",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
