import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class SelectionModel {
  final String id;
  final int timestamp;
  final String userId;

  SelectionModel({
    required this.id,
    required this.timestamp,
    required this.userId,
  });

  factory SelectionModel.fromMap(Map<dynamic, dynamic> map) {
    return SelectionModel(
      id: map['id'],
      timestamp: map['timestamp'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'userId': userId,
    };
  }
}

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {
  final databaseRef = FirebaseDatabase.instance.ref('selections');
  List<SelectionModel> selections = [];

  @override
  void initState() {
    super.initState();
    _createSelection();
    _fetchSelections();
  }

  void _createSelection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String id = const Uuid().v4();
    final SelectionModel selection = SelectionModel(
      id: id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      userId: user.uid,
    );

    databaseRef.child(id).set(selection.toMap());
  }

  void _fetchSelections() {
    databaseRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return;

      final List<SelectionModel> loadedSelections = [];

      data.forEach((key, value) {
        loadedSelections.add(SelectionModel.fromMap(value));
      });

      setState(() {
        selections = loadedSelections;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selections'),
      ),
      body: selections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: selections.length,
              itemBuilder: (context, index) {
                final selection = selections[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text("ID: ${selection.id}"),
                  subtitle: Text(
                    "User: ${selection.userId}\nTime: ${DateTime.fromMillisecondsSinceEpoch(selection.timestamp)}",
                  ),
                );
              },
            ),
    );
  }
}
