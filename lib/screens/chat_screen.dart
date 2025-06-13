// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String myRole;    // 'paciente' o 'familiar'
  final String otherRole; // contraparte
  const ChatScreen({super.key, required this.myRole, required this.otherRole});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final me = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('mensajes').add({
      'fromId': me.uid,
      'fromRole': widget.myRole,
      'toRole': widget.otherRole,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('mensajes')
        .where('fromRole', whereIn: [widget.myRole, widget.otherRole])
        .where('toRole', whereIn: [widget.myRole, widget.otherRole])
        .orderBy('timestamp')
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (ctx, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final m = docs[i].data()! as Map<String, dynamic>;
                    final mine = m['fromRole'] == widget.myRole;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(m['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje'),
                  ),
                ),
                IconButton(
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _sending ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}