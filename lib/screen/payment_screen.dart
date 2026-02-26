import 'package:flutter/material.dart';
import 'package:my_app/screen/payment_successfull.dart';

class PaymentPage extends StatelessWidget {
  final String helperId; // receive here

  const PaymentPage({super.key, required this.helperId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Payment",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Session Fee Text
              const Text(
                "Session Fee: ৳50 (Demo Payment)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F6FED),
                ),
              ),

              const SizedBox(height: 40),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6FED),
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
                        builder: (context) =>
                            PaymentSuccessScreen(helperId: helperId),
                      ),
                    );
                  },
                  child: const Text(
                    "Pay Now",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Subtitle
              const Text(
                "This is a test payment for project demo.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
