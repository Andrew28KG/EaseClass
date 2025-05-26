import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/time_slot.dart';
import '../../services/class_service.dart';

class EditClassPage extends StatefulWidget {
  final ClassModel classModel;

  const EditClassPage({
    Key? key,
    required this.classModel,
  }) : super(key: key);

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _classService = ClassService();
  
  bool _isLoading = false;
  List<String> _features = [];
  List<TimeSlot> _timeSlots = [];
  final List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']; // Weekdays for display

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController.text = widget.classModel.name;
    _descriptionController.text = widget.classModel.description;
    _buildingController.text = widget.classModel.building;
    _floorController.text = widget.classModel.floor.toString();
    _capacityController.text = widget.classModel.capacity.toString();
    _features = List<String>.from(widget.classModel.features);
    _timeSlots = List<TimeSlot>.from(widget.classModel.timeSlots ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedClass = widget.classModel.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        building: _buildingController.text,
        floor: int.parse(_floorController.text),
        capacity: int.parse(_capacityController.text),
        features: _features,
        timeSlots: _timeSlots,
      );

      await _classService.updateClass(updatedClass.id, updatedClass.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating class: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addTimeSlot(String day) async { // Made async to wait for time picker
    TimeOfDay? selectedStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Start Time',
    );

    if (selectedStartTime == null) return; // User canceled

    TimeOfDay? selectedEndTime = await showTimePicker(
      context: context,
      initialTime: selectedStartTime, // Suggest end time after start time
      helpText: 'Select End Time',
    );

    if (selectedEndTime == null) return; // User canceled

    final TextEditingController courseEventController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Time Slot for $day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start Time: ${selectedStartTime.format(context)}'), // Display selected start time
            const SizedBox(height: 16),
            Text('End Time: ${selectedEndTime.format(context)}'), // Display selected end time
            const SizedBox(height: 16),
            TextFormField(
              controller: courseEventController,
              decoration: const InputDecoration(labelText: 'Course/Event (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _timeSlots.add(TimeSlot(
                  day: day,
                  startTime: selectedStartTime.format(context), // Use selected time
                  endTime: selectedEndTime.format(context),   // Use selected time
                  courseEvent: courseEventController.text.isNotEmpty ? courseEventController.text : null,
                ));
                // Sort time slots for better display
                _timeSlots.sort((a, b) {
                  int dayComparison = _weekdays.indexOf(a.day).compareTo(_weekdays.indexOf(b.day));
                  if (dayComparison != 0) return dayComparison;
                  return a.startTime.compareTo(b.startTime);
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editTimeSlot(TimeSlot timeSlot, int index) async { // Made async
    // Parse existing time strings into TimeOfDay objects
    TimeOfDay? initialStartTime;
    TimeOfDay? initialEndTime;
    try {
       final startTimeParts = timeSlot.startTime.split(':');
       initialStartTime = TimeOfDay(hour: int.parse(startTimeParts[0]), minute: int.parse(startTimeParts[1]));

       final endTimeParts = timeSlot.endTime.split(':');
       initialEndTime = TimeOfDay(hour: int.parse(endTimeParts[0]), minute: int.parse(endTimeParts[1]));
    } catch (e) {
        // Handle potential parsing errors, fallback to current time or null
        initialStartTime = TimeOfDay.now();
        initialEndTime = TimeOfDay.now();
        print('Error parsing time strings: $e'); // Log error
    }

    TimeOfDay? selectedStartTime = initialStartTime;
    TimeOfDay? selectedEndTime = initialEndTime;

    final TextEditingController courseEventController = TextEditingController(text: timeSlot.courseEvent);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog content
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Time Slot for ${timeSlot.day}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedStartTime ?? TimeOfDay.now(),
                        helpText: 'Select Start Time',
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedStartTime = pickedTime;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(text: selectedStartTime?.format(context)), // Use controller to display selected time
                        decoration: const InputDecoration(labelText: 'Start Time'),
                        readOnly: true, // Make it read-only as time is picked from picker
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                   GestureDetector(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedEndTime ?? selectedStartTime ?? TimeOfDay.now(),
                         helpText: 'Select End Time',
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedEndTime = pickedTime;
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                         controller: TextEditingController(text: selectedEndTime?.format(context)), // Use controller to display selected time
                        decoration: const InputDecoration(labelText: 'End Time'),
                         readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: courseEventController,
                    decoration: const InputDecoration(labelText: 'Course/Event (Optional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedStartTime != null && selectedEndTime != null) {
                       // Update the time slot in the list
                       final updatedTimeSlot = TimeSlot(
                          day: timeSlot.day,
                          startTime: selectedStartTime!.format(context),
                          endTime: selectedEndTime!.format(context),
                          courseEvent: courseEventController.text.isNotEmpty ? courseEventController.text : null,
                        );

                       setState(() {
                          _timeSlots[index] = updatedTimeSlot;
                           _timeSlots.sort((a, b) {
                              int dayComparison = _weekdays.indexOf(a.day).compareTo(_weekdays.indexOf(b.day));
                              if (dayComparison != 0) return dayComparison;
                              return a.startTime.compareTo(b.startTime);
                            });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  void _addFeature() {
    final TextEditingController featureController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Feature'),
        content: TextField(
          controller: featureController,
          decoration: const InputDecoration(
            labelText: 'Feature',
            hintText: 'Enter a feature (e.g., Projector, Whiteboard)',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _features.add(value);
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = featureController.text;
              if (value.isNotEmpty) {
                setState(() {
                  _features.add(value);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveClass,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _buildingController,
                            decoration: const InputDecoration(
                              labelText: 'Building',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Please enter a building' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _floorController,
                            decoration: const InputDecoration(
                              labelText: 'Floor',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Please enter a floor' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a capacity' : null,
                    ),
                    const SizedBox(height: 24),

                    // Features Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addFeature,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _features.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => _removeFeature(entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Time Slots Section
                    const Text(
                      'Time Slots',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _weekdays.length,
                      itemBuilder: (context, dayIndex) {
                        final day = _weekdays[dayIndex];
                        final dayTimeSlots = _timeSlots.where((slot) => slot.day == day).toList();
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      day,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => _addTimeSlot(day),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (dayTimeSlots.isEmpty)
                                  const Text('No time slots for this day'),
                                ...dayTimeSlots.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final slot = entry.value;
                                  // Find the original index of this time slot in the main _timeSlots list
                                  final originalIndex = _timeSlots.indexOf(slot);
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('${slot.startTime} - ${slot.endTime}'),
                                    subtitle: slot.courseEvent != null && slot.courseEvent!.isNotEmpty
                                      ? Text('Course/Event: ${slot.courseEvent}')
                                      : null,
                                    trailing: Row( // Use a Row for multiple trailing icons
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editTimeSlot(slot, originalIndex), // Call edit method
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _removeTimeSlot(originalIndex),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 