# EcoMind

EcoMind is a Flutter-based waste-sorting mobile app that helps users scan a single item or a mixed waste scene, analyze it locally on-device, and classify the material into a disposal stream using a lightweight computer vision pipeline.

This repository is the current implementation of that project. It is aligned with the code in the app and the supporting design notes in project-report.md, while keeping the README accurate to what is actually present in this repo today.

## What the app does

- Captures images from camera or gallery
- Runs local quality checks and enhancement before inference
- Detects and segments waste objects using a TFLite detector
- Classifies detected items into a 9-class taxonomy
- Estimates contamination and color attributes for material-specific guidance
- Routes items using the India SWM 3-stream disposal model
- Stores scan history and user correction metadata in local SQLite
- Exports dataset corrections for retraining purposes

## Current implementation status

The codebase implements a working prototype / research demo with the following key pieces:

- Flutter app shell and navigation: HomeScreen, CaptureScreen, ResultsScreen, HistoryScreen, SettingsScreen
- DIP processing tools: quality gate, enhancement, edge/texture analysis, thresholding, histogram analysis, contamination heatmap
- Local model integration: YOLO11n-seg and MobileNetV3-style classifier assets under assets/models
- Disposal rules engine: local JSON-based rules for waste stream routing
- Local persistence: sqflite database for scan history, item records, and corrections
- Automated tests covering DIP algorithms and model asset contract assumptions

## Notable repo realities

This project is intentionally privacy-first and offline-first. The current implementation is not a cloud-based product and does not currently include:

- Firebase authentication
- remote database syncing
- Gemini / Firebase AI chat integration wired into the app
- a live production ML backend

The project-report.md is a more detailed technical design and implementation narrative, while this README focuses on the actual repository structure and setup as it exists now.

## Tech stack

- Flutter
- Dart
- TFLite / tflite_flutter
- sqflite for local storage
- image_picker, image, path_provider, shared_preferences
- Flutter Material UI

## Project structure

```text
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── local/
│   └── models/
├── features/
│   ├── capture/
│   ├── classification/
│   ├── detection/
│   ├── dip/
│   ├── hitl/
│   ├── history/
│   ├── home/
│   ├── results/
│   ├── rules/
│   └── settings/
├── main.dart
└── ...

assets/
├── models/
│   ├── mobilenetv3_large.tflite
│   ├── yolo11n-seg.tflite
│   └── labels.txt
├── rules/
│   ├── disposal_rules.json
│   └── contamination_config.json
└── ...
```

## Waste taxonomy

The classifier currently uses a 9-class taxonomy:

- cardboard
- paper
- plastic
- glass
- metal
- organic
- battery_ewaste
- textile
- general_trash

## Setup

### Prerequisites

- Flutter SDK 3.6.0 or newer
- Android SDK / Android emulator or a physical Android device
- Optional: Chrome for web testing

### Install dependencies

```bash
git clone https://github.com/Mo-Kash/EcoMind.git
cd EcoMind
flutter pub get
```

### Verify required assets

Check that these files are present before running the app:

```bash
assets/models/mobilenetv3_large.tflite
assets/models/yolo11n-seg.tflite
assets/models/labels.txt
assets/rules/disposal_rules.json
assets/rules/contamination_config.json
```

### Run tests

```bash
flutter test
```

### Run the app

```bash
flutter run
```

## Features implemented in this repo

### Digital image processing

- quality gate for blur and exposure checks
- auto-enhancement workflow for white balance, contrast, gamma adjustment, and sharpening
- edge and texture analysis
- contamination heatmap generation
- histogram analysis and thresholding utilities
- glass color extraction logic

### Waste detection and classification

- local TFLite segmentation and classification pipeline
- post-processing of raw detections
- fallback saliency-based detection when model inference is unavailable
- 9-class material labeling and disposal guidance

### User experience and offline workflow

- camera and gallery capture flow
- before/after DIP comparison UI
- local scan history
- correction tracking and dataset export flow
- privacy-focused settings and data wipe support

## Testing and validation

The repo includes tests for:

- DIP quality gate behavior
- morphological mask operations
- contamination estimation
- glass color extraction
- histogram analysis
- edge/texture classification
- thresholding logic
- TFLite asset presence/service readiness expectations

## Licensing and privacy

- Application code is treated as project source for this repository.
- The project is designed to avoid cloud APIs and to keep inference on-device.
- Model and data licensing should be reviewed separately when shipping or publishing a production build.

## Related documentation

- project-report.md — detailed implementation and technical design notes
- assets/ and lib/ — actual app code and ML assets

If you are working on this project, keep the README aligned with the actual implementation rather than the broader concept document, especially when features are added or removed from the app.
