import 'package:flutter/material.dart';
import 'package:hello/screens/home_screen.dart';
import 'my_home_page.dart'; // Import your custom MyHomePage here

class HospitalDashboard extends StatefulWidget {
  @override
  _HospitalDashboardState createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  // Client list
  List<Map<String, String>> clients = [
    {"name": "Client A", "icon": Icons.local_hospital.codePoint.toString()},
    {"name": "Client B", "icon": Icons.health_and_safety.codePoint.toString()},
    {"name": "Client C", "icon": Icons.healing.codePoint.toString()},
    {"name": "Client D", "icon": Icons.medical_services.codePoint.toString()},
  ];

  final TextEditingController _clientNameController = TextEditingController();

  // Function to add a new client
  void _addClient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add New Client"),
          content: TextField(
            controller: _clientNameController,
            decoration: const InputDecoration(
              labelText: "Client Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_clientNameController.text.isNotEmpty) {
                  setState(() {
                    clients.add({
                      "name": _clientNameController.text,
                      "icon": Icons.person.codePoint.toString(),
                    });
                  });
                  _clientNameController.clear();
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to your existing MyHomePage and pass the client name as the title
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyHomePage(title: client["name"]!),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: Icon(
                            IconData(
                              int.parse(client["icon"]!),
                              fontFamily: 'MaterialIcons',
                            ),
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          client["name"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addClient,
              icon: const Icon(Icons.person_add, size: 24),
              label: const Text(
                "Add New Client",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
