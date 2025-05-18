import 'package:cloud_firestore/cloud_firestore.dart';

class FAQModel {
  final String id;
  final String question;
  final String answer;
  final int order;
  final String category;
  final Timestamp createdAt;
  final bool isActive;

  FAQModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
    required this.category,
    required this.createdAt,
    required this.isActive,
  });

  factory FAQModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FAQModel(
      id: doc.id,
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      order: data['order'] ?? 0,
      category: data['category'] ?? 'General',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'order': order,
      'category': category,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
} 