import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// CREATE OR GET CHAT
  Future<String> createOrGetChat(String otherUserId) async {
    final currentUid = currentUser!.uid;

    // check if chat already exists
    final query = await _firestore
        .collection('chats')
        .where('members', arrayContains: currentUid)
        .get();

    for (var doc in query.docs) {
      List members = doc['members'];
      if (members.contains(otherUserId)) {
        return doc.id;
      }
    }

    // create new chat if not found
    final newChat = await _firestore.collection('chats').add({
      'members': [currentUid, otherUserId],
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }

  /// SEND MESSAGE
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final currentUid = currentUser!.uid;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  /// GET REAL-TIME MESSAGES
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  /// GET USER CHATS
  Stream<QuerySnapshot> getUserChats() {
    final currentUid = currentUser!.uid;

    print("current user UID: $currentUid");

    return _firestore
        .collection('chats')
        .where('members', arrayContains: currentUid)
        .snapshots();
  }
}