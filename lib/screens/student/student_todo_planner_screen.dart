import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentTodoPlannerScreen extends StatefulWidget {
  const StudentTodoPlannerScreen({super.key});

  @override
  State<StudentTodoPlannerScreen> createState() => _StudentTodoPlannerScreenState();
}

class _StudentTodoPlannerScreenState extends State<StudentTodoPlannerScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _taskController = TextEditingController();

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Study Task 📚", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _taskController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "E.g., Read Science Chapter 3",
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _taskController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              if (_taskController.text.trim().isNotEmpty && user != null) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('todos')
                    .add({
                  'title': _taskController.text.trim(),
                  'isCompleted': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                _taskController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleTask(String docId, bool currentValue) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('todos')
          .doc(docId)
          .update({'isCompleted': !currentValue});
    }
  }

  void _deleteTask(String docId) {
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('todos')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Daily Study Planner 📝", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in first"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 15),
                        Text(
                          "No tasks for today!\nTap + to add your study goals.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var task = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    bool isCompleted = task['isCompleted'] ?? false;
                    String title = task['title'] ?? 'Task';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCompleted ? const Color(0xFF2EBD85).withOpacity(0.5) : Theme.of(context).dividerColor.withOpacity(0.1), 
                          width: 2
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: GestureDetector(
                          onTap: () => _toggleTask(docId, isCompleted),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted ? const Color(0xFF2EBD85) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted ? const Color(0xFF2EBD85) : const Color(0xFFE1E5F4),
                                width: 2
                              ),
                            ),
                            child: isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? Colors.grey : Theme.of(context).colorScheme.onSurface,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () => _deleteTask(docId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
} 