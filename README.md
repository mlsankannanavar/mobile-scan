# BatchMate Scanner - Mobile App

A Flutter mobile application for pharmaceutical batch scanning with OCR capabilities and local batch matching.

## Features

- 📱 **Mobile-First OCR**: Local text recognition using ML Kit
- 🔍 **Intelligent Batch Matching**: Fuzzy matching algorithms for accurate batch identification
- 📊 **Real-time Validation**: Instant feedback on batch scan results
- 🔗 **Server Integration**: Seamless communication with backend services
- 📸 **QR Code Scanner**: Quick batch identification via QR codes
- 💾 **Local Storage**: Offline capability with SQLite database
- 🎨 **Material Design 3**: Modern, intuitive user interface

## Architecture

### Mobile-First Design
- **Local OCR Processing**: ML Kit handles text recognition on-device
- **Intelligent Matching**: Advanced algorithms for batch identification
- **Offline Capability**: Works without constant internet connection
- **Real-time Feedback**: Instant validation and suggestions

### Technology Stack
- **Flutter**: Cross-platform mobile development
- **ML Kit**: Google's machine learning SDK for OCR
- **SQLite**: Local database for offline storage
- **Riverpod**: State management
- **Freezed**: Immutable data classes

## Getting Started

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Android Studio / VS Code
- Android SDK (API level 21+)
- Camera permissions for scanning

### Installation

1. Clone the repository:
```bash
git clone https://github.com/mlsankannanavar/batchscan.git
cd batchscan
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building APK

The repository includes GitHub Actions workflow for automatic APK building:

### Automatic Builds
- **On Push**: Builds debug APK on every push to main branch
- **On Release**: Creates signed release APK and AAB files
- **Artifacts**: Downloadable APK files available in GitHub Actions

### Manual Build
```bash
flutter build apk --release
flutter build appbundle --release
```

## Configuration

### Server Connection
Configure your backend server URL in `lib/utils/constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'your-server-url';
  // ... other configurations
}
```

### Permissions
The app requires camera permissions for scanning functionality. These are automatically requested on first use.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── api_response.dart
│   ├── batch_info.dart
│   ├── match_result.dart
│   └── session_data.dart
├── screens/                  # UI screens
│   ├── connection_screen.dart
│   └── qr_scanner_screen.dart
├── services/                 # Business logic
│   ├── backend_service.dart
│   ├── batch_matcher.dart
│   ├── local_storage_service.dart
│   └── ocr_service.dart
├── utils/                    # Utilities
│   ├── constants.dart
│   └── logger.dart
└── widgets/                  # Reusable UI components
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions, please open an issue in the GitHub repository.

---

**BatchMate Scanner** - Transforming pharmaceutical batch verification through mobile technology.
