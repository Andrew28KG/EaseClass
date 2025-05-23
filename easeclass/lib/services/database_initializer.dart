import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to initialize all collections
  Future<void> initializeDatabase() async {
    await _createRooms();
    await _createClasses();
    await _createFaqs();
    // Only create sample bookings and ratings if a user exists
    if (_auth.currentUser != null) {
      await _createSampleBookings();
      await _createSampleRatings();
    }
  }

  // Create rooms collection
  Future<void> _createRooms() async {
    final CollectionReference roomsCollection = _firestore.collection('rooms');
    
    // Check if rooms already exist
    final QuerySnapshot existingRooms = await roomsCollection.limit(1).get();
    if (existingRooms.docs.isNotEmpty) {
      print('Rooms collection already initialized');
      return;
    }
    
    final List<Map<String, dynamic>> roomsData = [
      {
        'building': 'A',
        'floor': 1,
        'capacity': 25,
        'rating': 4.5,
        'isAvailable': true,
        'features': ['Projector', 'Whiteboard', 'Air Conditioning'],
        'imageUrl': 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Lecture', 'lastRenovation': '2021-05-10'}
      },
      {
        'building': 'A',
        'floor': 2,
        'capacity': 40,
        'rating': 4.2,
        'isAvailable': true,
        'features': ['Smart Board', 'Surround Sound', 'Air Conditioning', 'Adjustable Lighting'],
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Lecture', 'lastRenovation': '2022-01-15'}
      },
      {
        'building': 'B',
        'floor': 1,
        'capacity': 30,
        'rating': 4.8,
        'isAvailable': true,
        'features': ['Projector', 'Whiteboard', 'Video Conferencing', 'Adjustable Lighting'],
        'imageUrl': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Conference', 'lastRenovation': '2022-07-22'}
      },
      {
        'building': 'B',
        'floor': 3,
        'capacity': 20,
        'rating': 4.0,
        'isAvailable': true,
        'features': ['Whiteboard', 'Air Conditioning'],
        'imageUrl': 'https://images.unsplash.com/photo-1577896851231-70ef18881754?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Seminar', 'lastRenovation': '2020-11-05'}
      },
      {
        'building': 'C',
        'floor': 1,
        'capacity': 50,
        'rating': 4.9,
        'isAvailable': true,
        'features': ['Smart Board', 'Surround Sound', 'Video Conferencing', 'Recording Equipment', 'Adjustable Lighting'],
        'imageUrl': 'https://images.unsplash.com/photo-1517164850305-99a27ae571fe?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Auditorium', 'lastRenovation': '2023-02-10'}
      },
      {
        'building': 'C',
        'floor': 2,
        'capacity': 15,
        'rating': 3.8,
        'isAvailable': false,
        'features': ['Whiteboard', 'Air Conditioning'],
        'imageUrl': 'https://images.unsplash.com/photo-1517164850305-99a27ae571fe?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Study Room', 'lastRenovation': '2019-06-20', 'maintenanceUntil': '2023-06-30'}
      },
      {
        'building': 'A',
        'floor': 3,
        'capacity': 35,
        'rating': 4.6,
        'isAvailable': true,
        'features': ['Projector', 'Smart Board', 'Air Conditioning', 'Ergonomic Furniture'],
        'imageUrl': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Computer Lab', 'lastRenovation': '2022-09-05'}
      },
      {
        'building': 'B',
        'floor': 2,
        'capacity': 45,
        'rating': 4.3,
        'isAvailable': true,
        'features': ['Projector', 'Whiteboard', 'Air Conditioning', 'Adjustable Lighting'],
        'imageUrl': 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'metadata': {'roomType': 'Lecture', 'lastRenovation': '2021-11-18'}
      },
    ];
    
    // Add each room to the collection
    for (var roomData in roomsData) {
      await roomsCollection.add(roomData);
    }
    
    print('Rooms collection initialized with ${roomsData.length} documents');
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

  // Create sample bookings (only if a user exists)
  Future<void> _createSampleBookings() async {
    final CollectionReference bookingsCollection = _firestore.collection('bookings');
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      print('No user signed in, skipping sample bookings');
      return;
    }
    
    // Check if bookings already exist for this user
    final QuerySnapshot existingBookings = await bookingsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();
        
    if (existingBookings.docs.isNotEmpty) {
      print('Bookings already exist for current user');
      return;
    }
    
    // Get room IDs to reference in bookings
    final QuerySnapshot roomSnapshot = await _firestore.collection('rooms').limit(5).get();
    if (roomSnapshot.docs.isEmpty) {
      print('No rooms available for creating sample bookings');
      return;
    }
    
    List<String> roomIds = roomSnapshot.docs.map((doc) => doc.id).toList();
    
    // Create dates for bookings
    final DateTime now = DateTime.now();
    final String today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    final String yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    
    final DateTime lastWeek = now.subtract(const Duration(days: 7));
    final String lastWeekStr = '${lastWeek.year}-${lastWeek.month.toString().padLeft(2, '0')}-${lastWeek.day.toString().padLeft(2, '0')}';
    
    final DateTime nextWeek = now.add(const Duration(days: 7));
    final String nextWeekStr = '${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';
    
    final DateTime tomorrow = now.add(const Duration(days: 1));
    final String tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    
    final List<Map<String, dynamic>> bookingsData = [
      {
        'roomId': roomIds[0],
        'userId': currentUser.uid,
        'date': lastWeekStr,
        'time': '10:00 - 12:00',
        'purpose': 'Study Group Meeting',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(lastWeek),
        'rating': 4.5,
        'feedback': 'Room was clean and well-equipped.'
      },
      {
        'roomId': roomIds[1],
        'userId': currentUser.uid,
        'date': yesterdayStr,
        'time': '14:00 - 16:00',
        'purpose': 'Team Project Discussion',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(yesterday.subtract(const Duration(days: 2))),
        'rating': 4.0,
        'feedback': 'Projector was a bit dim, but overall good experience.'
      },
      {
        'roomId': roomIds[2],
        'userId': currentUser.uid,
        'date': today,
        'time': '16:00 - 18:00',
        'purpose': 'Research Meeting',
        'status': 'upcoming',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'roomId': roomIds[3],
        'userId': currentUser.uid,
        'date': tomorrowStr,
        'time': '09:00 - 11:00',
        'purpose': 'Exam Preparation',
        'status': 'upcoming',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'roomId': roomIds[4],
        'userId': currentUser.uid,
        'date': nextWeekStr,
        'time': '13:00 - 15:00',
        'purpose': 'Group Presentation Practice',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      },
    ];
    
    // Add each booking to the collection
    for (var bookingData in bookingsData) {
      await bookingsCollection.add(bookingData);
    }
    
    print('Sample bookings initialized with ${bookingsData.length} documents');
  }

  // Create sample ratings
  Future<void> _createSampleRatings() async {
    final CollectionReference ratingsCollection = _firestore.collection('ratings');
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      print('No user signed in, skipping sample ratings');
      return;
    }
    
    // Check if ratings already exist for this user
    final QuerySnapshot existingRatings = await ratingsCollection
        .where('userId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();
        
    if (existingRatings.docs.isNotEmpty) {
      print('Ratings already exist for current user');
      return;
    }
    
    // Get room IDs and booking IDs to reference in ratings
    final QuerySnapshot roomSnapshot = await _firestore.collection('rooms').limit(5).get();
    final QuerySnapshot bookingSnapshot = await _firestore.collection('bookings')
        .where('userId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'completed')
        .get();
        
    if (roomSnapshot.docs.isEmpty || bookingSnapshot.docs.isEmpty) {
      print('No rooms or completed bookings available for creating sample ratings');
      return;
    }
    
    List<String> roomIds = roomSnapshot.docs.map((doc) => doc.id).toList();
    List<String> bookingIds = bookingSnapshot.docs.map((doc) => doc.id).toList();
    
    // Create some sample ratings
    final List<Map<String, dynamic>> ratingsData = [];
    
    // Only add as many ratings as we have completed bookings
    final int ratingsCount = bookingIds.length;
    
    for (int i = 0; i < ratingsCount; i++) {
      ratingsData.add({
        'bookingId': bookingIds[i],
        'roomId': roomIds[i % roomIds.length],
        'userId': currentUser.uid,
        'rating': 4.0 + (i % 2) * 0.5, // Alternating between 4.0 and 4.5
        'comment': 'Good experience overall. ${i % 2 == 0 ? 'The room was clean and well-equipped.' : 'The facilities worked great.'}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Add each rating to the collection
    for (var ratingData in ratingsData) {
      await ratingsCollection.add(ratingData);
    }
    
    print('Sample ratings initialized with ${ratingsData.length} documents');
  }
} 