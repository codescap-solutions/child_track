# NAVIQ - Flutter MVVM Architecture

## 🏗️ Architecture Overview

This Flutter project follows **MVVM (Model-View-ViewModel)** architecture pattern with **BLoC** for state management, providing a clean, scalable, and maintainable codebase.

## 📁 Project Structure

```
lib/
├── src/
│   ├── core/                    # Core functionality and configurations
│   │   ├── constants/           # App constants (colors, text styles, strings, sizes)
│   │   ├── theme/              # App theming
│   │   ├── utils/              # Utility classes (snackbar, logger)
│   │   ├── navigation/         # Navigation and routing
│   │   ├── services/           # Core services (Dio, SharedPreferences, API)
│   │   └── di/                 # Dependency injection setup
│   │
│   ├── data/                   # Data layer
│   │   ├── models/             # Data models
│   │   └── repositories/       # Data repositories
│   │
│   ├── domain/                 # Domain layer (Business logic)
│   │   └── usecases/           # Use cases (Business rules)
│   │
│   └── presentation/           # Presentation layer
│       ├── blocs/              # BLoC state management
│       ├── views/              # UI screens
│       └── widgets/            # Reusable UI components
│
└── main.dart                   # App entry point
```

## 🧩 Key Components

### Core Layer

- **Constants**: Centralized app constants for colors, text styles, strings, and sizes
- **Theme**: Material Design 3 theme with custom styling
- **Utils**: Common utilities like snackbar and logger
- **Navigation**: Route management and navigation
- **Services**: Core services for API, storage, and networking
- **DI**: Dependency injection using GetIt

### Data Layer

- **Models**: Data transfer objects and response models
- **Repositories**: Data access layer implementing repository pattern

### Domain Layer

- **Use Cases**: Business logic and rules implementation

### Presentation Layer

- **BLoC**: State management using flutter_bloc
- **Views**: UI screens and pages
- **Widgets**: Reusable UI components

## 🚀 Features Implemented

### ✅ Authentication Flow

- **Login Screen**: Phone number input with validation
- **OTP Screen**: OTP verification with resend functionality
- **Home Screen**: Dashboard with quick actions and stats

### ✅ Core Services

- **Dio Client**: HTTP client with interceptors and error handling
- **SharedPreferences**: Local storage for user data and tokens
- **Base Service**: Abstract service class for API operations
- **Logger**: Centralized logging system

### ✅ State Management

- **Auth BLoC**: Authentication state management
- **Events**: User actions and triggers
- **States**: UI state representations

### ✅ UI Components

- **Common Button**: Reusable button with loading states
- **Common TextField**: Input field with validation
- **App Snackbar**: Toast notifications
- **Theme**: Consistent Material Design 3 theming

## 🛠️ Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6 # State management
  equatable: ^2.0.5 # Value equality
  get_it: ^7.6.4 # Dependency injection
  dio: ^5.4.2 # HTTP client
  shared_preferences: ^2.2.3 # Local storage
  google_fonts: ^6.2.1 # Custom fonts
  logger: ^2.2.0 # Logging
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd child_track
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Flow

1. **Splash Screen**: Shows app logo and checks authentication status
2. **Login Screen**: User enters phone number
3. **OTP Screen**: User verifies OTP code
4. **Home Screen**: Dashboard with app features

## 🔧 Configuration

### API Configuration

Update `lib/src/core/services/api_endpoints.dart` with your API endpoints:

```dart
class ApiEndpoints {
  static const String baseUrl = 'https://your-api.com/v1';
  // ... other endpoints
}
```

### Theme Customization

Modify `lib/src/core/constants/app_colors.dart` and `app_text_styles.dart` to customize the app's appearance.

## 🧪 Testing

Run tests using:

```bash
flutter test
```

## 📦 Building

### Debug Build

```bash
flutter build apk --debug
```

### Release Build

```bash
flutter build apk --release
```

## 🏗️ Architecture Benefits

- **Separation of Concerns**: Clear separation between UI, business logic, and data
- **Testability**: Easy to unit test each layer independently
- **Maintainability**: Clean code structure makes maintenance easier
- **Scalability**: Easy to add new features and modules
- **Reusability**: Common components can be reused across the app

## 🔄 State Management Flow

1. **User Action** → **Event** → **BLoC**
2. **BLoC** → **Use Case** → **Repository**
3. **Repository** → **API/Storage** → **Response**
4. **Response** → **State** → **UI Update**

## 📝 Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Use const constructors where possible

## 🚀 Next Steps

This base architecture provides a solid foundation for building the NAVIQ app. You can now:

1. Add more screens and features
2. Implement real API endpoints
3. Add more BLoCs for different features
4. Enhance UI components
5. Add more validation and error handling
6. Implement push notifications
7. Add location tracking features
8. Implement child management features

## 📞 Support

For questions or issues, please refer to the Flutter documentation or create an issue in the repository.
