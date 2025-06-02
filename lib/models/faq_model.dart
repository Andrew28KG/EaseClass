import 'package:cloud_firestore/cloud_firestore.dart';

class FAQModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final Timestamp createdAt;
  final bool isActive;

  FAQModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.createdAt,
    this.isActive = true,
  });
  factory FAQModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FAQModel(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      category: data['category'] ?? 'General',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
} 