# EaseClass - Classroom Booking System

EaseClass is a modern classroom booking system designed to streamline the process of booking and managing classrooms in educational institutions. The app provides separate interfaces for students and administrators, making it easy to manage classroom bookings efficiently.

## Features

### For Students
- **Classroom Booking**
  - Browse available classrooms
  - View detailed classroom information (capacity, features, location)
  - Book classrooms for specific dates and times
  - Specify booking purpose and duration
  - Request additional items/notes for the booking

- **Booking Management**
  - View all bookings (pending, approved, completed, cancelled)
  - Track booking status in real-time
  - Cancel bookings when needed
  - Mark bookings as completed after use
  - Rate and provide feedback for completed bookings

- **Notifications**
  - Real-time notifications for booking status updates
  - Customizable notification preferences
  - Push notifications for important updates
  - Mark notifications as read

- **User Profile**
  - View and update personal information
  - Manage notification preferences
  - View booking history
  - Track booking statistics

### For Administrators
- **Dashboard**
  - Overview of total users, classrooms, and bookings
  - View pending booking requests
  - Monitor top booked classrooms
  - Track recent reviews and ratings

- **Booking Management**
  - Approve or reject booking requests
  - Provide reasons for rejections
  - View all bookings across the system
  - Monitor booking statuses
  - Access detailed booking information

- **Classroom Management**
  - Add and manage classrooms
  - Update classroom details (capacity, features, location)
  - Track classroom usage statistics
  - Manage classroom availability

- **User Management**
  - View and manage user accounts
  - Monitor user activity
  - Handle user-related issues

- **Content Management**
  - Manage FAQs
  - Update system announcements
  - Handle content-related tasks

## Technical Features
- **Authentication**
  - Secure user authentication
  - Role-based access control (Student/Admin)
  - Email-based login system

- **Real-time Updates**
  - Live booking status updates
  - Instant notifications
  - Real-time data synchronization

- **Data Management**
  - Cloud-based storage using Firebase
  - Secure data handling
  - Efficient data querying and filtering

- **User Interface**
  - Modern and intuitive design
  - Responsive layout
  - Easy navigation
  - Dark mode support

## Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Firebase account
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/EaseClass.git
   ```

2. Navigate to the project directory:
   ```bash
   cd EaseClass
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Firebase:
   - Create a new Firebase project
   - Add your Android/iOS app to the Firebase project
   - Download and add the configuration files
   - Enable Authentication and Firestore

5. Run the app:
   ```bash
   flutter run
   ```

## Building the App

### For Android
```bash
flutter build apk --release
```
The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### For iOS
```bash
flutter build ios --release
```

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Support
For support, please open an issue in the GitHub repository or contact the development team.

## Acknowledgments
- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who have helped in the development
