# 🌊 Aqualyze - Smart Water Quality Monitoring

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?style=flat&logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat&logo=android)](https://developer.android.com)

A cutting-edge Flutter mobile application designed for IoT-based water quality monitoring in aquaculture environments, specifically optimized for crab farming operations.

## 🚀 Features

### 📊 Real-Time Monitoring
- **Multi-Sensor Support**: Monitor pH, temperature, dissolved oxygen, and turbidity
- **Live Data Sync**: Real-time data synchronization from IoT sensors via Firebase
- **Offline Capability**: Access cached data when internet connection is unavailable
- **Location-Based Monitoring**: Support for multiple monitoring locations (Semarang & Malang)

### 🤖 AI-Powered Predictions
- **Machine Learning Integration**: AI predictions for next sensor readings
- **Confidence Scoring**: Model reliability indicators for each prediction
- **Trend Analysis**: Historical data analysis for better decision making

### 📈 Advanced Analytics
- **Interactive Charts**: Professional charts powered by Syncfusion
- **Time-Based Filtering**: Daily, weekly, monthly, and yearly data views
- **Status Indicators**: Color-coded alerts for optimal/warning/critical conditions
- **Data Export**: Export capabilities for further analysis

### 🔐 Secure Authentication
- **Google Sign-In**: Seamless authentication with Google OAuth
- **User Profiles**: Personal settings and location preferences
- **Data Privacy**: Secure user data management with Firebase Auth

### 🎨 Modern UI/UX
- **Material Design 3**: Modern, intuitive interface design
- **Smooth Animations**: Polished user experience with custom animations
- **Responsive Design**: Optimized for various screen sizes
- **Dark/Light Theme Ready**: Theme system prepared for future expansion

## 🏗️ Architecture

### Clean Architecture Pattern
```
lib/
├── core/                  # Core utilities and constants
│   ├── constants/         # App constants, colors, strings
│   ├── theme/             # Theme configuration
│   ├── utils/             # Helper functions and extensions
│   └── network/           # Connectivity services
├── data/
│   ├── models/            # Data models (Hive & Firestore)
│   ├── providers/         # Riverpod state providers
│   ├── repositories/      # Data access layer
│   └── services/          # External service integrations
└── presentation/
    ├── pages/             # Screen implementations
    ├── widgets/           # Reusable UI components
    └── animations/        # Custom animations
```

### Technology Stack
- **Frontend**: Flutter 3.16+ with Material Design 3
- **State Management**: Riverpod for reactive state management
- **Backend**: Firebase (Firestore, Authentication)
- **Local Storage**: Hive for offline data persistence
- **Charts**: Syncfusion Flutter Charts
- **ML Integration**: Custom prediction API service
- **Connectivity**: Real-time connection monitoring

## 📱 Pages

### Home Dashboard
- Real-time sensor readings with status indicators
- AI predictions for next measurements
- Location switching and overall condition monitoring

### Analytics Dashboard
- Interactive charts for each sensor type
- Time-based filtering and trend analysis
- Statistical summaries and performance metrics

### Authentication & Profile
- Google Sign-In integration
- User profile management
- Location preferences and settings

## 🛠️ Installation

### Prerequisites
- **Flutter SDK**: 3.16 or higher
- **Dart SDK**: 3.1.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Project** with Firestore and Authentication enabled

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/jeremyseans/Aqualyze-App.git
   cd Aqualyze-App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Firebase Configuration**
   - Create a new Firebase project
   - Enable Firestore Database and Authentication
   - Add your `google-services.json` to `android/app/`
   - Update `lib/firebase_options.dart` with your config

5. **Run the application**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Firebase Setup
1. **Firestore Collections**:
   ```
   water_quality/          # Main Semarang data
   water_quality_malang/   # Malang location data
   users/                  # User preferences and profiles
   ```

2. **Security Rules** (Basic example):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /water_quality/{document} {
         allow read: if request.auth != null;
       }
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Environment Variables
Create a `.env` file in the root directory:
```env
ML_API_BASE_URL=https://aqualyze-predict.up.railway.app/
```

## 🔧 Development

### Code Generation
```bash
# Generate Hive type adapters
flutter packages pub run build_runner build

# Watch for changes during development
flutter packages pub run build_runner watch
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Build for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## 📊 Data Flow

### Real-Time Sync Process
1. **IoT Sensors** → Firebase Firestore (real-time)
2. **Firestore** → App via Stream listeners
3. **Local Storage** (Hive) for offline access
4. **Smart Sync**: Only fetch new data since last sync

### AI Prediction Workflow
1. Collect last 5 sensor readings
2. Send to ML API for prediction
3. Display results with confidence indicators
4. Cache predictions for offline viewing

## 🎯 Sensor Specifications

### Optimal Ranges (Crab Farming)
- **Temperature**: 26-31°C
- **pH Level**: 6.5-7.5
- **Dissolved Oxygen**: >4.0 mg/L
- **Turbidity**: 300-700 NTU

### Status Indicators
- 🟢 **Excellent**: All parameters optimal
- 🔵 **Good**: Within acceptable ranges
- 🟡 **Warning**: Some parameters need attention
- 🔴 **Critical**: Immediate action required

## 🚀 Future Enhancements

### Planned Features
- [ ] **Push Notifications**: Real-time alerts for critical conditions
- [ ] **Multi-Language Support**: Indonesian and English localization
- [ ] **Data Export**: CSV/PDF report generation
- [ ] **Advanced ML Models**: Enhanced prediction accuracy
- [ ] **IoT Device Management**: Direct sensor configuration
- [ ] **Team Collaboration**: Multi-user access and sharing

### Technical Improvements
- [ ] **Dark Theme**: Complete dark mode implementation
- [ ] **Web Platform**: Progressive Web App support
- [ ] **iOS Support**: Cross-platform expansion
- [ ] **Advanced Analytics**: Machine learning insights
- [ ] **Offline ML**: Local prediction models

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure code passes all checks

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Lead Developer**: Jeremy Sean Sitranata
- **UI/UX Designer**: Jeremy Sean Sitranata
- **ML Engineer**: Jeremy Sean Sitranata
- **IoT Specialist**: Justo Gregorius Channing Teng

## 📞 Support

For support and questions:
- **Email**: jremysie@gmail.com
- **Issues**: [GitHub Issues](https://github.com/jeremyseans/aqualyze/issues)

---

<div align="center">
  <p>Made with ❤️ for sustainable aquaculture</p>
  <p><strong>Aqualyze</strong> - Empowering Smart Water Management</p>
</div>