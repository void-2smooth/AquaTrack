<p align="center">
  <img src="https://img.icons8.com/fluency/96/water.png" alt="AquaTrack Logo" width="96" height="96">
</p>

<h1 align="center">AquaTrack 💧</h1>

<p align="center">
  <strong>A beautiful, feature-rich daily water intake tracker built with Flutter</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#project-structure">Structure</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Riverpod-2.4+-00D4AA?style=for-the-badge" alt="Riverpod">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey?style=for-the-badge" alt="Platform">
</p>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 **Custom Goals** | Set daily water intake goals in Liters or Ounces |
| ⚡ **Quick Add** | One-tap buttons for common amounts (100ml, 250ml, 500ml, 1L) |
| 📊 **Visual Progress** | Beautiful circular progress bar with real-time updates |
| 💬 **Motivational Messages** | Dynamic encouragement based on your progress |
| 🔥 **Streak Tracking** | Track consecutive days of meeting your hydration goals |
| 📅 **History View** | Browse past daily records with detailed summaries |
| 🔔 **Smart Reminders** | Optional notifications to keep you hydrated |
| 🌙 **Dark Mode** | Easy-on-the-eyes dark theme option |
| 📱 **Cross-Platform** | Works on iOS, Android, and Web |

## 📱 Screenshots

<p align="center">
  <i>Screenshots coming soon...</i>
</p>

<!-- Add your screenshots here
<p align="center">
  <img src="screenshots/home_light.png" width="200" alt="Home Screen">
  <img src="screenshots/home_dark.png" width="200" alt="Home Screen Dark">
  <img src="screenshots/history.png" width="200" alt="History Screen">
  <img src="screenshots/settings.png" width="200" alt="Settings Screen">
</p>
-->

## check feature md for features to  Contribute

## 🚀 Installation

### Prerequisites

- Flutter SDK 3.0 or higher
- Dart 3.0 or higher

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/aquatrack.git

# Navigate to project directory
cd aquatrack

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Platform-Specific Setup

<details>
<summary><b>📱 Android</b></summary>

No additional setup required. Just run:
```bash
flutter run -d android
```

For notifications on Android 13+, the app will request permission at runtime.

</details>

<details>
<summary><b>🍎 iOS</b></summary>

```bash
cd ios
pod install
cd ..
flutter run -d ios
```

Add to `ios/Runner/Info.plist` for notifications:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

</details>

<details>
<summary><b>🌐 Web</b></summary>

```bash
flutter run -d chrome
```

> Note: Push notifications are not supported on web platform.

</details>

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Riverpod** | State management |
| **Hive** | Local database storage |
| **flutter_local_notifications** | Push notifications |
| **percent_indicator** | Circular progress visualization |

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point & theme config
│
├── models/
│   ├── water_entry.dart           # Data models
│   └── water_entry.g.dart         # Hive type adapters
│
├── providers/
│   └── providers.dart             # Riverpod state management
│
├── screens/
│   ├── home_screen.dart           # Main dashboard
│   ├── history_screen.dart        # Historical data view
│   └── settings_screen.dart       # App preferences
│
├── services/
│   ├── storage_service.dart       # Hive operations
│   └── notification_service.dart  # Notification handling
│
└── widgets/
    ├── progress_bar.dart          # Circular progress widget
    ├── water_add_buttons.dart     # Quick-add buttons
    └── motivational_message.dart  # Dynamic messages
```

## 🎨 Customization

### Change Theme Colors

Edit the `colorScheme` in `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF0EA5E9), // Your color here
  brightness: Brightness.light,
),
```

### Add Quick-Add Amounts

Edit `quickAddAmountsProvider` in `lib/providers/providers.dart`:

```dart
QuickAddAmount(label: '750ml', amountMl: 750),
```

### Customize Motivational Messages

Edit `motivationalMessageProvider` in `lib/providers/providers.dart` to add your own messages.

## 📖 Documentation

For detailed documentation, see [DOCUMENTATION.md](DOCUMENTATION.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - Beautiful native apps in record time
- [Riverpod](https://riverpod.dev/) - A simple way to access state
- [Hive](https://docs.hivedb.dev/) - Lightweight and blazing fast key-value database

---

<p align="center">
  Made with 💙 for hydration enthusiasts
</p>

<p align="center">
  <a href="https://github.com/yourusername/aquatrack/stargazers">⭐ Star this repo</a> if you find it helpful!
</p>
