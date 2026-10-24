# EcoMind Project Report

## 1. Project overview

**EcoMind** is a Flutter application intended to make waste sorting and reuse more accessible. It combines account-based user profiles, a recyclable-goods listing and browsing experience, on-device image classification, and an AI-assisted waste-management chatbot.

The current application is organized around four main capabilities:

1. Create an account or sign in.
2. View waste-sorting information and classify an image of an item.
3. List recyclable or reusable items and browse listings from other users.
4. Maintain a profile and ask a chatbot questions about waste management.

The application uses Firebase Authentication and Cloud Firestore for user identity and application data. Waste classification uses a bundled TensorFlow Lite model. The chatbot sends requests to the Google Gemini API.

## 2. Goals and intended audience

The project aims to support people who want to dispose of waste more responsibly, people who can reuse or recycle materials, and potential buyers or organizations seeking reusable waste. The classifier and chatbot are intended to help users decide how to handle an item; the marketplace concept is intended to connect people who have materials with people who may use them.

The README describes the broader sustainability motivation and identifies a marketplace, educational game, and rewards as project concepts. The game and reward accrual are not implemented in the application code currently present.

## 3. Implemented features

### Accounts and authentication

- Email-and-password sign-up and sign-in are implemented with Firebase Authentication.
- On account creation, the app creates a Firestore user document with a display name, a zero-point reward balance, default contact information, and an empty product list.
- The root app listens to Firebase authentication state. Signed-out users see the authentication screens; signed-in users see the home screen.
- Sign-out is available from the home and profile interfaces.

### Home screen

- Displays a time-dependent greeting and sustainability-oriented introduction.
- Shows static recycling facts.
- Provides navigation to the EcoBot chatbot and waste classifier.
- Provides bottom navigation to the home, buyer, seller, and profile sections.

### Waste classifier

- Allows a user to capture an image with the camera or choose one from the image gallery.
- Runs the bundled `assets/mobilenetv2_trash_classifier.tflite` model locally through `tflite_flutter`.
- Resizes the selected image to 224 × 224 pixels, normalizes RGB channel values, and selects the highest-scoring output class.
- The classifier has 13 model labels: Battery, Biological, brown-glass, Cardboard, Clothes, Glass, green-glass, Metal, Paper, Plastic, Shoes, Trash, and white-glass. The three glass-color labels are presented to the user as “Glass.”
- Displays simple biodegradability, reusability, and recyclability descriptions for the predicted class.
- Can open the chatbot with a suggested question containing the prediction and classification details.

These descriptions are fixed mappings in the app, not additional model predictions.

### Chatbot

- Provides a message-based chat interface and a loading indicator while waiting for a response.
- Returns predefined replies for exact-match greetings and thank-you messages.
- Uses Gemini to classify other messages as waste-management-related or unrelated.
- Sends questions classified as relevant to Gemini with a waste-management instruction and displays the generated response.
- Rejects questions classified as unrelated with a scope reminder.

The app sends each submitted message as an individual request; it does not include prior chat messages as conversational context.

### Buyer and seller sections

- The buyer view reads user documents from Firestore, gathers their product lists, and displays product cards using bundled category images.
- Product cards show a name, price in Indian rupees, category, and a “BUY” action.
- The “BUY” action opens a seller-details screen showing the seller name, contact information, organization, and reward-point balance.
- The seller view displays the signed-in user’s products and provides a form to list a product or remove a listing.
- The product form validates a non-empty name, a digits-only price, and a selected category. The available categories are paper, metal, plastic, cardboard, glass, shoes, trash, clothes, battery, biological, and other.

The current buyer flow is a listing/contact discovery experience. There is no in-app checkout, payment, order management, or completed purchase workflow in the inspected application code.

### Profile

- Displays the account name, phone number, email address, organization, and reward points.
- Allows the user to edit their name and contact/profile information.
- Validates a 10-digit phone number and a basic email-address pattern.
- Provides an expandable developer-information section and a logout action.

## 4. Technical architecture

### Application startup and navigation

`lib/main.dart` initializes Flutter bindings and Firebase before starting the app. A Provider exposes the authentication-state stream as a nullable `UserObj`. `lib/screens/wrapper.dart` selects the authentication experience or the home screen based on that stream.

Navigation is primarily implemented with Flutter routes and page-level state. The home, buyer, seller, and profile screens each expose bottom-navigation controls.

### Backend and data storage

`DatabaseService` reads and writes the Cloud Firestore collection named `brews`. Each document is keyed by a Firebase user ID and stores:

| Field | Purpose |
|---|---|
| `name` | User display name |
| `rewardpoints` | Integer points balance |
| `userinfo` | Contact and organization data, including phone, email, and organization |
| `productdetails` | List of product maps containing listing details such as name, price, and category |

The buyer feed listens to collection snapshots. Profile, edit-profile, seller-list, and product-entry views listen to the signed-in user's document. Product details are stored as an array in the user document rather than in a separate listings collection.

### AI and image processing

- **Image model:** bundled TensorFlow Lite file at `assets/mobilenetv2_trash_classifier.tflite`.
- **Image utilities:** the `image` package performs decoding and resizing.
- **Image selection:** `image_picker` supports camera and gallery selection.
- **Chatbot service:** `lib/chatbot/gemini_service.dart` makes HTTP requests to the Google Generative Language API and handles basic greeting, relevance-classification, and response-generation steps.

The client does not provide an API-key entry field. A build-time Gemini key, if configured, is still extractable from a distributed app; production cloud requests should be routed through a protected backend with the key stored as a server-side secret. Rotate any credential previously embedded in or entered into the app.

## 5. Repository layout

| Path | Contents |
|---|---|
| [`lib/main.dart`](./lib/main.dart) | Firebase startup, Provider setup, and application root |
| [`lib/screens/`](./lib/screens/) | Authentication screens, app wrapper, and home screens |
| [`lib/services/`](./lib/services/) | Authentication, Firestore access, buyer/seller, profile, and listing flows |
| [`lib/chatbot/`](./lib/chatbot/) | Classifier UI/model integration and chatbot UI/service |
| [`lib/models/`](./lib/models/) | User and marketplace data models |
| [`lib/shared/`](./lib/shared/) | Shared input decoration and loading UI |
| [`assets/`](./assets/) | Classifier model, item/category images, and profile/loading imagery |
| [`icons/`](./icons/) | Launcher icon source image |
| [`screenshots/`](./screenshots/) | UI screenshots and a project presentation PDF |
| [`test/`](./test/) | Flutter widget test directory |
| `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` | Flutter platform project scaffolding and platform-specific configuration |

## 6. Technology stack and dependencies

- **Language and framework:** Dart and Flutter.
- **Minimum declared Dart SDK:** `^3.6.0`.
- **Authentication:** `firebase_auth`.
- **Cloud data:** `cloud_firestore`.
- **Firebase initialization:** `firebase_core`.
- **State propagation:** `provider`.
- **Image selection and processing:** `image_picker`, `image`.
- **On-device inference:** `tflite_flutter`.
- **Chat API requests:** `http`.
- **UI and utilities:** `flutter_spinkit`, `animate_do`, `tuple`, `intl`, and `cupertino_icons`.
- **Development/test dependencies:** `flutter_test`, `flutter_lints`, and `flutter_launcher_icons`.

The Android app applies the Google Services Gradle plugin and includes the Firebase BoM. The package manifest sets app version `1.0.0+1`; Android release builds currently use the debug signing configuration, so production signing still needs to be configured.

## 7. Assets and design

The assets directory includes category images for batteries, biological waste, cardboard, clothes, glass, metal, paper, plastic, shoes, trash, and other items, as well as a profile image, a loading animation, and the TensorFlow Lite model. The Flutter asset declaration includes the full `assets/` directory.

The interface uses green as its primary sustainability theme, with gradients, cards, icons, and animated transitions. The README identifies Figma as the design tool. UI screenshots and a presentation are kept in `screenshots/`.

## 8. Setup and running

### Prerequisites

- Flutter SDK compatible with Dart `^3.6.0`.
- A configured Firebase project with Firebase Authentication (email/password) and Cloud Firestore enabled.
- Valid Firebase configuration for each platform being built.
- A valid Gemini API setup for chatbot functionality.
- A device or emulator for camera/gallery and inference testing.

### Commands

From the repository root:

```sh
flutter pub get
flutter run
```

Useful project checks:

```sh
flutter analyze
flutter test
```

Platform release builds also require production signing and deployment configuration. Confirm the Firebase and API setup for the selected platform before attempting a full app run.

## 9. Current limitations and follow-up work

The following points are based on the code currently present and should be considered before treating the project as production-ready:

1. **Chat API credential handling:** a build-time Gemini credential is extractable from a distributed client. Move API access behind a protected service with a server-side secret; rotate any credential previously embedded in or entered into the app.
2. **Marketplace completion:** “BUY” opens seller details; no transaction, payment, order state, or buyer-to-seller messaging flow is implemented.
3. **Listing identity and lifecycle:** product details are stored inside per-user documents. The listing form stores name, price, and category, while buyer filtering looks for a `sellerUid` value. Verify ownership filtering and listing lifecycle behavior as the marketplace is completed.
4. **Rewards:** reward points are stored and displayed, but the inspected app code does not implement an award/accrual flow.
5. **Educational game:** the README lists a mini-game, but no game screen or game logic is present in the inspected Dart source.
6. **Chat resilience:** chatbot errors are returned as text or treated as an off-topic classification; production behavior would benefit from explicit user-facing error handling and robust API response validation.
7. **Classifier validation:** the application does not surface model confidence or a low-confidence warning. Verify label order, input normalization, and actual model output behavior against the model's training/export specification.
8. **Testing:** the existing widget test is still the default counter smoke-test template and expects counter UI that is not part of EcoMind. Add tests for authentication routing, profile/listing forms, classifier behavior, and chatbot response handling.
9. **Release readiness:** configure production app signing, validate Firebase settings and platform permissions, and verify camera/gallery behavior on target devices.
10. **Documentation alignment:** update the README when the game, rewards, payment/transactions, or deployment instructions change so documented features match the shipped app.

Potential future enhancements listed by the project README include improving model accuracy with additional training data, adding community/social features, and partnering with recycling organizations.

## 10. Project team and license

The README credits the team as:

- **Krish** — full-stack and Flutter application development.
- **Mohit and Anshul** — image-classification model and chatbot development.
- **Madhan** — UI/UX design and logo.

The repository includes an MIT License (`LICENSE`), with copyright attributed to Mo-Kash, 2025.

## 11. Reference files

- [README.md](./README.md) — project overview, stated features, installation, team, and roadmap.
- [pubspec.yaml](./pubspec.yaml) — SDK constraint, Flutter dependencies, and asset declaration.
- [lib/main.dart](./lib/main.dart) — Firebase initialization and application root.
- [lib/services/auth.dart](./lib/services/auth.dart) — Firebase authentication operations.
- [lib/services/database.dart](./lib/services/database.dart) — Firestore data access.
- [lib/screens/home/home.dart](./lib/screens/home/home.dart) — home screen and main feature navigation.
- [lib/chatbot/classifier.dart](./lib/chatbot/classifier.dart) — waste image classifier.
- [lib/chatbot/gemini_service.dart](./lib/chatbot/gemini_service.dart) — chatbot API behavior.
- [test/widget_test.dart](./test/widget_test.dart) — current widget test template.
