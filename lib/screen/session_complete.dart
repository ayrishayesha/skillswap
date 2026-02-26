import 'package:flutter/material.dart';
import 'package:my_app/screen/payment_screen.dart';

class SessionCompleteScreen extends StatelessWidget {
  final String helperId;
  final String helperName;

  final int totalMinutes;
  final String role;

  const SessionCompleteScreen({
    super.key,
    required this.helperId,
    required this.helperName,

    required this.totalMinutes,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session Summary")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.blue),
            ),

            const SizedBox(height: 20),

            const Text(
              "Session Completed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Great job! Your session with $helperName is done.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(helperName[0])),
                title: Text(helperName),
              ),
            ),

            const SizedBox(height: 40),

            if (role == "learner") ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(helperId: helperId),
                      ),
                    );
                  },
                  child: const Text("Pay & Rate"),
                ),
              ),
              const SizedBox(height: 15),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Back to Chats"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
