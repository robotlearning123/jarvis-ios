# JARVIS iOS

<div align="center">

**A Native iOS AI Assistant with Real-time Voice Conversation**

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0+-lightgrey.svg)](https://www.apple.com/ios)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Development](#-development)

</div>

---

## 📱 Features

- **🎤 Real-time Voice Conversations** - Natural voice interaction using OpenAI Realtime API
- **💬 Speech Recognition** - Native iOS speech-to-text with live transcription
- **🎨 Beautiful SwiftUI Interface** - Modern, native iOS design with dark mode
- **📊 Data Management** - SwiftData integration for local storage
- **🔐 Secure API Key Storage** - Encrypted storage in UserDefaults
- **⚡ Async/Await** - Modern Swift concurrency for smooth performance

## 🚀 Quick Start

### Prerequisites

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **macOS 13.0+** for development
- **OpenAI API Key** (get one at [platform.openai.com](https://platform.openai.com))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/robotlearning123/jarvis-ios.git
   cd jarvis-ios
   ```

2. **Open in Xcode**
   ```bash
   open Jarvis.xcodeproj
   ```

3. **Configure signing**
   - Select the `Jarvis` target
   - Go to "Signing & Capabilities"
   - Select your development team

4. **Build and run**
   - Select a simulator or device
   - Press `⌘ + R` or click the Run button

### First Launch Setup

1. On first launch, tap the key icon in the top right
2. Enter your OpenAI API key
3. Tap "Save"
4. Allow microphone access when prompted
5. Tap the blue voice button to start talking!

## 💻 Usage

### Voice Conversation

1. **Start Recording** - Tap the blue voice button
2. **Speak** - Your speech is transcribed in real-time
3. **Stop Recording** - Tap the red stop button
4. **Get Response** - JARVIS responds via the Realtime API

### API Key Management

- Tap the key icon to update your API key anytime
- Keys are stored securely in UserDefaults
- Leave empty to disable voice features

## 🏗️ Architecture

### Project Structure

```
Jarvis/
├── JarvisApp.swift              # App entry point
├── ContentView.swift            # Main view with voice UI
├── Models/                      # Data models
│   ├── Item.swift              # Generic item model
│   └── User.swift              # User data model
├── Views/                       # SwiftUI views
│   ├── HomeView.swift          # Home dashboard
│   ├── ProfileView.swift       # User profile
│   └── SettingsView.swift      # App settings
└── Services/                    # Business logic
    ├── AIService.swift         # AI/chat service
    ├── RealtimeService.swift   # OpenAI Realtime API
    └── VoiceService.swift      # Speech recognition
```

### Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data**: SwiftData
- **Networking**: URLSession with async/await
- **Voice**: AVFoundation + Speech framework
- **AI**: OpenAI Realtime API (WebSocket)

### Key Components

#### RealtimeService
Handles WebSocket connection to OpenAI's Realtime API:
- Real-time audio streaming
- Session management
- Event handling
- Error recovery

#### VoiceService
Manages speech recognition:
- Microphone input
- Speech-to-text conversion
- Permission handling
- Audio session management

#### ContentView
Main UI with:
- Voice button with visual feedback
- Message history display
- Connection status indicator
- API key configuration

## 🛠️ Development

### Building from Source

```bash
# Clean build
xcodebuild clean -project Jarvis.xcodeproj -scheme Jarvis

# Build
xcodebuild build -project Jarvis.xcodeproj -scheme Jarvis

# Run tests
xcodebuild test -project Jarvis.xcodeproj -scheme Jarvis \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Adding Features

1. **New View**: Add to `Views/` directory
2. **New Model**: Add to `Models/` directory
3. **New Service**: Add to `Services/` directory
4. Follow MVVM pattern

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines.

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint/SwiftFormat (if configured)
- Prefer `async/await` over completion handlers
- Use `@Observable` for ViewModels (Swift 5.9+)

### Testing

```bash
# Run unit tests
⌘ + U (in Xcode)

# Or via command line
xcodebuild test -project Jarvis.xcodeproj -scheme Jarvis
```

## 📋 Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- OpenAI API key with Realtime API access

## 🔐 Privacy & Security

- API keys stored locally in UserDefaults
- No data sent to third parties except OpenAI
- Microphone access only when recording
- No persistent storage of conversations (currently)

### Permissions Required

- **Microphone**: For voice input
- **Speech Recognition**: For transcription

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for the Realtime API
- Apple for SwiftUI and native frameworks
- The iOS development community

## 📧 Contact

Project Link: [https://github.com/robotlearning123/jarvis-ios](https://github.com/robotlearning123/jarvis-ios)

---

<div align="center">

**Built with ❤️ using Swift and SwiftUI**

</div>
