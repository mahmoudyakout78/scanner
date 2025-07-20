import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_barcode_sdk_example/selection_model.dart';
import 'package:flutter_barcode_sdk_example/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseDatabase.instance.ref();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  String? currentUserId;
  List<SelectionModel> userSelections = [];

  void registerUser() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;

    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final user = UserModel(userId: userId, name: name, phone: phone);

    await db.child("users").child(userId).set(user.toMap());

    setState(() {
      currentUserId = userId;
      userSelections = [];
    });

    nameController.clear();
    phoneController.clear();
  }

  void addSelection() async {
    if (currentUserId == null) return;

    final selectionId = Random().nextInt(1000000).toString();
    final selection = SelectionModel(
      id: selectionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      userId: currentUserId!,
    );

    await db.child("selections").child(selectionId).set(selection.toMap());
    loadUserSelections();
  }

  void loadUserSelections() async {
    if (currentUserId == null) return;

    final snapshot = await db.child("selections")
        .orderByChild("userId")
        .equalTo(currentUserId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      final list = data.values.map((e) => SelectionModel.fromMap(Map<String, dynamic>.from(e))).toList();
      setState(() {
        userSelections = list;
      });
    } else {
      setState(() {
        userSelections = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone")),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: registerUser,
              child: const Text('REGISTER USER'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: addSelection,
              child: const Text('ADD SELECTION'),
            ),
            const Divider(),
            const Text('User Selections:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: userSelections.length,
                itemBuilder: (_, index) {
                  final sel = userSelections[index];
                  return ListTile(
                    title: Text('ID: ${sel.id}'),
                    subtitle: Text('Timestamp: ${sel.timestamp}'),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
