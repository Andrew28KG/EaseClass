import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import '../../theme/app_colors.dart';

class AdminAvailableClassesPage extends StatefulWidget {
  const AdminAvailableClassesPage({Key? key}) : super(key: key);

  @override
  State<AdminAvailableClassesPage> createState() => _AdminAvailableClassesPageState();
}

class _AdminAvailableClassesPageState extends State<AdminAvailableClassesPage> {
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  String selectedCapacity = 'All';
  bool isFilterExpanded = false;
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();
  List<ClassModel> _classes = [];
  bool _isLoading = true;

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
      final classes = await _firestoreService.getClasses();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading classes: $e')),
      );
    }
  }

  List<ClassModel> _getFilteredClasses() {
    return _classes.where((classItem) {
      bool matchesBuilding = selectedBuilding == 'All' || classItem.building == selectedBuilding;
      bool matchesFloor = selectedFloor == 'All' || classItem.floor.toString() == selectedFloor;
      bool matchesCapacity = selectedCapacity == 'All' || 
        (selectedCapacity == '< 30' && classItem.capacity < 30) ||
        (selectedCapacity == '30-60' && classItem.capacity >= 30 && classItem.capacity <= 60) ||
        (selectedCapacity == '> 60' && classItem.capacity > 60);
      
      return matchesBuilding && matchesFloor && matchesCapacity;
    }).toList();
  }

  // Get unique buildings for filter
  List<String> _getBuildings() {
    Set<String> buildings = _classes.map((classItem) => classItem.building).toSet();
    return ['All', ...buildings];
  }

  // Get unique floors for filter
  List<String> _getFloors() {
    Set<String> floors = _classes.map((classItem) => classItem.floor.toString()).toSet();
    return ['All', ...floors];
  }

  Future<void> _updateClassAvailability(String classId, bool isAvailable) async {
    try {
      await _firestoreService.updateClassAvailability(classId, isAvailable);
      await _loadClasses(); // Reload the list after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating class availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _getFilteredClasses();
    
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadClasses,
          child: Column(
            children: [
              // Filter panel
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isFilterExpanded ? 170 : 0,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Classes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedBuilding,
                                decoration: const InputDecoration(
                                  labelText: 'Building',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: _getBuildings()
                                    .map((building) => DropdownMenuItem(
                                          value: building,
                                          child: Text(building),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedBuilding = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedFloor,
                                decoration: const InputDecoration(
                                  labelText: 'Floor',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: _getFloors()
                                    .map((floor) => DropdownMenuItem(
                                          value: floor,
                                          child: Text(floor),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedFloor = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCapacity,
                                decoration: const InputDecoration(
                                  labelText: 'Capacity',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: ['All', '< 30', '30-60', '> 60']
                                    .map((capacity) => DropdownMenuItem(
                                          value: capacity,
                                          child: Text(capacity),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCapacity = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedBuilding = 'All';
                                    selectedFloor = 'All';
                                    selectedCapacity = 'All';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Filter toggle button and counter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Classes: ${filteredClasses.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isFilterExpanded = !isFilterExpanded;
                        });
                      },
                      icon: Icon(
                        isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        isFilterExpanded ? 'Hide Filters' : 'Show Filters',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Class list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredClasses.isEmpty
                        ? const Center(child: Text('No classes available matching the filters'))
                        : ListView.builder(
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) {
                              final classItem = filteredClasses[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          Switch(
                                            value: classItem.isAvailable,
                                            onChanged: (value) {
                                              _updateClassAvailability(classItem.id, value);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Building: ${classItem.building}'),
                                      Text('Floor: ${classItem.floor}'),
                                      Text('Capacity: ${classItem.capacity}'),
                                      if (classItem.features.isNotEmpty)
                                        Text('Features: ${classItem.features.join(", ")}'),
                                      Text('Rating: ${classItem.rating.toStringAsFixed(1)} (${classItem.totalRatings} reviews)'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
