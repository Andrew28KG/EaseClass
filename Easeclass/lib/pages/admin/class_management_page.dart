import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import 'edit_class_page.dart';
import 'add_class_page.dart';
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddClassPage()),
            ).then((_) {
              // The stream builder will automatically update when we return
            });
          },
          tooltip: 'Add New Class',
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
}
