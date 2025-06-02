import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/time_slot.dart'; // Import TimeSlot model

class AddClassPage extends StatefulWidget {
  const AddClassPage({Key? key}) : super(key: key);

  @override
  _AddClassPageState createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  // Controllers and list for features
  final TextEditingController _featureController = TextEditingController();
  final List<String> _features = [];

  // Controllers and list for time slots
  final TextEditingController _timeSlotTitleController = TextEditingController(); // Controller for time slot title
  final TextEditingController _startTimeController = TextEditingController(); // Controller for start time
  final TextEditingController _endTimeController = TextEditingController(); // Controller for end time
  final List<TimeSlot> _timeSlots = []; // List now holds TimeSlot objects

  // Add day selection for time slots
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  String _selectedDay = 'Monday';

  // For image URL
  final TextEditingController _imageUrlController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _featureController.dispose();
    _timeSlotTitleController.dispose(); // Dispose new controllers
    _startTimeController.dispose();
    _endTimeController.dispose();
    _imageUrlController.dispose(); // Dispose the image URL controller
    super.dispose();
  }

  void _addFeature() {
    if (_featureController.text.isNotEmpty) {
      setState(() {
        _features.add(_featureController.text.trim());
        _featureController.clear();
      });
    }
  }

  void _removeFeature(String feature) {
    setState(() {
      _features.remove(feature);
    });
  }

  void _addTimeSlot() {
    final startTime = _startTimeController.text.trim();
    final endTime = _endTimeController.text.trim();
    final title = _timeSlotTitleController.text.trim();

    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      // Basic validation for time format (e.g., HH:mm)
      // final timeRegex = RegExp(r'^\\d{2}:\\d{2}$');
      // if (timeRegex.hasMatch(startTime) && timeRegex.hasMatch(endTime)) {
         setState(() {
           // Create TimeSlot object and add to list
           _timeSlots.add(TimeSlot(
             day: _selectedDay,
             startTime: startTime,
             endTime: endTime,
             title: title.isNotEmpty ? title : null, // Add title if not empty
           ));
           // Clear controllers
           _startTimeController.clear();
           _endTimeController.clear();
           _timeSlotTitleController.clear();
         });
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Invalid time format. Use HH:mm')),
      //   );
      // }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both start and end times.')),
       );
    }
  }

  void _removeTimeSlot(TimeSlot timeSlot) {
    setState(() {
      _timeSlots.remove(timeSlot);
    });
  }

  // Implement saving class data
  Future<void> _saveClass() async {
    if (_formKey.currentState!.validate()) {
      // Validate if image URL is provided
      if (_imageUrlController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a class image URL.')),
        );
        return;
      }
      // Collect data
      final classData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'building': _buildingController.text.trim(),
        'floor': int.tryParse(_floorController.text.trim()) ?? 0,
        'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
        'features': _features,
        'timeSlots': _timeSlots.map((slot) => slot.toMap()).toList(), // Save list of TimeSlot maps
        'imageUrl': _imageUrlController.text.trim(), // Use the URL from the controller
        'rating': 0.0, // Initial rating
        'isAvailable': true, // Default to available
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Add any other relevant fields
      };
      try {
        await _firestore.collection('classes').add(classData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class added successfully!')),
        );
        Navigator.pop(context); // Navigate back on success
      } catch (e) {
        print('Error saving class: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save class: $e')),
        );
      }
    }
  }

  // Helper to show time picker
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      // Format the time as HH:mm
      final String formattedTime = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current image URL from the controller to display preview
    final currentImageUrl = _imageUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Class'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buildingController,
                      decoration: const InputDecoration(labelText: 'Building'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(labelText: 'Floor'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              // Features Section
              Text(
                'Features',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _featureController,
                      decoration: const InputDecoration(
                        labelText: 'Add Feature',
                        hintText: 'e.g., Projector',
                      ),
                      onSubmitted: (_) => _addFeature(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addFeature,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _features.map((feature) => Chip(
                  label: Text(feature),
                  onDeleted: () => _removeFeature(feature),
                )).toList(),
              ),
              const SizedBox(height: 24),
              // Time Slots Section
              Text(
                'Available Time Slots',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Day Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDay,
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
                      _selectedDay = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              // New input fields for time slot details
              TextFormField(
                controller: _timeSlotTitleController,
                decoration: const InputDecoration(
                  labelText: 'Course/Study Title',
                  hintText: 'e.g., Calculus I',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        hintText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(_startTimeController),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        hintText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectTime(_endTimeController),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addTimeSlot,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Display added time slots
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _timeSlots.map((timeSlot) => Chip(
                  label: Text(timeSlot.toString()), // Use toString to display TimeSlot details
                  onDeleted: () => _removeTimeSlot(timeSlot),
                )).toList(),
              ),
              const SizedBox(height: 24),
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
                // You could add a validator here for URL format if needed
                onChanged: (_) => setState(() {}), // Trigger rebuild to show image preview
              ),
              const SizedBox(height: 16),
               // Display image preview if URL is available
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
              const SizedBox(height: 24),
              // Save Button
              ElevatedButton(
                onPressed: _saveClass,
                child: const Text('Add Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}