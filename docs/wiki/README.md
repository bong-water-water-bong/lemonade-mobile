# Project Wiki: Lemonade Mobile

## Mission
To provide a polished, multi-platform chat interface for Lemonade AI servers, featuring real-time streaming, syntax highlighting, and persistent conversation management.

## Architecture
- **Language**: Dart (>=3.8.1)
- **Framework**: Flutter with Material Design 3.
- **State Management**: Riverpod for clean, reactive architecture.
- **Core Components**:
  - **Chat Engine**: Streaming responses with `dart_openai` and custom Markdown/Syntax highlighting.
  - **Server Management**: Multi-server configuration with connectivity testing.
  - **Persistence**: `isar_community` for high-performance local storage of chat history and `flutter_secure_storage` for sensitive data.
  - **Media & Audio**: Integrated image picking, audio recording (with Silero VAD), and playback.
- **Layout**:
  - `lib/providers/`: State management and logic.
  - `lib/screens/`: Main UI entry points (Chat, Settings).
  - `lib/services/`: API and external integration wrappers.
  - `lib/widgets/`: Reusable UI components.

## Agent Handoff
- **Testing**: Run `flutter test`.
- **Linting**: Use `flutter analyze`.
- **Dependencies**: Use `flutter pub get` to fetch packages.
- **Build Runner**: Some components (like Isar) require `dart run build_runner build` for code generation.
- **Priorities**: Ensure smooth UI performance, reliable streaming, and robust local persistence.

## Decisions & Gotchas
- **Isar Community**: Using `isar_community` instead of the original `isar` to ensure compatibility with 16KB page-size requirements (Android 15+).
- **Offline-First Persistence**: Chat history is stored locally to ensure availability without server connection.
- **OpenAI Compatibility**: Designed to work with any OpenAI-compatible endpoint, not just official Lemonade servers.
