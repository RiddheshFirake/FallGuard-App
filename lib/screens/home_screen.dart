import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_home_page.dart'; // Import the page where the fall detection data will be displayed

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    try {
      // Get the current user's UID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the document from Firestore using the UID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if the document exists
      if (snapshot.exists) {
        // Safely access the 'role' field
        var role = snapshot['role'] ?? 'guest'; // Default to 'guest' if 'role' is missing
        setState(() {
          userRole = role;
        });

        // After fetching the role, navigate accordingly
        if (role == 'Normal User') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(title: 'Fall Detection System')),
          );
        }
      } else {
        // Handle the case where the document does not exist
        setState(() {
          userRole = 'No role assigned'; // Or you can handle it as needed
        });
        print("Document does not exist");
      }
    } catch (e) {
      // Handle any errors that occur during fetching
      setState(() {
        userRole = 'Error fetching role';
      });
      print("Error fetching document: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: userRole.isEmpty
            ? CircularProgressIndicator() // Show loading spinner while fetching data
            : userRole == 'normal'  // If role is 'normal' or 'user', show the fall detection page
            ? Container()  // Show nothing as we're navigating to another page
            : Text(
          'User Role: $userRole',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
