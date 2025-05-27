import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/navigation_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/class_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableRoomsPage extends StatefulWidget {
  final Map<String, dynamic>? applyFilter;

  const AvailableRoomsPage({
    Key? key,
    this.applyFilter,
  }) : super(key: key);

  @override
  State<AvailableRoomsPage> createState() => _AvailableRoomsPageState();
}

class _AvailableRoomsPageState extends State<AvailableRoomsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFilterExpanded = false;
  String _selectedBuilding = 'All';
  String _selectedFloor = 'All';
  String _selectedCapacity = 'All';
  String _selectedRatingSort = 'None';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _buildings = ['All'];
  List<String> _floors = ['All'];
  List<String> _capacities = ['All'];
  List<String> _ratingSortOptions = ['None', 'Highest to Lowest', 'Lowest to Highest'];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _applyInitialFilters();
  }

  void _applyInitialFilters() {
    if (widget.applyFilter != null) {
      setState(() {
        if (widget.applyFilter!['ratingSort'] != null) {
          _selectedRatingSort = widget.applyFilter!['ratingSort'];
        }
      });
    }
  }

  Future<void> _loadFilterOptions() async {
    final classes = await _firestoreService.getClasses();
    
    // Extract unique values for filters
    final buildings = classes.map((c) => c.building).toSet().toList()..sort();
    final floors = classes.map((c) => c.floor.toString()).toSet().toList()..sort();
    final capacities = classes.map((c) => c.capacity.toString()).toSet().toList()..sort();

    setState(() {
      _buildings = ['All', ...buildings];
      _floors = ['All', ...floors];
      _capacities = ['All', ...capacities];
    });
  }

  List<ClassModel> getFilteredClasses(List<ClassModel> classes) {
    return classes.where((classItem) {
      // Filter by building
      if (_selectedBuilding != 'All' && classItem.building != _selectedBuilding) {
        return false;
      }

      // Filter by floor
      if (_selectedFloor != 'All' && classItem.floor.toString() != _selectedFloor) {
        return false;
      }

      // Filter by capacity
      if (_selectedCapacity != 'All' && classItem.capacity.toString() != _selectedCapacity) {
        return false;
      }

      // Filter by availability
      if (!classItem.isAvailable) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_selectedRatingSort == 'Highest to Lowest') {
          return b.rating.compareTo(a.rating);
        } else if (_selectedRatingSort == 'Lowest to Highest') {
          return a.rating.compareTo(b.rating);
        }
        return 0;
      });
  }

  void _applyFilters() {
    setState(() {
      _isFilterExpanded = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedBuilding = 'All';
      _selectedFloor = 'All';
      _selectedCapacity = 'All';
      _selectedRatingSort = 'None';
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Classrooms'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter section
          FilterSection(
            isExpanded: _isFilterExpanded,
            selectedBuilding: _selectedBuilding,
            selectedFloor: _selectedFloor,
            selectedCapacity: _selectedCapacity,
            selectedRatingSort: _selectedRatingSort,
            selectedDate: _selectedDate,
            selectedTime: _selectedTime,
            buildings: _buildings,
            floors: _floors,
            capacities: _capacities,
            ratingSortOptions: _ratingSortOptions,
            onBuildingChanged: (value) {
              setState(() {
                _selectedBuilding = value ?? 'All';
              });
            },
            onFloorChanged: (value) {
              setState(() {
                _selectedFloor = value ?? 'All';
              });
            },
            onCapacityChanged: (value) {
              setState(() {
                _selectedCapacity = value ?? 'All';
              });
            },
            onRatingSortChanged: (value) {
              setState(() {
                _selectedRatingSort = value ?? 'None';
              });
            },
            onDateChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDate = value;
                });
              }
            },
            onTimeChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTime = value;
                });
              }
            },
            onApplyFilters: _applyFilters,
            onResetFilters: _resetFilters,
          ),
          // StreamBuilder to listen for real-time updates
          Expanded(
            child: StreamBuilder<List<ClassModel>>(
              stream: _firestoreService.getClassesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading classes: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No available classrooms found.'));
                }

                // Apply client-side filters to the data from the stream
                final allClasses = snapshot.data!;
                final filteredClasses = getFilteredClasses(allClasses);

                if (filteredClasses.isEmpty) {
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

                // Display the filtered classes in a ListView
                return ListView.builder(
                  itemCount: filteredClasses.length,
                  itemBuilder: (context, index) {
                    final classItem = filteredClasses[index];
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
                          child: classItem.imageUrl != null && classItem.imageUrl!.isNotEmpty
                              ? Image.network(
                                  classItem.imageUrl!,
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
                                classItem.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 2),
                                Text(
                                  classItem.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Building ${classItem.building} - Floor ${classItem.floor}'),
                            Text('Capacity: ${classItem.capacity} people'),
                            if (classItem.features.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: classItem.features.map((feature) =>
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
                          NavigationHelper.navigateToClassDetails(context, classItem);
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