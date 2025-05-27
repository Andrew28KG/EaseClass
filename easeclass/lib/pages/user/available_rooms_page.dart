import 'package:flutter/material.dart';
import '../../utils/navigation_helper.dart'; // Import navigation helper
import '../../services/firestore_service.dart'; // Import Firestore service
import '../../models/room_model.dart'; // Import Room model
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class AvailableRoomsPage extends StatefulWidget {
  const AvailableRoomsPage({Key? key}) : super(key: key);

  @override
  State<AvailableRoomsPage> createState() => _AvailableRoomsPageState();
}

class _AvailableRoomsPageState extends State<AvailableRoomsPage> {
  String selectedBuilding = 'All';
  String selectedFloor = 'All';
  String selectedCapacity = 'All';
  String selectedRatingSort = 'None';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  bool isFilterExpanded = false;
  
  // Firebase services
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Check for any pending filters from navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingFilters = NavigationHelper.consumePendingFilters();
      if (pendingFilters != null && mounted) {
        setState(() {
          // Apply any filters that were passed via navigation
          if (pendingFilters.containsKey('ratingSort')) {
            selectedRatingSort = pendingFilters['ratingSort'];
            // Expand filters if a sort was applied
            isFilterExpanded = true;
          }
        });
      }
    });
  }

  // Filter constants
  final List<String> buildings = ['All', 'Building A', 'Building B', 'Building C'];
  final List<String> floors = ['All', '1st Floor', '2nd Floor', '3rd Floor'];
  final List<String> capacities = ['All', '< 20 people', '20-40 people', '> 40 people'];
  final List<String> ratingSortOptions = ['None', 'Highest to Lowest', 'Lowest to Highest'];

  // Safe version of toggle that prevents any navigation
  void _toggleFilterVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isFilterExpanded = !isFilterExpanded;
        });
      }
    });
  }

  // Apply filters method
  void _applyFilters() {
    if (mounted) {
      setState(() {
        // Here you would typically apply the filters to your data
        isFilterExpanded = false; // Auto-collapse the filter section
      });
    }
  }

  // Reset filters method
  void _resetFilters() {
    if (mounted) {
      setState(() {
        selectedBuilding = 'All';
        selectedFloor = 'All';
        selectedCapacity = 'All';
        selectedRatingSort = 'None';
        selectedDate = DateTime.now();
        selectedTime = TimeOfDay.now();
      });
    }
  }

  // Get filtered and sorted rooms
  List<RoomModel> getFilteredRooms(List<RoomModel> allRooms) {
    List<RoomModel> filteredRooms = List.from(allRooms);
    
    // Apply building filter
    if (selectedBuilding != 'All') {
      String buildingLetter = selectedBuilding.split(' ').last;
      filteredRooms = filteredRooms.where((room) => room.building == buildingLetter).toList();
    }
    
    // Apply floor filter
    if (selectedFloor != 'All') {
      int floorNumber = int.parse(selectedFloor.split(' ').first[0]);
      filteredRooms = filteredRooms.where((room) => room.floor == floorNumber).toList();
    }
    
    // Apply capacity filter
    if (selectedCapacity != 'All') {
      if (selectedCapacity.startsWith('<')) {
        filteredRooms = filteredRooms.where((room) => room.capacity < 20).toList();
      } else if (selectedCapacity.startsWith('>')) {
        filteredRooms = filteredRooms.where((room) => room.capacity > 40).toList();
      } else {
        filteredRooms = filteredRooms.where((room) => room.capacity >= 20 && room.capacity <= 40).toList();
      }
    }
    
    // Apply rating sort
    if (selectedRatingSort != 'None') {
      if (selectedRatingSort == 'Highest to Lowest') {
        filteredRooms.sort((a, b) => b.rating.compareTo(a.rating));
      } else {
        filteredRooms.sort((a, b) => a.rating.compareTo(b.rating));
      }
    }
    
    return filteredRooms;
  }

  @override
  Widget build(BuildContext context) {
    // Check if any filters are active
    bool hasActiveFilters = selectedBuilding != 'All' || 
                           selectedFloor != 'All' || 
                           selectedCapacity != 'All' ||
                           selectedRatingSort != 'None';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Classrooms'),
        actions: [
          // Using a stateful builder to isolate the filter button from any parent widget events
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setFilterState) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(isFilterExpanded ? Icons.filter_list_off : Icons.filter_list),
                  onPressed: () {
                    setFilterState(() {
                      isFilterExpanded = !isFilterExpanded;
                    });
                    // Also update the main state
                    setState(() {});
                  },
                  tooltip: isFilterExpanded ? 'Hide Filters' : 'Show Filters',
                ),
              );
            }
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section - Collapsible
          FilterSection(
            isExpanded: isFilterExpanded,
            selectedBuilding: selectedBuilding,
            selectedFloor: selectedFloor,
            selectedCapacity: selectedCapacity,
            selectedRatingSort: selectedRatingSort,
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            buildings: buildings,
            floors: floors,
            capacities: capacities,
            ratingSortOptions: ratingSortOptions,
            onBuildingChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedBuilding = value;
                });
              }
            },
            onFloorChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedFloor = value;
                });
              }
            },
            onCapacityChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCapacity = value;
                });
              }
            },
            onRatingSortChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedRatingSort = value;
                });
              }
            },
            onDateChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedDate = value;
                });
              }
            },
            onTimeChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedTime = value;
                });
              }
            },
            onApplyFilters: _applyFilters,
            onResetFilters: _resetFilters,
          ),
          // StreamBuilder to listen for real-time updates
          Expanded(
            child: StreamBuilder<List<RoomModel>>(
              stream: _firestoreService.getRoomsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading rooms: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No available classrooms found.'));
                }

                // Apply client-side filters to the data from the stream
                final allRooms = snapshot.data!;
                final filteredRooms = getFilteredRooms(allRooms);

                if (filteredRooms.isEmpty) {
                  return const Center(
                    child: Text(
                      'No classrooms match your filters',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // Display the filtered rooms in a ListView
                return ListView.builder(
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = filteredRooms[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[200],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                              ? Image.network(
                                  room.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.meeting_room,
                                    color: Colors.blue[800],
                                    size: 28,
                                  ),
                                )
                              : Icon(
                                  Icons.meeting_room,
                                  color: Colors.blue[800],
                                  size: 28,
                                ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                // Use room.name instead of room.id for the title
                                room.name, // Display the room name
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Show rating with constrained size
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 2),
                                Text(
                                  room.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display building and floor using room properties
                            Text('Building ${room.building} - Floor ${room.floor}'),
                            // Display capacity using room property
                            Text('Capacity: ${room.capacity} people'),
                            if (room.features.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: room.features.map((feature) =>
                                    Chip(
                                      label: Text(
                                        feature,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                      labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                    ))
                                    .toList(),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          NavigationHelper.navigateToRoomDetail(
                            context,
                            {
                              'roomId': room.id,
                              'building': room.building,
                              'floor': room.floor,
                            },
                          );
                        },
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

// Custom stateful widget for filter section to prevent navigation issues
class FilterSection extends StatefulWidget {
  final bool isExpanded;
  final String selectedBuilding;
  final String selectedFloor;
  final String selectedCapacity;
  final String selectedRatingSort;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final List<String> buildings;
  final List<String> floors;
  final List<String> capacities;
  final List<String> ratingSortOptions;
  final Function(String?) onBuildingChanged;
  final Function(String?) onFloorChanged;
  final Function(String?) onCapacityChanged;
  final Function(String?) onRatingSortChanged;
  final Function(DateTime?) onDateChanged;
  final Function(TimeOfDay?) onTimeChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onResetFilters;

  const FilterSection({
    Key? key,
    required this.isExpanded,
    required this.selectedBuilding,
    required this.selectedFloor,
    required this.selectedCapacity,
    required this.selectedRatingSort,
    required this.selectedDate,
    required this.selectedTime,
    required this.buildings,
    required this.floors,
    required this.capacities,
    required this.ratingSortOptions,
    required this.onBuildingChanged,
    required this.onFloorChanged,
    required this.onCapacityChanged,
    required this.onRatingSortChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onApplyFilters,
    required this.onResetFilters,
  }) : super(key: key);

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  // Focus node to manage focus and prevent unexpected navigation
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Format time with proper padding
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show date picker with a totally isolated approach to prevent navigation issues
  void _selectDate(BuildContext context) {
    // Prevent widget build during rendering
    Future.microtask(() {
      // Create calendar grid in a bottom sheet instead of using the standard date picker
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (bottomSheetContext) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      "Select Date",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CalendarDatePicker(
                  initialDate: widget.selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  onDateChanged: (newDate) {
                    // Update the date if it changed
                    if (mounted && newDate != widget.selectedDate) {
                      widget.onDateChanged(newDate);
                    }
                    // Close the bottom sheet
                    Navigator.pop(bottomSheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Show time picker with a totally isolated approach to prevent navigation issues
  void _selectTime(BuildContext context) {
    // Prevent widget build during rendering
    Future.microtask(() {
      // Create time picker in a bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (bottomSheetContext) => SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              // Local state for hour and minute
              TimeOfDay currentTime = widget.selectedTime;
              
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Select Time",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Time Display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _formatTime(currentTime),
                        style: const TextStyle(
                          fontSize: 36, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Hour and Minute Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hours
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Hour", style: TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: const EdgeInsets.all(8),
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 50,
                                  perspective: 0.005,
                                  diameterRatio: 1.5,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                    initialItem: currentTime.hour,
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      currentTime = TimeOfDay(hour: index, minute: currentTime.minute);
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 24,
                                    builder: (context, index) {
                                      return Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: currentTime.hour == index
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: currentTime.hour == index
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: currentTime.hour == index
                                                ? Colors.blue
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Minute
                        Expanded(
                          child: Column(
                            children: [
                              const Text("Minute", style: TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: const EdgeInsets.all(8),
                                child: ListWheelScrollView.useDelegate(
                                  itemExtent: 50,
                                  perspective: 0.005,
                                  diameterRatio: 1.5,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: FixedExtentScrollController(
                                    initialItem: currentTime.minute,
                                  ),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      currentTime = TimeOfDay(hour: currentTime.hour, minute: index);
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: 60,
                                    builder: (context, index) {
                                      return Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: currentTime.minute == index
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          index.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: currentTime.minute == index
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: currentTime.minute == index
                                                ? Colors.blue
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Confirm Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (mounted) {
                                widget.onTimeChanged(currentTime);
                              }
                              Navigator.pop(bottomSheetContext);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Confirm",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: widget.isExpanded ? null : 0,
        child: Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Find available classrooms based on your preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Building Section
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Select which campus building and floor you prefer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Building and Floor in Row
                Row(
                  children: [
                    // Building Filter
                    Expanded(
                      child: SimpleDropdown(
                        items: widget.buildings,
                        value: widget.selectedBuilding,
                        label: 'Building',
                        iconData: Icons.business,
                        onChanged: widget.onBuildingChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Floor Filter
                    Expanded(
                      child: SimpleDropdown(
                        items: widget.floors,
                        value: widget.selectedFloor,
                        label: 'Floor',
                        iconData: Icons.stairs,
                        onChanged: widget.onFloorChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Capacity Section
                const Text(
                  'Room Size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Choose a room that fits your group size',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Capacity Filter
                SimpleDropdown(
                  items: widget.capacities,
                  value: widget.selectedCapacity,
                  label: 'Capacity',
                  iconData: Icons.people,
                  onChanged: widget.onCapacityChanged,
                ),
                const SizedBox(height: 16),
                
                // Rating Sort Section
                const Text(
                  'Rating Sort',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Choose a rating sort option',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Rating Sort Filter
                SimpleDropdown(
                  items: widget.ratingSortOptions,
                  value: widget.selectedRatingSort,
                  label: 'Rating Sort',
                  iconData: Icons.star,
                  onChanged: widget.onRatingSortChanged,
                ),
                const SizedBox(height: 16),
                
                // Availability Section
                const Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Select when you need the room',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Date and Time in Row
                Row(
                  children: [
                    // Date Picker - Using ElevatedButton to prevent navigation issues
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Text('Date', style: TextStyle(fontSize: 12)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _selectDate(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                backgroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, top: 4.0),
                            child: Text('Tap to select', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Time Picker - Using ElevatedButton to prevent navigation issues
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Text('Time', style: TextStyle(fontSize: 12)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _selectTime(context),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                backgroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(_formatTime(widget.selectedTime)),
                                  ),
                                  const Icon(Icons.access_time, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, top: 4.0),
                            child: Text('Tap to select', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Apply Filter Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onApplyFilters,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Apply Filters'),
                  ),
                ),
                
                // Reset Filter Button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: widget.onResetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple Dropdown Widget to avoid navigation issues
class SimpleDropdown extends StatelessWidget {
  final List<String> items;
  final String value;
  final String label;
  final Function(String?) onChanged;
  final IconData? iconData;

  const SimpleDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.label,
    required this.onChanged,
    this.iconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          hint: Text(label),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  if (iconData != null) ...[
                    Icon(iconData, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                  ],
                  Text(item),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}