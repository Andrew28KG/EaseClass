import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/class_model.dart';
import '../../services/firestore_service.dart';
import '../../models/time_slot.dart';

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
  final _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  List<String> _features = [];
  List<TimeSlot> _timeSlots = [];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _timeSlots = List<TimeSlot>.from(widget.classModel.timeSlots ?? []);
  }

  void _initializeData() {
    _nameController.text = widget.classModel.name;
    _descriptionController.text = widget.classModel.description;
    _buildingController.text = widget.classModel.building;
    _floorController.text = widget.classModel.floor.toString();
    _capacityController.text = widget.classModel.capacity.toString();
    _features = List<String>.from(widget.classModel.features);
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
      final updatedData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'building': _buildingController.text,
        'floor': int.parse(_floorController.text),
        'capacity': int.parse(_capacityController.text),
        'features': _features,
        'updatedAt': FieldValue.serverTimestamp(),
        'timeSlots': _timeSlots.map((slot) => slot.toMap()).toList(),
      };
      await _firestoreService.updateClass(widget.classModel.id, updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class updated successfully')),
        );
        Navigator.pop(context, true);
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

  void _addTimeSlot(String day) async {
    TimeOfDay? start;
    TimeOfDay? end;
    String? courseTitle;
    final courseController = TextEditingController();
    TimeSlot? newSlot;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Time Slot for $day'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course/Study Title',
                    hintText: 'e.g., Math 101',
                  ),
                  onChanged: (value) {
                    setState(() {
                      courseTitle = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: start ?? TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            start = picked;
                          });
                        }
                      },
                      child: Text(start == null ? 'Start' : start!.format(context)),
                    ),
                    const Text('to'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: end ?? TimeOfDay(hour: 10, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            end = picked;
                          });
                        }
                      },
                      child: Text(end == null ? 'End' : end!.format(context)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (start != null && end != null && (courseTitle?.isNotEmpty ?? false))
                    ? () {
                        newSlot = TimeSlot(
                          day: day,
                          startTime: start!.format(context),
                          endTime: end!.format(context),
                          courseEvent: courseTitle,
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
    if (newSlot != null) {
      setState(() {
        _timeSlots.add(newSlot!);
      });
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
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

                    const Text(
                      'Class Study Schedule (Unavailable for Booking)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._days.map((day) {
                      final slots = _timeSlots
                          .asMap()
                          .entries
                          .where((entry) => entry.value.day == day)
                          .toList();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextButton.icon(
                                    onPressed: () => _addTimeSlot(day),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Time Slot'),
                                  ),
                                ],
                              ),
                              if (slots.isEmpty)
                                const Text('No time slots'),
                              ...slots.map((entry) {
                                final i = entry.key;
                                final slot = entry.value;
                                return ListTile(
                                  title: Text(slot.courseEvent ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeTimeSlot(i),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
} 