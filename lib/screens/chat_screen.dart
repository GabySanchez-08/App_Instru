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

  Future<void> _send() async {
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
    // 1) Traemos *todos* los mensajes, ordenados por fecha
    final stream = FirebaseFirestore.instance
        .collection('mensajes')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allDocs = snap.data?.docs ?? [];
                // 2) Filtramos en el cliente solo los que realmente son entre estos dos roles
                final docs = allDocs.where((doc) {
                  final m = doc.data()! as Map<String, dynamic>;
                  final from = m['fromRole'] as String?;
                  final to   = m['toRole']   as String?;
                  return (from == widget.myRole && to == widget.otherRole)
                      || (from == widget.otherRole && to == widget.myRole);
                }).toList();

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(hintText: 'Escribe un mensaje'),
                      onSubmitted: (_) => _sending ? null : _send(),
                    ),
                  ),
                  _sending
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _send,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}