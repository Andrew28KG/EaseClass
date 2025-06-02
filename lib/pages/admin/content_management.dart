import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/faq_model.dart';
import '../../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
  }

  void _showFAQDialog(FAQModel? faq) async {
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
              const SizedBox(height: 16),
              StatefulBuilder(
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
                _updateFAQ(
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
      // Get the current highest order
      final querySnapshot = await _firestore
          .collection('faqs')
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      int newOrder = 1; // Default order if no FAQs exist
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        newOrder = (data['order'] ?? 0) + 1;
      }

      await _firestore.collection('faqs').add({
        'question': question,
        'answer': answer,
        'category': category,
        'createdAt': Timestamp.now(),
        'isActive': true,
        'order': newOrder,
      });

      // Refresh the FAQs list immediately
      await _loadFAQs();

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ added successfully')),
      );
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding FAQ: $e')),
      );
      }
    }
  }

  Future<void> _updateFAQ(
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

      // Refresh the FAQs list immediately
      await _loadFAQs();

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ updated successfully')),
      );
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating FAQ: $e')),
      );
      }
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

      // Refresh the FAQs list immediately
      await _loadFAQs();

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FAQ deleted successfully')),
      );
      }
    } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting FAQ: $e')),
      );
    }
  }
  }

  // Event Slider Management
    // Event Slider Management
  void _showEventDialog(Map<String, dynamic> event) async {
    debugPrint("Attempting to show event dialog for event ID: ${event['id']}");
    final isEditing = event['id'] != null && event['id'] is String && event['id'].isNotEmpty;
    final titleController = TextEditingController(text: event['title'] ?? '');
    final contentController = TextEditingController(text: event['content'] ?? '');
    bool isActive = event['isActive'] ?? true;
    int order = event['order'] ?? (_events.length + 1);
    // Store the initial image URL separately
    String? initialImageUrl = event['imageUrl'];
    // Placeholder image URL in case no image is set
    const String placeholderImageUrl = 'https://via.placeholder.com/150'; // Example placeholder

    debugPrint("Dialog variables initialized.");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          debugPrint("StatefulBuilder started for dialog.");
          File? _selectedImage; // State variable for the selected image file
          String? _currentImageUrl = initialImageUrl; // State variable for the current image URL (either initial or newly uploaded)

          // Function to pick an image from the gallery
          Future<void> _pickEventImage() async {
            debugPrint("Attempting to pick image.");
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);

            if (pickedFile != null) {
              setState(() {
                _selectedImage = File(pickedFile.path);
                // Clear the current image URL when a new image is selected
                _currentImageUrl = null;
              });
              debugPrint("Image picked successfully: ${_selectedImage?.path}");
            } else {
              debugPrint("Image picking cancelled.");
            }
          }

          // Function to upload the image to Firebase Storage
          Future<String?> _uploadEventImage(File imageFile) async {
            debugPrint("Attempting to upload image: ${imageFile.path}");
            try {
              final storageRef = FirebaseStorage.instance.ref();
              // Create a unique name for the image file
              final imageName = 'event_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
              final uploadTask = storageRef.child(imageName).putFile(imageFile);
              debugPrint("Upload task created.");
              final snapshot = await uploadTask.whenComplete(() {
                debugPrint("Upload task completed.");
              });
              final downloadUrl = await snapshot.ref.getDownloadURL();
              debugPrint("Image uploaded successfully. Download URL: $downloadUrl");
              return downloadUrl;
            } catch (e) {
              debugPrint('Error uploading event image: $e');
              // Optionally show an error message to the user
              if(mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Failed to upload image: $e')),
                 );
              }
              return null;
            }
          }

          debugPrint("Building AlertDialog UI.");
          return AlertDialog(
            title: Text(isEditing ? 'Edit Event' : 'Add New Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Image section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Image',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Display current image or preview of selected image, or placeholder
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : (_currentImageUrl?.isNotEmpty == true
                                ? Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                    ),
                                     loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Image.network( // Placeholder image
                                    placeholderImageUrl,
                                     fit: BoxFit.cover,
                                     errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                    ),
                                     loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Button to pick image
                      TextButton.icon(
                        onPressed: _pickEventImage,
                        icon: const Icon(Icons.image),
                        label: Text(_selectedImage != null || (_currentImageUrl?.isNotEmpty == true) ? 'Change Image' : 'Insert Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: const SizedBox.shrink(), // Placeholder after removing active switch
                      ),
                      // Only show order for existing events or when adding beyond initial 4
                      // Simplified: always show order input if needed, adjust logic later if required
                      // For now, we'll just use the event's current order or a default
                      // TextFormField(
                      //   decoration: const InputDecoration(labelText: 'Order'),
                      //   keyboardType: TextInputType.number,
                      //   initialValue: order.toString(),
                      //   onChanged: (value) {
                      //     order = int.tryParse(value) ?? order;
                      //   },
                      // ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                   debugPrint("Cancel button pressed.");
                   Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                   debugPrint("Save/Add button pressed.");
                  if (titleController.text.isEmpty ||
                      contentController.text.isEmpty) {
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill title and content')),
                      );
                    }
                    debugPrint("Title or content is empty.");
                    return;
                  }

                  // Determine the image URL to save
                  String? finalImageUrl = _currentImageUrl; // Start with the current URL

                  if (_selectedImage != null) {
                    debugPrint("New image selected. Uploading...");
                    // If a new image was selected, upload it
                    final uploadedUrl = await _uploadEventImage(_selectedImage!);
                    if (uploadedUrl == null) {
                      // If upload failed, don't save the event
                      debugPrint("Image upload failed. Not saving event.");
                      return;
                    }
                    finalImageUrl = uploadedUrl;
                     debugPrint("New image URL determined: $finalImageUrl");
                  } else if (_currentImageUrl == '') {
                     // If the remove image button was pressed
                    finalImageUrl = null; // Or an empty string, depending on how you store 'no image'
                     debugPrint("Image removed. Final URL set to null.");
                  }
                   // If _selectedImage is null and _currentImageUrl is not empty or '',
                   // finalImageUrl remains the initialImageUrl, which is correct.

                  final eventData = {
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'isActive': true,
                    'order': order, // Keep existing order or default
                    'imageUrl': finalImageUrl, // Use the determined image URL
                    'updatedAt': Timestamp.now(),
                  };

                  eventData['isActive'] = true; // Events added/edited via dialog are always active

                  try {
                    if (isEditing) {
                      debugPrint("Updating existing event: ${event['id']}");
                      await _firestore
                          .collection('events')
                          .doc(event['id'])
                          .update(eventData);
                       if(mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event updated successfully')),
                          );
                       }
                       debugPrint("Event updated in Firestore.");
                    } else {
                       debugPrint("Adding new event.");
                       // When adding a new event, ensure we don't exceed 4
                       if (_events.length >= 4) {
                          if(mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Cannot add more than 4 events.')),
                            );
                          }
                          debugPrint("Maximum events reached. Cannot add more.");
                          Navigator.pop(context);
                          return;
                       }
                       // For new events, the order might need careful consideration
                       // Simple approach: add to the end and re-order might be needed manually
                       eventData['createdAt'] = Timestamp.now();
                       await _firestore.collection('events').add(eventData);
                        if(mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event added successfully')),
                          );
                        }
                         debugPrint("New event added to Firestore.");
                    }

                    // Refresh the events list
                    debugPrint("Loading events after save.");
                    await _loadEvents();

                    if (mounted) {
                      debugPrint("Closing dialog after save.");
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    debugPrint('Error saving event: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving event: $e')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}