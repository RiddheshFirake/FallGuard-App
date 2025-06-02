import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello/screens/SignUpScreen.dart'; // Import SignUpScreen

class FirstTimeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose User Type',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Title
            Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please select your user type to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),

            // Normal User Button
            _buildUserTypeButton(
              icon: Icons.person,
              label: 'Normal User',
              color: Colors.blueAccent,
              context: context,
              role: 'Normal User',
            ),
            const SizedBox(height: 20),

            // Hospital Button
            _buildUserTypeButton(
              icon: Icons.local_hospital,
              label: 'Hospital',
              color: Colors.green,
              context: context,
              role: 'Hospital',
            ),
            const SizedBox(height: 40),

            // Login Button (For existing users)
            Center(
              child: TextButton(
                onPressed: () {
                  print("Navigating to LoginScreen...");
                  Navigator.pushNamed(context, '/login'); // Navigate to login screen
                },
                child: Text(
                  'Already have an account? Login',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build User Type Button Widget
  Widget _buildUserTypeButton({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
    required String role,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(role: role),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
    );
  }
}
