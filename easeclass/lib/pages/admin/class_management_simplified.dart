import 'package:flutter/material.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import '../../pages/admin/edit_class_page.dart';
// Note: ClassEditPage was removed, edit functionality disabled for now

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final ClassService _classService = ClassService();
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  String selectedCapacity = 'All';
  String selectedAvailability = 'All';
  String selectedRatingSort = 'None';
  bool isFilterExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Simply call setState to trigger a rebuild when search query changes
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter constants
  final List<String> buildings = ['All', 'A', 'B', 'C'];
  final List<String> floors = ['All', '1', '2', '3'];
  final List<String> capacities = ['All', '< 20 people', '20-40 people', '> 40 people'];
  final List<String> availabilityOptions = ['All', 'Available', 'Unavailable'];
  final List<String> ratingSortOptions = ['None', 'Highest to Lowest', 'Lowest to Highest'];

  List<ClassModel> _applyFiltersToClasses(List<ClassModel> classes) {
     final query = _searchController.text.toLowerCase();
     List<ClassModel> filtered = classes;

      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((classItem) {
          return classItem.name.toLowerCase().contains(query) ||
                 classItem.description.toLowerCase().contains(query) ||
                 classItem.building.toLowerCase().contains(query) ||
                 classItem.features.any((feature) => feature.toLowerCase().contains(query));
        }).toList();
      }
      
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
      _searchController.clear();
      // setState here will trigger StreamBuilder rebuild with cleared filters
    });
  }

  void _showAddClassDialog() {
    final _formKey = GlobalKey<FormState>(); // Added Form Key
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final buildingController = TextEditingController();
    final floorController = TextEditingController();
    final capacityController = TextEditingController();
    bool isAvailable = true; // Added isAvailable for adding
    List<String> features = []; // Added features for adding
    
    // Controllers for adding time slots in the add dialog (optional based on UI design)
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final dayController = TextEditingController();


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: SingleChildScrollView(
          child: Form( // Wrap with Form for validation
            key: _formKey, // Assign form key
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField( // Use TextFormField for validation
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Classroom Name',
                    hintText: 'Enter classroom name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                   validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 12),
                TextFormField( // Use TextFormField
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter classroom description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                   validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField( // Use TextFormField
                        controller: buildingController,
                        decoration: InputDecoration(
                          labelText: 'Building',
                          hintText: 'A, B, C',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                         validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter building';
                            }
                            return null;
                          },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField( // Use TextFormField
                        controller: floorController,
                        decoration: InputDecoration(
                          labelText: 'Floor',
                          hintText: '1, 2, 3',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                         validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter floor';
                            }
                             if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                 TextFormField( // Use TextFormField
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
                SwitchListTile( // Added availability switch for adding
                  title: const Text('Available'),
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() {
                      isAvailable = value;
                    });
                  },
                ),
                // Add features input here if needed in the add dialog
                // Add time slots input here if needed in the add dialog
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async { // Made async
              if (_formKey.currentState!.validate()) { // Validate form
                 Navigator.pop(context); // Close dialog
                
                // Create a dummy class model with generated ID for adding
                 // Firebase will generate the actual ID when added
                final newClass = ClassModel(
                  id: '', // ID will be generated by Firestore
                  name: nameController.text,
                  description: descriptionController.text,
                  building: buildingController.text,
                  floor: int.parse(floorController.text), // Parse floor
                  capacity: int.parse(capacityController.text), // Parse capacity
                  isAvailable: isAvailable,
                  features: features, // Include features
                  rating: 0.0, // Initial rating
                   timeSlots: [], // Include time slots
                );

                try {
                  await _classService.addClass(newClass); // Use Firebase service
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class added successfully')),
                  );
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding class: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

   void _deleteClass(String classId) async { // Made async
     try {
        await _classService.deleteClass(classId); // Use Firebase service
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
        backgroundColor: Colors.orange, // Example color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Classes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Filter options
          ExpansionTile(
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
          ),
          Expanded(
            // Wrap the list display with StreamBuilder
            child: StreamBuilder<List<ClassModel>>(
              stream: _classService.getClasses(), // Listen to the stream
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading classes: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Data is available, apply filters
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          // Display a placeholder or class image if available
                           backgroundColor: Colors.orangeAccent,
                           child: Text(classItem.building, style: TextStyle(color: Colors.white)),
                          // foregroundImage: classItem.imageUrl != null ? NetworkImage(classItem.imageUrl!) : null,
                        ),
                        title: Text(classItem.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Building: ${classItem.building}, Floor: ${classItem.floor}'),
                            Text('Capacity: ${classItem.capacity}'),
                            Text('Available: ${classItem.isAvailable ? 'Yes' : 'No'}'),
                             // Display features if any
                            if (classItem.features.isNotEmpty)
                              Text('Features: ${classItem.features.join(', ')}'),
                            // Display time slots if any
                            if (classItem.timeSlots != null && classItem.timeSlots!.isNotEmpty)
                              Text('Time Slots: ${classItem.timeSlots!.map((slot) => '${slot.day} ${slot.startTime}-${slot.endTime}').join('; ')}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editClass(classItem),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteClass(classItem.id), // Pass class ID to delete
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        tooltip: 'Add New Class',
        child: const Icon(Icons.add),
      ),
    );
  }
}
