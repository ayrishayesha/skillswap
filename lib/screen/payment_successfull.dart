import 'package:flutter/material.dart';
import 'rating_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String helperId;
  const PaymentSuccessScreen({super.key, required this.helperId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Text(
              "Payment Status",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const Spacer(),

            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.15),
              ),
              child: Center(
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Payment Successful",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "This was a demo payment for\nproject purposes.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5FD0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RatingScreen(helperId: helperId),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue to Rate",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
