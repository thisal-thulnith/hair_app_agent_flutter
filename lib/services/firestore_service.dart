import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new conversation
  Future<String> createConversation({
    required String userId,
    required String title,
  }) async {
    try {
      final conversation = Conversation.create(
        userId: userId,
        title: title,
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(conversation.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Get conversations for user
  Stream<List<Conversation>> getConversationsStream(String userId) {
    try {
      return _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        final conversations = snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList();
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return conversations;
      });
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete conversation
      await _firestore.collection('conversations').doc(conversationId).delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Add message to conversation
  Future<String> addMessage({
    required String conversationId,
    required Message message,
  }) async {
    try {
      final docRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());

      // Update conversation timestamp
      await _firestore.collection('conversations').doc(conversationId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  // Get messages stream
  Stream<List<Message>> getMessagesStream(String conversationId) {
    try {
      return _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .snapshots()
          .map((snapshot) {
        print('📖 Loading ${snapshot.docs.length} messages from Firestore');
        final messages =
            snapshot.docs.map((doc) {
              final message = Message.fromFirestore(doc);
              // Debug log for assistant messages with images
              if (message.isAssistant && message.hasGeneratedImage) {
                print('  ✅ Message ${doc.id}: Has generated image');
                if (message.generatedImageUrl != null) {
                  print('     - URL: ${message.generatedImageUrl!.substring(0, 50)}...');
                }
                if (message.generatedImageBase64 != null) {
                  final sizeKB = message.generatedImageBase64!.length / 1024;
                  print('     - Base64: ${sizeKB.toStringAsFixed(2)} KB');
                }
              } else if (message.isAssistant) {
                print('  ⚠️  Message ${doc.id}: No generated image');
              }
              return message;
            }).toList();
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      });
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // Update conversation title
  Future<void> updateConversationTitle({
    required String conversationId,
    required String title,
  }) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }
}
