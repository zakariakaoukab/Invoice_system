#  Invoice system

*A unified cross-platform Point of Sale, Inventory Management, and AI-powered Analytics system designed to streamline business operations and generate localized professional invoices.*

---

## 🏗 System Architecture & Tech Stack

*   **Frontend Framework:** Flutter (Cross-platform: Windows, macOS, Web, Android, iOS)
*   **State Management & Routing:** Riverpod (`flutter_riverpod`) & GoRouter (`go_router`)
*   **Backend & Database:** Firebase Suite (Firebase Auth, Cloud Firestore, Firebase Storage)
*   **AI Integration:** Google Generative AI (Gemini 2.5 Flash) via `google_generative_ai`
*   **Document Generation:** `pdf` and `printing` packages (custom Cairo font injected for multi-language support)
*   **Data Visualization:** `fl_chart` for responsive analytics dashboards

## ⚙️ Core Features

*   **Context-Aware AI Business Assistant:** Integrates Gemini 2.5 Flash to act as a localized AI assistant. It continuously ingests a live JSON snapshot of current inventory and recent sales, allowing users to query their business data in Arabic, French, or English without SQL knowledge.
*   **Platform-Agnostic PDF Generation Pipeline:** A robust, zero-crash PDF engine that generates fully localized, Right-to-Left (RTL) compliant invoices (with French & Arabic text), complete with pre-cached heavy assets (TTF fonts, image logos) for instantaneous rendering.
*   **Reactive Role-Based Access Control (RBAC):** Dynamic, declarative routing mechanism that intercepts navigation at the router level. Ensures robust security by gating the Dashboard, Reporting, and User Management modules behind an Admin firewall, while funneling cashiers directly to the POS interface.
*   **Unified Multi-Platform Support:** A single Dart codebase compiled to desktop executables for back-office administration and web/mobile platforms for flexible point-of-sale operations.

## 🧠 Technical Challenges & Trade-offs

### 1. Desktop PDF Generation & Native Printing Crashes
*   **The Problem:** The standard `printing` package relies on native plugins that can occasionally trigger a fatal `abort()` exception on Windows/macOS if no default system printer is configured, abruptly crashing the entire Flutter desktop application during invoice generation.
*   **The Solution:** Engineered a platform-aware PDF handler. For mobile and web, it defaults to the standard print-preview share sheet. For desktop platforms, it entirely bypasses the native printing plugin by generating the raw PDF bytes in-memory, saving them to `Directory.systemTemp`, and executing an OS-level shell command (`cmd /c start`, `open`, or `xdg-open`) to safely trigger the operating system's native PDF viewer.

### 2. Injecting Live Database Context into Generative AI
*   **The Problem:** To make the Gemini AI assistant genuinely useful, it required real-time knowledge of stock levels and recent sales. However, feeding thousands of raw Firestore documents directly into a prompt is highly inefficient, exceeds token limits, and causes severe latency.
*   **The Solution:** Built a highly-optimized context hydration pipeline in `AiService`. It queries the current product states and only the last 100 recent orders, serializes this critical snapshot into a minimized JSON payload, and injects it as system context behind the scenes. This gives the model the exact context it needs to provide accurate business insights without hallucinating.

### 3. State-Driven Role-Based Routing
*   **The Problem:** Securing application routes (Admin Dashboard vs. Cashier POS) based on asynchronous Firestore user profile data, while ensuring a smooth initial load sequence (Splash -> Setup Wizard -> Login -> App) without causing UI flickering or infinite redirect loops.
*   **The Solution:** Implemented a reactive `GoRouter` instance tightly coupled with Riverpod providers. The router actively listens to three asynchronous streams: `firebaseAuthStateProvider`, `hasAdminUserProvider`, and `currentAppUserProvider`. The `redirect` callback acts as a pure, synchronous state machine, evaluating the combined resolution of these asynchronous states to guarantee bulletproof route security and a seamless UX.



##  Getting Started (Local Development)

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.4.0 <4.0.0`)
*   [Firebase CLI](https://firebase.google.com/docs/cli) (Logged in and configured)
*   A Google Gemini API Key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   
   ```

2. **Install Flutter Dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   Create a `.env` file in the root directory and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Firebase Configuration**
   Ensure your Firebase project is configured for your desired platforms. If `firebase_options.dart` is missing, generate it via FlutterFire:
   ```bash
   flutterfire configure
   ```

5. **Run the application**
   ```bash
   # Run on Windows/macOS Desktop
   flutter run -d windows # or macos

   # Run on Web (Chrome)
   flutter run -d chrome
   ```
