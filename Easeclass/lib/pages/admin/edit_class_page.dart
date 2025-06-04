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
  final _imageUrlController = TextEditingController();
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
  final TextEditingController _newTimeSlotTitleController = TextEditingController();
  final TextEditingController _newStartTimeController = TextEditingController();
  final TextEditingController _newEndTimeController = TextEditingController();
  String _newTimeSlotSelectedDay = 'Monday';

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
    _imageUrlController.text = widget.classModel.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    _newTimeSlotTitleController.dispose();
    _newStartTimeController.dispose();
    _newEndTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'building': _buildingController.text.trim(),
        'floor': int.tryParse(_floorController.text.trim()) ?? 0,
        'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
        'features': _features,
        'updatedAt': FieldValue.serverTimestamp(),
        'timeSlots': _timeSlots.map((slot) => slot.toMap()).toList(),
        'imageUrl': _imageUrlController.text.trim(),
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
                _features.add(value.trim());
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
              final value = featureController.text.trim();
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

  void _addTimeSlotDialog() async {
    _newTimeSlotTitleController.clear();
    _newStartTimeController.clear();
    _newEndTimeController.clear();
    _newTimeSlotSelectedDay = 'Monday';

    TimeSlot? newSlot;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Time Slot'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _newTimeSlotSelectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: _days.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _newTimeSlotSelectedDay = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newTimeSlotTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Course/Study Title',
                      hintText: 'e.g., Math 101',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _newStartTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: 'Select Time',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(_newStartTimeController),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _newEndTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: 'Select Time',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(_newEndTimeController),
                        ),
                      ),
                    ],
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
                onPressed: (_newStartTimeController.text.isNotEmpty && _newEndTimeController.text.isNotEmpty)
                    ? () {
                        newSlot = TimeSlot(
                          day: _newTimeSlotSelectedDay,
                          startTime: _newStartTimeController.text.trim(),
                          endTime: _newEndTimeController.text.trim(),
                          title: _newTimeSlotTitleController.text.trim().isNotEmpty ? _newTimeSlotTitleController.text.trim() : null,
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

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final String formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentImageUrl = _imageUrlController.text.trim();

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
                                    onPressed: () => _addTimeSlotDialog(),
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
                                  title: Text(slot.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
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

                    // Image URL Section
                    Text(
                      'Class Image URL',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'Enter image URL',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    if (currentImageUrl.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Image Preview:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              currentImageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Text('Failed to load image from URL'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
} 