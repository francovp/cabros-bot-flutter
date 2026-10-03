# Cabros Bot Operator Console (Flutter)

A cross-platform operator console and diagnostic panel for **Cabros Bot**, built with Flutter.

The console connects directly to the Cabros Bot API (`https://cabros-bot-production.up.railway.app` or a custom endpoint) to provide real-time operational visibility, signal analysis, alert replay, market scanner orchestration, and interactive API exploration.

---

## Features

| Workspace Section | Description |
|---|---|
| **Overview** | Quick-glance system health, active channel count, core metrics, and one-click actions. |
| **Status & Capabilities** | Live inspection of service metadata, runtime feature flags, delivery channels (Telegram, WhatsApp, Discord), and dependencies (TradingView MCP, Gemini, Binance, Twelve Data, Firestore, Sentry). |
| **Alerts Feed** | Full stored alert history with cursor pagination, enriched/plain filters, per-channel delivery statuses, LLM token metrics, and instant alert replay. |
| **Signal Outcomes** | Systematic tracking of alert performance across timeframes (`1h`, `4h`, `1D`, `1W`), win rates, expectancy ($R$), MFE/MAE excursions, and realized returns. |
| **Scanner Presets** | CRUD manager for TradingView market scanner presets with immediate manual execution. |
| **Background Jobs** | BullMQ/Render worker job monitor with real-time polling, multi-phase progress meters, job results inspection, retry, and cancellation. |
| **Quick Analysis** | Interactive runners for Volume Confirmation, Expanded Analysis Alerts, and Market Scanner triggers with custom timeouts. |
| **API Playground** | Dynamic API testing client driven by live `/openapi.json` contract introspection, complete with formatted JSON editors and response inspectors. |

---

## User Interface & Design

- **Dark Theme**: Custom theme matching the Cabros Bot dark console design (`#08111F` canvas, `#0F1D31` card panels, `#62D8FF` accents).
- **Responsive Layout**: Persistent sidebar on desktop and wide screens (`>= 900px`), with a collapsable drawer on mobile and tablet devices.
- **Copy & Highlight Support**: Every screen and modal is wrapped in Flutter's `SelectionArea`, allowing operators to highlight and copy alert text, JSON payloads, IDs, and metrics directly.
- **Fail-Safe & Defensive Parsing**: Robust data models handle both legacy and modern API payload shapes (e.g. array vs map `deliveryResults`).

---

## Authentication & Configuration

The console supports dual authentication modes:
1. **API Key (`x-api-key`)**: For protected webhook and operational endpoints.
2. **Firebase ID Token (`Bearer`)**: For role-gated admin operations (`admin.viewer`, `admin.operator`).

Credentials and base URL configurations can be managed anytime via the **Connection & Auth Settings** modal (click the connection pill in the header) and are persisted locally using `shared_preferences`.

> **Security Note**: All credentials entered are stored strictly on-device in local storage. Secrets and tokens are automatically masked and redacted in logs and error banners.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.19.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.3.0`)
- Google Chrome (for Flutter Web) or Xcode / CocoaPods (for macOS Desktop)

### Running Locally

1. **Clone the repository and install dependencies**:
   ```bash
   cd cabros_bot_flutter
   flutter pub get
   ```

2. **Run in Chrome (Flutter Web)**:
   ```bash
   flutter run -d chrome
   ```

3. **Run on macOS Desktop**:
   ```bash
   flutter run -d macos
   ```

4. **Build for Production Web**:
   ```bash
   flutter build web --release
   ```

---

## Testing & Quality

Run the automated test suite and static analysis:

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

### Test Coverage
- **Unit Tests (`test/unit/`)**:
  - `admin_view_model_test.dart` — State transitions, job polling supervision, credentials persistence.
  - `api_client_test.dart` — Endpoint-specific timeout budgets, URI building, secret redaction.
  - `models_test.dart` — JSON deserialization for Status, Alerts, Outcomes, Jobs, Scanner Presets, and OpenAPI spec.
- **Widget Tests (`test/widget/`)**:
  - `selection_test.dart` — Verifies `SelectionArea` availability across the app hierarchy.
  - `shell_view_test.dart` — Responsive layout switches, navigation rail, and drawer interactions.
  - `overview_view_test.dart` — KPI rendering, empty states, and action triggers.
  - `status_badge_test.dart` & `metric_card_test.dart` — Core UI component rendering.

---

## Project Structure

```text
lib/
├── data/
│   ├── models/            # Strongly-typed data models with defensive parsing
│   │   ├── admin_status.dart
│   │   ├── alert_model.dart
│   │   ├── job_model.dart
│   │   ├── openapi_spec.dart
│   │   ├── outcome_model.dart
│   │   └── preset_model.dart
│   └── services/          # Network client & API abstraction
│       ├── admin_service.dart
│       └── api_client.dart
├── ui/
│   ├── core/              # Theme & reusable widgets
│   │   ├── theme.dart
│   │   └── widgets/       # MetricCard, StatusBadge, ResponseBlock, etc.
│   └── features/          # Feature views for all 8 console sections
│       ├── alerts/
│       ├── analysis/
│       ├── auth/
│       ├── jobs/
│       ├── outcomes/
│       ├── overview/
│       ├── playground/
│       ├── presets/
│       ├── shell/
│       └── status/
├── view_models/           # ChangeNotifier state management & supervisors
│   └── admin_view_model.dart
└── main.dart              # Application entry point with SelectionArea wrapper
```

---

## License

Private / Proprietary. Part of the Cabros Bot ecosystem.
