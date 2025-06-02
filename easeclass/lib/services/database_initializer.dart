import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;  // Method to initialize all collections
  Future<void> initializeDatabase() async {
    // Removed _createRooms() call as rooms collection is not used
    // await _createRooms();
    await _createClasses();
    await _createFaqs();
    await _createEvents(); // Add events initialization
    await _ensureAdminUser();
    // Removed sample data creation as per user request
    // if (_auth.currentUser != null) {
    //   await _createSampleBookings();
    //   await _createSampleRatings();
    // }
  }
  
  // Public method to manually create sample bookings for admin testing
  Future<void> createSampleBookingsForAdmin() async {
    // Removed sample booking creation as per user request
    // if (_auth.currentUser != null) {
    //   // Force create new sample bookings regardless of existing ones
    //   await _createSampleBookingsForced();
    // } else {
    //   print('No user logged in, cannot create sample bookings for admin');
    // }
     print('Sample booking creation for admin is disabled.'); // Add a log indicating it's disabled
  }
  
  // Create sample bookings ignoring existing ones - for admin testing
  // Removed as per user request
  // Future<void> _createSampleBookingsForced() async {
  // ... (rest of the _createSampleBookingsForced method commented out or removed)
  // }

  // Removed sample booking data generation helper
  // List<Map<String, dynamic>> _generateSampleBookingsData({required String today, required List<String> roomIds, required User currentUser}) {
  // ... (rest of the _generateSampleBookingsData method commented out or removed)
  // }

  // List of admin emails - keep in sync with AuthService
  final List<String> _adminEmails = [
    'admin@easeclass.com',
    'admin@example.com'
    // Add more admin emails as needed
  ];

  // Ensure admin user exists and has the isAdmin flag set
  Future<void> _ensureAdminUser() async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Check if the user's email is in the admin list
        bool isAdmin = _adminEmails.contains(currentUser.email);
        
        // Set user data with appropriate role and admin flag
        await _firestore.collection('users').doc(currentUser.uid).set({
          'email': currentUser.email,
          'role': isAdmin ? 'admin' : 'user',
          'isAdmin': isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('User record updated with role: ${isAdmin ? "admin" : "user"}');
      }
    } catch (e) {
      print('Error ensuring admin user: $e');
    }
  }

  // Create classes collection
  Future<void> _createClasses() async {
    final CollectionReference classesCollection = _firestore.collection('classes');
    
    // Check if classes already exist
    final QuerySnapshot existingClasses = await classesCollection.limit(1).get();
    if (existingClasses.docs.isNotEmpty) {
      print('Classes collection already initialized');
      return;
    }
    
    final List<Map<String, dynamic>> classesData = [
      {
        'name': 'Introduction to Computer Science',
        'description': 'Fundamental concepts of computer science including algorithms, data structures, and basic programming.',
        'building': 'A',
        'floor': 1,
        'capacity': 25,
        'rating': 4.7,
        'isAvailable': true,
        'features': ['Projector', 'Computer Workstations', 'Programming Software'],
        'imageUrl': 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'CS101', 'instructor': 'Dr. James Smith', 'duration': '1 semester'}
      },
      {
        'name': 'Calculus I',
        'description': 'Introduction to differential and integral calculus of functions of one variable.',
        'building': 'B',
        'floor': 2,
        'capacity': 40,
        'rating': 4.3,
        'isAvailable': true,
        'features': ['Smart Board', 'Graphic Calculators', 'Visualization Software'],
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'MATH201', 'instructor': 'Dr. Maria Garcia', 'duration': '1 semester'}
      },
      {
        'name': 'Organic Chemistry',
        'description': 'Study of structure, properties, and reactions of organic compounds and organic materials.',
        'building': 'C',
        'floor': 1,
        'capacity': 30,
        'rating': 4.5,
        'isAvailable': true,
        'features': ['Lab Equipment', 'Chemical Storage', 'Safety Gear'],
        'imageUrl': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'CHEM301', 'instructor': 'Dr. Robert Johnson', 'duration': '1 semester'}
      },
      {
        'name': 'Introduction to Psychology',
        'description': 'Overview of the scientific study of human behavior and mental processes.',
        'building': 'A',
        'floor': 2,
        'capacity': 45,
        'rating': 4.8,
        'isAvailable': true,
        'features': ['Projector', 'Audio System', 'Observation Room'],
        'imageUrl': 'https://images.unsplash.com/photo-1577896851231-70ef18881754?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'PSYC101', 'instructor': 'Dr. Sarah Williams', 'duration': '1 semester'}
      },
      {
        'name': 'Digital Marketing',
        'description': 'Comprehensive overview of marketing in the digital age, including social media, SEO, and analytics.',
        'building': 'B',
        'floor': 1,
        'capacity': 35,
        'rating': 4.6,
        'isAvailable': true,
        'features': ['Computer Workstations', 'Marketing Software', 'Internet Access'],
        'imageUrl': 'https://images.unsplash.com/photo-1517164850305-99a27ae571fe?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'MKT305', 'instructor': 'Prof. David Brown', 'duration': '1 semester'}
      },
      {
        'name': 'Advanced Machine Learning',
        'description': 'In-depth study of machine learning algorithms, neural networks, and practical applications.',
        'building': 'A',
        'floor': 3,
        'capacity': 25,
        'rating': 4.9,
        'isAvailable': true,
        'features': ['GPU Workstations', 'AI Software', 'Data Visualization Tools'],
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'courseCode': 'CS450', 'instructor': 'Dr. Lisa Chen', 'duration': '1 semester'}
      },
    ];
    
    // Add each class to the collection
    for (var classData in classesData) {
      await classesCollection.add(classData);
    }
    
    print('Classes collection initialized with ${classesData.length} documents');
  }

  // Create FAQs collection
  Future<void> _createFaqs() async {
    final CollectionReference faqsCollection = _firestore.collection('faqs');
    
    // Check if FAQs already exist
    final QuerySnapshot existingFaqs = await faqsCollection.limit(1).get();
    if (existingFaqs.docs.isNotEmpty) {
      print('FAQs collection already initialized');
      return;
    }
    
    final List<Map<String, dynamic>> faqsData = [
      {
        'question': 'How do I book a classroom?',
        'answer': 'You can book a classroom by browsing the available rooms tab, selecting a room, choosing your preferred date and time slot, and confirming the booking. The system will then reserve the room for you.',
        'order': 1,
        'category': 'Booking',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'Can I cancel my booking?',
        'answer': 'Yes, you can cancel your booking up to 24 hours before the scheduled time without any penalty. Go to My Bookings, select the booking you want to cancel, and tap the Cancel Booking button.',
        'order': 2,
        'category': 'Booking',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'What equipment is available in rooms?',
        'answer': 'Most rooms are equipped with projectors, whiteboards, and air conditioning. Specialized rooms may have additional equipment like computers, lab equipment, or audio-visual systems. Check the room details page for specific information.',
        'order': 3,
        'category': 'Facilities',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'How early can I book a room?',
        'answer': 'You can book rooms up to 30 days in advance. For special events or recurring bookings, please contact the administration office.',
        'order': 4,
        'category': 'Booking',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'Can I extend my booking time?',
        'answer': 'If the room is available after your booked time slot, you may extend your booking through the app. Go to your current booking and select "Extend Booking" option. Note that extension is subject to availability.',
        'order': 5,
        'category': 'Booking',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'Is there technical support available?',
        'answer': 'Yes, technical support is available during business hours. For immediate assistance, please call the IT helpdesk at 123-456-7890 or use the Help button in the app.',
        'order': 6,
        'category': 'Support',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'What is the maximum duration I can book a room for?',
        'answer': 'Standard bookings can be made for up to 4 hours. For longer durations, you need special permission from the department administrator.',
        'order': 7,
        'category': 'Booking',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'Are there rooms with special accessibility features?',
        'answer': 'Yes, we have rooms with accessibility features including wheelchair access, hearing loops, and adjustable height desks. Look for the "Accessible" tag when browsing rooms.',
        'order': 8,
        'category': 'Facilities',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'How do I report issues with a room?',
        'answer': 'You can report issues by going to the room details page and selecting "Report Issue" or through the Feedback section in the app. Please provide as much detail as possible.',
        'order': 9,
        'category': 'Support',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
      {
        'question': 'Can I book a room for someone else?',
        'answer': 'Faculty and staff members can book rooms on behalf of others. Students can only book rooms for their own use.',
        'order': 10,
        'category': 'Policies',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true
      },
    ];
    
    // Add each FAQ to the collection
    for (var faqData in faqsData) {
      await faqsCollection.add(faqData);
    }
    
    print('FAQs collection initialized with ${faqsData.length} documents');
  }

  // Create Events collection
  Future<void> _createEvents() async {
    final CollectionReference eventsCollection = _firestore.collection('events');
    
    // Check if events already exist
    final QuerySnapshot existingEvents = await eventsCollection.limit(1).get();
    if (existingEvents.docs.isNotEmpty) {
      print('Events collection already initialized');
      return;
    }
    
    final List<Map<String, dynamic>> eventsData = [
      {
        'title': 'Welcome to EaseClass',
        'content': 'Discover our comprehensive classroom booking system. Book rooms, manage your schedule, and enhance your learning experience with ease.',
        'imageUrl': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
        'isActive': true,
        'order': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'State-of-the-Art Facilities',
        'content': 'Experience modern classrooms equipped with the latest technology, projectors, whiteboards, and comfortable seating for optimal learning.',
        'imageUrl': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
        'isActive': true,
        'order': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Flexible Booking System',
        'content': 'Book classrooms for lectures, seminars, group studies, or special events. Our flexible system accommodates all your academic needs.',
        'imageUrl': 'https://images.unsplash.com/photo-1577896851231-70ef18881754?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
        'isActive': true,
        'order': 3,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Student Success',
        'content': 'Join thousands of students who have enhanced their academic journey through our efficient classroom management system.',
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80',
        'isActive': true,
        'order': 4,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
    
    // Add each event to the collection
    for (var eventData in eventsData) {
      await eventsCollection.add(eventData);
    }
    
    print('Events collection initialized with ${eventsData.length} documents');
  }

  // Create sample bookings (only if a user exists)
  // Removed as per user request
  // Future<void> _createSampleBookings() async {
  // ... (rest of the _createSampleBookings method commented out or removed)
  // }

  // Create sample ratings
  // Removed as per user request
  // Future<void> _createSampleRatings() async {
  // ... (rest of the _createSampleRatings method commented out or removed)
  // }
}