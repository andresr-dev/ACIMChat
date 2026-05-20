ACIM Chat

An AI-powered chat application focused on studying and exploring the teachings of A Course in Miracles (ACIM).
Built with SwiftUI and The Composable Architecture (TCA) for a modern, scalable, and maintainable iOS architecture.

⸻

✨ Features

* 💬 Create multiple chats
* 🗑️ Delete conversations
* 🤖 Ask questions about A Course in Miracles
* 📚 AI-powered responses focused on the ACIM teachings
* ⚡ Built with a reactive and modular architecture using TCA
* 🎨 Modern SwiftUI interface

⸻

🛠️ Tech Stack

* Swift
* SwiftUI
* The Composable Architecture (TCA)
* OpenAI API (or your AI provider if different)

📱 Demo

https://github.com/user-attachments/assets/0cca8b05-22d8-4f67-8994-1e34001ec950

🧱 Architecture

The app follows a unidirectional data flow architecture using
The Composable Architecture (TCA).

Main benefits:

* Predictable state management
* Testable business logic
* Modular feature organization
* Scalable navigation and side effects handling

⸻

💾 Persistence

ACIM Chat uses the native FileManager system for local persistence.
All conversations are stored locally on the device, allowing chats to remain available between app launches without requiring a database setup.

Benefits of this approach:

* Lightweight and fast
* Offline-friendly
* Simple and maintainable storage layer
* Seamless chat restoration

⸻

☁️ Xcode Cloud CI/CD

The project is configured with Xcode Cloud for continuous integration and deployment.

Automated Workflow

Every merge into the main branch automatically:

1. Runs the test suite
2. Builds the application
3. Generates a new TestFlight build

This setup helps ensure code quality, faster delivery, and a streamlined release process.
