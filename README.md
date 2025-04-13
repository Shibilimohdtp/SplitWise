# SplitWise App

A modern, feature-rich expense splitting application built with Flutter and Firebase. This app helps users manage shared expenses within groups, track balances, and settle debts efficiently.

## Features

- **User Authentication**: Secure sign-up and login functionality using Firebase Authentication.
- **Group Management**: Create, join, and manage expense groups with friends.
- **Expense Tracking**: Add, edit, and delete expenses within groups.
- **Smart Expense Splitting**: Automatically calculate and split expenses among group members.
- **Balance Calculation**: Real-time balance calculations for each user within groups.
- **Offline Support**: Local database storage for offline expense entry and syncing.
- **Currency Conversion**: Support for multiple currencies with automatic conversion.
- **Notifications**: Real-time notifications for new expenses and group invitations.
- **Receipt Management**: Upload and store receipt images for expenses.
- **User Profiles**: Customizable user profiles with profile picture support.
- **Dark Mode**: Toggle between light and dark themes for comfortable usage.

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase (Firestore, Authentication, Cloud Storage)
- **State Management**: Provider
- **Local Database**: SQLite (via sqflite package)
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Image Handling**: Firebase Storage

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account and project set up
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/your-username/SplitWise.git
   ```

2. Navigate to the project directory:
   ```
   cd splitwise-app
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Set up Firebase:
   - Create a new Firebase project
   - Add your Android and iOS apps to the Firebase project
   - Download and place the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) in the respective directories

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/`
  - `models/`: Data models (User, Expense, Group, etc.)
  - `services/`: Firebase and local service implementations
  - `screens/`: UI screens
  - `widgets/`: Reusable UI components
  - `utils/`: Utility functions and constants

## Key Services

- `AuthService`: Handles user authentication and profile management
- `ExpenseService`: Manages expense-related operations
- `GroupService`: Handles group creation and management
- `NotificationService`: Manages push notifications
- `UserService`: User-related operations and profile management
- `SettingsService`: Manages app settings like currency and theme

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Firebase for providing a robust backend solution
- Flutter team for an excellent cross-platform framework
