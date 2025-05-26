import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/faq_model.dart';
import '../../services/firestore_service.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({Key? key}) : super(key: key);

  @override
  State<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingFAQs = true;
  bool _isLoadingEvents = true;
  List<FAQModel> _faqs = [];
  List<FAQModel> _filteredFAQs = [];
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
    _loadEvents();
    _searchController.addListener(_filterFAQs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFAQs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFAQs = _faqs;
      } else {
        _filteredFAQs = _faqs.where((faq) {
          return faq.question.toLowerCase().contains(query) ||
              faq.answer.toLowerCase().contains(query) ||
              faq.category.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoadingFAQs = true);
    try {
      final querySnapshot = await _firestore
          .collection('faqs')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _faqs = querySnapshot.docs
              .map((doc) => FAQModel.fromFirestore(doc))
              .toList();
          _filteredFAQs = _faqs;
          _isLoadingFAQs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFAQs = false;
          _faqs = [];
          _filteredFAQs = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading FAQs: $e')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('order', descending: false)
          .get();
      
      List<Map<String, dynamic>> events = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'isActive': data['isActive'] ?? true,
          'imageUrl': data['imageUrl'] ?? '',
          'order': data['order'] ?? 1,
        };
      }).toList();

      // Ensure we always have exactly 4 events
      if (events.length < 4) {
        await _initializeDefaultEvents();
        // Reload after initialization
        final newQuerySnapshot = await _firestore
            .collection('events')
            .orderBy('order', descending: false)
            .get();
        
        events = newQuerySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'content': data['content'] ?? '',
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'isActive': data['isActive'] ?? true,
            'imageUrl': data['imageUrl'] ?? '',
            'order': data['order'] ?? 1,
          };
        }).toList();
      }

      // Always maintain exactly 4 events, taking first 4 if there are more
      events = events.take(4).toList();

      if (mounted) {
        setState(() {
          _events = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
          _events = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading event slider: $e')),
        );
      }
    }
  }

  Future<void> _initializeDefaultEvents() async {
    try {
      final CollectionReference eventsCollection = _firestore.collection('events');
      
      final defaultEvents = [
        {
          'title': 'Event Slide 1',
          'content': 'Click to edit this slide',
          'imageUrl': '',
          'isActive': true,
          'order': 1,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Event Slide 2',
          'content': 'Click to edit this slide',
          'imageUrl': '',
          'isActive': true,
          'order': 2,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Event Slide 3',
          'content': 'Click to edit this slide',
          'imageUrl': '',
          'isActive': true,
          'order': 3,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Event Slide 4',
          'content': 'Click to edit this slide',
          'imageUrl': '',
          'isActive': true,
          'order': 4,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final eventData in defaultEvents) {
        await eventsCollection.add(eventData);
      }
    } catch (e) {
      debugPrint('Error initializing default events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade100,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'FAQs'),
                Tab(text: 'Event Slider'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFAQsTab(),
                _buildEventsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQsTab() {
    if (_isLoadingFAQs) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
            // FAQ list
            Expanded(
              child: _filteredFAQs.isEmpty
                  ? _buildEmptyState(
                      _searchController.text.isNotEmpty
                          ? 'No FAQs match your search'
                          : 'No FAQs found',
                      Icons.question_answer)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFAQs.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final faq = _filteredFAQs[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              faq.question,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(faq.answer),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    faq.category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: "Edit FAQ",
                                  onPressed: () { 
                                    debugPrint("Edit button clicked for FAQ: ${faq.id}");
                                    _editFAQ(faq);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Delete FAQ",
                                  onPressed: () => _deleteFAQ(faq),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _addFAQ(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit the 4 main event slider images. These slides are shown on the homepage.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Event cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4, // Always show exactly 4 slots
            itemBuilder: (context, index) {
              final event = index < _events.length ? _events[index] : null;

              if (event == null) {
                // Show placeholder for missing events
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading slide ${index + 1}...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _buildEventCard(event, index);
            },
          ),
        ),
      ],
    );
  }
  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: () {
          debugPrint("Event card clicked: ${event['id']}");
          _showEventDialog(event);
        },
        borderRadius: BorderRadius.circular(4.0),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe image display that handles null, empty or invalid URLs
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[300],
              child: (event['imageUrl'] != null && event['imageUrl'].toString().isNotEmpty)
                ? Image.network(
                    event['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                    ),
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (frame == null) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return child;
                    },
                  )
                : Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slide ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['title']?.isEmpty == true ? 'No title set' : event['title'] ?? 'No title set',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['content']?.isEmpty == true
                        ? 'No description set'
                        : event['content'] ?? 'No description set',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add new content using the + button',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // FAQ Management
  void _addFAQ() {
    _showFAQDialog(null);
  }

  void _editFAQ(FAQModel faq) {
    debugPrint("Editing FAQ with ID: ${faq.id}");
    _showFAQDialog(faq);
  }  void _showFAQDialog(FAQModel? faq) async {
    final isEditing = faq != null;
    final questionController = TextEditingController(
        text: isEditing ? faq.question : '');
    final answerController = TextEditingController(
        text: isEditing ? faq.answer : '');

    // Get dynamic categories from database
    List<String> categories = await _firestoreService.getFAQCategories();
    
    // Ensure we have at least some default categories if database is empty
    if (categories.isEmpty) {
      categories = ['General', 'Booking', 'Rooms', 'Classes', 'Account', 'Policies'];
    }
    
    // Ensure the current FAQ's category is included in the list
    if (isEditing && !categories.contains(faq.category)) {
      categories.add(faq.category);
    }
    
    // Make sure we always have 'General' category as a fallback
    if (!categories.contains('General')) {
      categories.add('General');
    }
    
    // Sort categories for better UX
    categories.sort();
    
    // Set the default category - ensure it exists in the list
    String category = isEditing ? faq.category : 'General';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit FAQ' : 'Add New FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Question'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          category = value;
                        });
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final question = questionController.text.trim();
              final answer = answerController.text.trim();

              if (question.isEmpty || answer.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              if (isEditing) {
                _saveFAQ(
                  faq.id,
                  question,
                  answer,
                  category,
                );
              } else {
                _createFAQ(
                  question,
                  answer,
                  category,
                );
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFAQ(
    String question,
    String answer,
    String category,
  ) async {
    try {
      await _firestore.collection('faqs').add({
        'question': question,
        'answer': answer,
        'category': category,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ added successfully')),
      );

      _loadFAQs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding FAQ: $e')),
      );
    }
  }

  Future<void> _saveFAQ(
    String id,
    String question,
    String answer,
    String category,
  ) async {
    try {
      await _firestore.collection('faqs').doc(id).update({
        'question': question,
        'answer': answer,
        'category': category,
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ updated successfully')),
      );

      _loadFAQs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating FAQ: $e')),
      );
    }
  }

  Future<void> _deleteFAQ(FAQModel faq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: const Text('Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _firestore.collection('faqs').doc(faq.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ deleted successfully')),
      );

      _loadFAQs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting FAQ: $e')),
      );
    }
  }
  // Event Slider Management
  void _showEventDialog(Map<String, dynamic> event) {
    debugPrint("Opening dialog for event: ${event['id']}");
    final titleController = TextEditingController(text: event['title'] ?? '');
    final contentController = TextEditingController(text: event['content'] ?? '');
    final imageUrlController = TextEditingController(text: event['imageUrl'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Event Slide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'https://example.com/image.jpg',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Image preview with fixed constraints
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: imageUrlController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrlController.text,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, 
                                             size: 36, 
                                             color: Colors.grey.shade600),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Invalid image URL',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, 
                                       size: 36, 
                                       color: Colors.grey.shade600),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image URL provided',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Close the dialog first to avoid layout issues
                      Navigator.pop(context);
                      
                      final title = titleController.text.trim();
                      final content = contentController.text.trim();
                      String imageUrl = imageUrlController.text.trim();

                      if (title.isEmpty || content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill title and description')),
                        );
                        return;
                      }
                      
                      // If URL is invalid, set to empty string to avoid rendering issues
                      bool isValidUrl = imageUrl.isEmpty || 
                        Uri.tryParse(imageUrl)?.hasAbsolutePath == true;
                      
                      if (!isValidUrl) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid image URL format - saving without image')),
                        );
                        imageUrl = '';
                      }

                      _saveEvent(
                        event['id'] ?? '',
                        title,
                        content,
                        imageUrl,
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }  Future<void> _saveEvent(
    String id,
    String title,
    String content,
    String imageUrl,
  ) async {
    try {
      await _firestore.collection('events').doc(id).update({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'isActive': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event slide updated successfully')),
      );

      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating event slide: $e')),
      );
    }
  }
}