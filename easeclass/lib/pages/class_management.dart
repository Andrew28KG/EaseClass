import 'package:flutter/material.dart';
import '../services/class_service.dart';
import '../models/class_model.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({Key? key}) : super(key: key);

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  final ClassService _classService = ClassService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }
  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final classes = await _classService.getClasses();
      
      if (mounted) {
        setState(() {
          _classes = classes.map((c) => {
            'id': c.id,
            'name': c.name,
            'description': c.description,
            'building': c.building,
            'floor': c.floor,
            'capacity': c.capacity,
            'isAvailable': c.isAvailable,
            'features': c.features,
            'rating': c.rating,
            'imageUrl': c.imageUrl,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading classes: $e');
      // Use dummy data in case of error
      setState(() {
        _classes = [
          {
            'id': '1',
            'name': 'Programming Classroom',
            'description': 'Main programming lab with computers',
            'building': 'A',
            'floor': 2,
            'capacity': 30,
            'isAvailable': true,
            'features': ['Computers', 'Projector', 'Whiteboard'],
            'rating': 4.5,
          },
          {
            'id': '2',
            'name': 'Database Lab',
            'description': 'Database and server room',
            'building': 'B',
            'floor': 1,
            'capacity': 25,
            'isAvailable': true,
            'features': ['Computers', 'Server Equipment'],
            'rating': 4.0,
          },
          {
            'id': '3',
            'name': 'Design Studio',
            'description': 'Creative space for design classes',
            'building': 'C',
            'floor': 3,
            'capacity': 20,
            'isAvailable': false,
            'features': ['Drawing Tables', 'Mac Computers', 'Projector'],
            'rating': 4.8,
          },
        ];
        _isLoading = false;
      });
    }
  }

  void _showAddClassDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final buildingController = TextEditingController();
    final floorController = TextEditingController();
    final capacityController = TextEditingController();
    final featuresController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Classroom Name',
                  hintText: 'Enter classroom name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter classroom description',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: buildingController,
                decoration: const InputDecoration(
                  labelText: 'Building',
                  hintText: 'Enter building (e.g., A, B, C)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: floorController,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  hintText: 'Enter floor number',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Enter room capacity',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features',
                  hintText: 'Enter comma-separated features',
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
          ElevatedButton(            onPressed: () async {
              // Create new classroom
              final List<String> features = featuresController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
                  
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adding class...')),
              );
              
              try {
                // Create ClassModel
                final classModel = ClassModel(
                  id: '', // Firestore will generate this
                  name: nameController.text,
                  description: descriptionController.text,
                  building: buildingController.text,
                  floor: int.tryParse(floorController.text) ?? 1,
                  capacity: int.tryParse(capacityController.text) ?? 20,
                  rating: 0.0, // Default rating for new class
                  isAvailable: true,
                  features: features,
                  imageUrl: null, // No image for new class initially
                );
                
                // Save to Firestore and get the new ID
                final newId = await _classService.addClass(classModel);
                
                // Add to local list with the new ID
                final newClass = {
                  'id': newId,
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'building': buildingController.text,
                  'floor': int.tryParse(floorController.text) ?? 1,
                  'capacity': int.tryParse(capacityController.text) ?? 20,
                  'isAvailable': true,
                  'features': features,
                  'rating': 0.0,
                };
                
                setState(() {
                  _classes.add(newClass);
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class added successfully')),
                );
              } catch (e) {
                print('Error adding class: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding class: ${e.toString()}')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddClassDialog,
              child: const Icon(Icons.add),
            ),
            body: RefreshIndicator(
              onRefresh: _loadClasses,
              child: _classes.isEmpty
                  ? const Center(
                      child: Text(
                        'No classes found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _classes.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final classItem = _classes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            title: Text(
                              classItem['name'] ?? 'Unnamed Classroom',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Building: ${classItem['building'] ?? '-'}, Floor: ${classItem['floor'] ?? '-'}',
                            ),
                            trailing: Switch(
                              value: classItem['isAvailable'] ?? false,                              onChanged: (value) async {
                                final classId = _classes[index]['id'];
                                setState(() {
                                  _classes[index]['isAvailable'] = value;
                                });
                                
                                try {
                                  await _classService.updateClass(
                                    classId, 
                                    {'isAvailable': value}
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value 
                                          ? 'Class marked as available' 
                                          : 'Class marked as unavailable'
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                } catch (e) {
                                  // Revert the change if the update fails
                                  setState(() {
                                    _classes[index]['isAvailable'] = !value;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update: $e')),
                                  );
                                }
                              },
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(classItem['description'] ?? 'No description available'),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Capacity: ${classItem['capacity'] ?? 0}'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Features:'),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: (classItem['features'] as List<dynamic>? ?? [])
                                          .map((feature) => Chip(
                                                label: Text(feature.toString()),
                                              ))
                                          .toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Edit'),                                          onPressed: () {
                                            // Implement edit functionality
                                            final classItem = _classes[index];
                                            final nameController = TextEditingController(text: classItem['name']);
                                            final descriptionController = TextEditingController(text: classItem['description']);
                                            final buildingController = TextEditingController(text: classItem['building']);
                                            final floorController = TextEditingController(text: classItem['floor']?.toString() ?? '1');
                                            final capacityController = TextEditingController(text: classItem['capacity']?.toString() ?? '20');
                                            final featuresController = TextEditingController(
                                              text: (classItem['features'] as List<dynamic>?)?.join(', ') ?? '',
                                            );
                                            
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Edit Class'),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller: nameController,
                                                        decoration: const InputDecoration(labelText: 'Classroom Name'),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: descriptionController,
                                                        decoration: const InputDecoration(labelText: 'Description'),
                                                        maxLines: 2,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: buildingController,
                                                        decoration: const InputDecoration(labelText: 'Building'),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: floorController,
                                                        decoration: const InputDecoration(labelText: 'Floor'),
                                                        keyboardType: TextInputType.number,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: capacityController,
                                                        decoration: const InputDecoration(labelText: 'Capacity'),
                                                        keyboardType: TextInputType.number,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: featuresController,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Features',
                                                          hintText: 'Comma-separated features',
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
                                                      final classId = classItem['id'];
                                                      
                                                      // Parse features list
                                                      final List<String> features = featuresController.text
                                                          .split(',')
                                                          .map((e) => e.trim())
                                                          .where((e) => e.isNotEmpty)
                                                          .toList();
                                                      
                                                      // Update data
                                                      final updatedData = {
                                                        'name': nameController.text,
                                                        'description': descriptionController.text,
                                                        'building': buildingController.text,
                                                        'floor': int.tryParse(floorController.text) ?? 1,
                                                        'capacity': int.tryParse(capacityController.text) ?? 20,
                                                        'features': features,
                                                      };
                                                      
                                                      try {
                                                        // Update in Firestore
                                                        await _classService.updateClass(classId, updatedData);
                                                        
                                                        // Update local state
                                                        setState(() {
                                                          _classes[index] = {
                                                            ..._classes[index],
                                                            ...updatedData,
                                                          };
                                                        });
                                                        
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Class updated successfully')),
                                                        );
                                                      } catch (e) {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Error updating class: $e')),
                                                        );
                                                      }
                                                    },
                                                    child: const Text('Save Changes'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            // Show delete confirmation
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Class'),
                                                content: Text('Are you sure you want to delete "${classItem['name']}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(                                                    onPressed: () async {
                                                      final classId = _classes[index]['id'];
                                                      final className = _classes[index]['name'];
                                                      
                                                      try {
                                                        // Remove from the UI first for better UX
                                                        setState(() {
                                                          _classes.removeAt(index);
                                                        });
                                                        
                                                        // Delete from Firestore
                                                        await _classService.deleteClass(classId);
                                                        
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Class "$className" deleted')),
                                                        );
                                                      } catch (e) {
                                                        // Show error and reload the list
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Failed to delete: $e')),
                                                        );
                                                        _loadClasses(); // Reload the list
                                                      }
                                                    },
                                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          );
  }
}