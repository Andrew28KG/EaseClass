import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/faq_model.dart';
import '../../theme/app_colors.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({Key? key}) : super(key: key);

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final faqs = await _firestoreService.getFAQs();
      final categories = faqs.map((faq) => faq.category).where((category) => category != null && category.isNotEmpty).toSet().toList();
      setState(() {
        _categories = ['All', ...categories.cast<String>()];
      });
    } catch (e) {
      debugPrint('Error loading FAQ categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category Filter
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter by Category',
                  labelStyle: TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                value: _selectedCategory ?? 'All',
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue == 'All' ? null : newValue;
                  });
                },
                icon: Icon(Icons.filter_list, color: AppColors.primary),
                isExpanded: true,
              ),
            ),
          
          // FAQ List
          Expanded(
            child: StreamBuilder<List<FAQModel>>(
              stream: _firestoreService.getFAQsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading FAQs: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No FAQs available yet.'));
                }

                final allFaqs = snapshot.data!;
                final filteredFaqs = _selectedCategory == null
                    ? allFaqs
                    : allFaqs.where((faq) => faq.category == _selectedCategory).toList();

                if (filteredFaqs.isEmpty) {
                   return const Center(child: Text('No FAQs found for this category.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = filteredFaqs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          faq.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              faq.answer,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 