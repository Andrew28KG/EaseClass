import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/room_model.dart';
import '../../theme/app_colors.dart';

class AdminAvailableRoomsPage extends StatefulWidget {
  const AdminAvailableRoomsPage({Key? key}) : super(key: key);

  @override
  State<AdminAvailableRoomsPage> createState() => _AdminAvailableRoomsPageState();
}

class _AdminAvailableRoomsPageState extends State<AdminAvailableRoomsPage> {
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  String selectedCapacity = 'All';
  bool isFilterExpanded = false;
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();
  List<RoomModel> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final rooms = await _firestoreService.getRooms();
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rooms: $e')),
      );
    }
  }

  List<RoomModel> _getFilteredRooms() {
    return _rooms.where((room) {
      bool matchesBuilding = selectedBuilding == 'All' || room.building == selectedBuilding;
      bool matchesFloor = selectedFloor == 'All' || room.floor == selectedFloor;
      bool matchesCapacity = selectedCapacity == 'All' || 
        (selectedCapacity == '< 30' && room.capacity < 30) ||
        (selectedCapacity == '30-60' && room.capacity >= 30 && room.capacity <= 60) ||
        (selectedCapacity == '> 60' && room.capacity > 60);
      
      return matchesBuilding && matchesFloor && matchesCapacity;
    }).toList();
  }

  // Get unique buildings for filter
  List<String> _getBuildings() {
    Set<String> buildings = _rooms.map((room) => room.building).toSet();
    return ['All', ...buildings];
  }
  // Get unique floors for filter
  List<String> _getFloors() {
    Set<String> floors = _rooms.map((room) => room.floor.toString()).toSet();
    return ['All', ...floors];
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = _getFilteredRooms();
    
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation
      child: Scaffold(
        // No AppBar since this is embedded in AdminMainPage
        body: RefreshIndicator(
          onRefresh: _loadRooms,
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
                          'Filter Rooms',
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
                      'Available Rooms: ${filteredRooms.length}',
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
              
              // Room list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRooms.isEmpty
                        ? const Center(child: Text('No rooms available matching the filters'))
                        : ListView.builder(
                            itemCount: filteredRooms.length,
                            itemBuilder: (context, index) {
                              final room = filteredRooms[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [                                          Text(
                                            "Room ${room.id}",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: room.isAvailable
                                                  ? Colors.green
                                                  : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              room.isAvailable ? 'Available' : 'Unavailable',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text('Building: ${room.building}, Floor: ${room.floor}'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.people, size: 16, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text('Capacity: ${room.capacity} people'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.star, size: 16, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text('Rating: ${room.rating.toStringAsFixed(1)}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: room.features.map((facility) {
                                          return Chip(
                                            label: Text(
                                              facility,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor: AppColors.lightGrey,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              // Toggle room availability
                                              _firestoreService.updateRoomAvailability(
                                                room.id, 
                                                !room.isAvailable
                                              ).then((_) => _loadRooms());
                                            },
                                            icon: Icon(
                                              room.isAvailable 
                                                  ? Icons.block 
                                                  : Icons.check_circle,
                                            ),
                                            label: Text(
                                              room.isAvailable 
                                                  ? 'Mark Unavailable' 
                                                  : 'Mark Available',
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: room.isAvailable 
                                                  ? Colors.red 
                                                  : Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () {
                                              // View room details or edit
                                              // This would open a detailed view of the room
                                            },
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                          ),
                                        ],
                                      ),
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
