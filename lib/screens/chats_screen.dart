import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'users_screen.dart';

class ChatsScreen extends StatelessWidget {
  ChatsScreen({super.key});

  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          final chats = snapshot.data!.docs;
          final currentUid = _auth.currentUser!.uid;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {

              final chat = chats[index];
              final members = List<String>.from(chat['members']);

              // Get the other user UID
              final otherUserId =
              members.firstWhere((uid) => uid != currentUid);

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {

                  if (!userSnapshot.hasData) {
                    return const ListTile(
                        title: Text("Loading..."));
                  }

                  final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

                  final username = userData['email'];

                  final lastMessage = chat['lastMessage'] ?? '';
                  final Timestamp? timestamp = chat['lastTimestamp'];

                  String time = '';
                  if (timestamp != null) {
                    final date = timestamp.toDate();
                    time =
                    "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),

                    title: Text(
                      userData['username'] ?? 'user',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      chat['lastMessage'] ?? ''  ,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    trailing: Text(
                      time,
                      style: const TextStyle(fontSize: 12),
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(chatId: chat.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.chat),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsersScreen(),
            ),
          );
        },
      ),
    );
  }
}