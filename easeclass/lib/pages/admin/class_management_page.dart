import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import 'edit_class_page.dart';
// Note: ClassEditPage was removed, edit functionality disabled for now

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  // Filter variables
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  String selectedCapacity = 'All';
  String selectedAvailability = 'All';
  String selectedRatingSort = 'None';
  bool isFilterExpanded = false;

  // Filter constants
  final List<String> buildings = ['All', 'A', 'B', 'C'];
  final List<String> floors = ['All', '1', '2', '3'];
  final List<String> capacities = ['All', '< 20 people', '20-40 people', '> 40 people'];
  final List<String> availabilityOptions = ['All', 'Available', 'Unavailable'];
  final List<String> ratingSortOptions = ['None', 'Highest to Lowest', 'Lowest to Highest'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ClassModel> _applyFiltersToClasses(List<ClassModel> classes) {
     List<ClassModel> filtered = classes;
      
      // Apply building filter
      if (selectedBuilding != 'All') {
        filtered = filtered.where((classItem) => classItem.building == selectedBuilding).toList();
      }
      
      // Apply floor filter
      if (selectedFloor != 'All') {
        // Safely parse integer, handle potential errors
        try {
          int floorNumber = int.parse(selectedFloor);
           filtered = filtered.where((classItem) => classItem.floor == floorNumber).toList();
        } catch (e) {
          print('Error parsing floor: $e');
          // Optionally show a user-friendly error message
        }
      }
      
      // Apply capacity filter
      if (selectedCapacity != 'All') {
        if (selectedCapacity.startsWith('<')) {
          filtered = filtered.where((classItem) => classItem.capacity < 20).toList();
        } else if (selectedCapacity.startsWith('>')) {
          filtered = filtered.where((classItem) => classItem.capacity > 40).toList();
        } else {
          filtered = filtered.where((classItem) => classItem.capacity >= 20 && classItem.capacity <= 40).toList();
        }
      }
      
      // Apply availability filter
      if (selectedAvailability != 'All') {
        if (selectedAvailability == 'Available') {
          filtered = filtered.where((classItem) => classItem.isAvailable).toList();
        } else {
          filtered = filtered.where((classItem) => !classItem.isAvailable).toList();
        }
      }
      
      // Apply rating sort
      if (selectedRatingSort != 'None') {
        if (selectedRatingSort == 'Highest to Lowest') {
          filtered.sort((a, b) => b.rating.compareTo(a.rating));
        } else {
          filtered.sort((a, b) => a.rating.compareTo(b.rating));
        }
      }
      
      return filtered;
  }

  void _resetFilters() {
    setState(() {
      selectedBuilding = 'All';
      selectedFloor = 'All';
      selectedCapacity = 'All';
      selectedAvailability = 'All';
      selectedRatingSort = 'None';
    });
  }

  void _showAddClassDialog() {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedBuilding = 'A'; // Default building
    String selectedFloor = '1'; // Default floor
    final capacityController = TextEditingController();
    List<String> features = [];
    
    // Controllers for adding time slots in the add dialog (optional based on UI design)
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final dayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          File? _selectedImage;

          Future<void> _pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);

            if (pickedFile != null) {
              setState(() {
                _selectedImage = File(pickedFile.path);
              });
            }
          }

          Future<String?> _uploadImage(File imageFile) async {
            try {
              final storageRef = FirebaseStorage.instance.ref();
              final imageName = 'class_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
              final uploadTask = storageRef.child(imageName).putFile(imageFile);
              final snapshot = await uploadTask.whenComplete(() {});
              final downloadUrl = await snapshot.ref.getDownloadURL();
              return downloadUrl;
            } catch (e) {
              print('Error uploading image: $e');
              // Optionally show an error message to the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload image: $e')),
              );
              return null;
            }
          }

          return AlertDialog(
        title: const Text('Add New Class'),
        content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    hintText: 'e.g., Room 101',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                   validator: (value) {
                      if (value == null || value.isEmpty) {
                      return 'Please enter class name';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter class description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Building',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                  value: selectedBuilding,
                  items: buildings.where((b) => b != 'All').map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedBuilding = newValue;
                      });
                    }
                  },
                    ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Floor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                  value: selectedFloor,
                  items: floors.where((f) => f != 'All').map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedFloor = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Capacity',
                    hintText: 'e.g., 30',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                   validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Image Picker Button and Preview
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                  ),
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                ),
              ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    capacityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all required fields')),
                  );
                  return;
                }

                  String? imageUrl;
                  if (_selectedImage != null) {
                    // Upload image and get URL
                    imageUrl = await _uploadImage(_selectedImage!);
                    if (imageUrl == null) {
                      // If image upload failed, stop here
                      return;
                    }
                  }

                try {
                  final newClass = ClassModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                    building: selectedBuilding,
                    floor: int.parse(selectedFloor),
                  capacity: int.parse(capacityController.text),
                    isAvailable: true,
                      features: features, // Assuming features are handled elsewhere or optional
                    rating: 0.0,
                    totalRatings: 0,
                      imageUrl: imageUrl, // Include the uploaded image URL
                      timeSlots: null, // Assuming time slots are handled elsewhere or optional
                      metadata: null, // Assuming metadata is handled elsewhere or optional
                    createdAt: Timestamp.now(),
                    updatedAt: Timestamp.now(),
                      totalReviews: 0,
                      reviews: const [],
                  );

                  await _firestoreService.addClass(newClass);
                  if (mounted) {
                    Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Class added successfully')),
                  );
                  }
                } catch (e) {
                  if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding class: $e')),
                  );
                }
              }
            },
              child: const Text('Add Class'),
          ),
        ],
          );
        },
      ),
    );
  }

   void _deleteClass(String classId) async {
     try {
        await _firestoreService.deleteClass(classId); // Use FirestoreService
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
   }

  void _editClass(ClassModel classModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClassPage(classModel: classModel),
      ),
    );

    // If result is true, it means the class was updated and we should refresh
    if (result == true) {
      // StreamBuilder will automatically update, no need to manually reload
    }
  }

  Widget _buildFilterSection() {
    return ExpansionTile(
            title: const Text('Filters'),
            onExpansionChanged: (expanded) {
              setState(() {
                isFilterExpanded = expanded;
              });
            },
            initiallyExpanded: isFilterExpanded,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Building'),
                            value: selectedBuilding,
                            items: buildings.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedBuilding = newValue!;
                                // setState triggers rebuild, filters are applied in builder
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Floor'),
                            value: selectedFloor,
                            items: floors.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedFloor = newValue!;
                                // setState triggers rebuild
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                       children: [
                        Expanded(
                           child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Capacity'),
                            value: selectedCapacity,
                            items: capacities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCapacity = newValue!;
                                // setState triggers rebuild
                              });
                            },
                          ),
                        ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Availability'),
                            value: selectedAvailability,
                            items: availabilityOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedAvailability = newValue!;
                                // setState triggers rebuild
                              });
                            },
                          ),
                         ),
                       ],
                    ),
                    const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Sort by Rating'),
                      value: selectedRatingSort,
                      items: ratingSortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRatingSort = newValue!;
                          // setState triggers rebuild
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(
        body: Column(
          children: [
            // TabBar for Classes and Reviews
            TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey.shade700,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Classes'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
            // TabBarView content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Classes Tab
                  Column(
                    children: [
                      _buildFilterSection(),
                      Expanded(
                        child: StreamBuilder<List<ClassModel>>(
                          stream: _firestoreService.getClassesStream(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Error loading classes: ${snapshot.error}'));
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final classes = snapshot.data ?? [];
                            final filteredClasses = _applyFiltersToClasses(classes);

                            if (filteredClasses.isEmpty) {
                              return const Center(child: Text('No classes found.'));
                            }

                            return ListView.builder(
                              itemCount: filteredClasses.length,
                              itemBuilder: (context, index) {
                                final classItem = filteredClasses[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    title: Text(classItem.name),
                                    subtitle: Text('${classItem.building} - Floor ${classItem.floor}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${classItem.rating.toStringAsFixed(1)} ⭐'),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editClass(classItem),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteClass(classItem.id),
                                          tooltip: 'Delete Class',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // Reviews Tab
                  StreamBuilder<List<ClassModel>>(
                    stream: _firestoreService.getClassesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading reviews: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final classes = snapshot.data ?? [];
                      
                      if (classes.isEmpty) {
                        return const Center(child: Text('No reviews found.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final classItem = classes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        classItem.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            classItem.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${classItem.building} - Floor ${classItem.floor}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // TODO: Add actual reviews when review model is implemented
                                  const Text(
                                    'No reviews yet',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
          onPressed: _showAddClassDialog,
          tooltip: 'Add New Class',
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
