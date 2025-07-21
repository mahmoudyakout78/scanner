import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_barcode_sdk_example/selection_model.dart';
import 'package:google_fonts/google_fonts.dart';


class OtpPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpPage({super.key, required this.verificationId, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController codeController = TextEditingController();

  void verifyCode() async {
    final smsCode = codeController.text.trim();

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectionPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid code")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF5FF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.phoneNumber,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(
              "We've sent you a text message containing the verification code",
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "To complete the verification process for your phone number, please enter the 6-digit activation code",
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 28, letterSpacing: 6, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Have you not received the verification code?",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A3E9D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Verify", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white) ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
