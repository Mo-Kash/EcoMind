# EcoMind

EcoMind is a Flutter-based waste-sorting mobile app that helps users scan a single item or a mixed waste scene, analyze it locally on-device, and classify the material into a disposal stream using a lightweight computer vision pipeline.

This repository is the current implementation of that project. It is aligned with the code in the app and the supporting design notes in project-report.md, while keeping the README accurate to what is actually present in this repo today.

## What the app does

- **100% On-Device & Offline:** Completely private waste classification with zero cloud or external API dependencies.
- **Automated 3-Stage DIP + ML Pipeline:**
  1. **Stage 1 (DIP Image Conditioning):** Discrete Laplacian blur variance and mean luma quality gate, followed by background isolate auto-enhancement (Gray-World White Balance, CLAHE contrast boost, adaptive gamma, and unsharp mask sharpening).
  2. **Stage 2 (YOLO11-seg Instance Segmentation):** Class-agnostic instance isolation with fast morphological opening/closing and BFS largest connected component filtering on a standardized $160 \times 160$ prototype grid.
  3. **Stage 3 (DIP Feature Extraction & Classification):** Per-instance Sobel edge density ($D_{edge}$) surface texture analysis, HSV color-space grease/soil contamination ratio ($R_{soil}$), and MobileNetV3-Large classification with Bayesian prior calibration.
- **Dynamic India SWM 2016 Rules Engine:** Segregates items into 3 municipal streams (Wet / Dry Recyclable / Domestic Hazardous) with dynamic rerouting (e.g. food/grease-soiled paper and cardboard diverted from Dry Recyclable to Wet Waste for composting).
- **Interactive Before/After Wipe Comparator:** Draggable split slider widget on the results screen to inspect raw camera captures against the DIP auto-enhanced image fed into the neural models.
- **Auto-Healing Local SQLite Persistence:** Stores scan history, segmented bounding boxes, surface texture, and contamination metrics in a local database with automatic schema migrations.
- **Human-In-The-Loop & Dataset Export:** Active learning confirmation prompts for uncertain predictions and standardized COCO 1.0 JSON + images offline zip export.

## Current implementation status

The codebase implements a complete offline application with the following key pieces:

- **Flutter App Shell & Navigation:** `HomeScreen`, `CaptureScreen`, `ResultsScreen`, `PipelineInspectorScreen`, `HistoryScreen`, `SettingsScreen`.
- **Integrated DIP Engine:** `QualityGate`, `AutoEnhancement`, `EdgeTextureAnalyzer`, `HsvContamination`, `KMeansColor`, `HistogramAnalyzer`, `ContaminationHeatmapGenerator`, and `MaskUtils`.
- **Edge-Optimized ML Pipeline:** Quantized `yolo11n-seg.tflite` for instance segmentation and `mobilenetv3_large.tflite` for 9-class waste categorization with Test-Time Augmentation (TTA) and Bayesian prior calibration.
- **Regulatory Rules Engine:** SWM 2016 rules loaded from `disposal_rules.json` with dynamic contamination threshold rerouting.
- **Resilient Local Persistence:** `sqflite` database (`AppDatabase` v2) with automatic table reflection and schema self-healing for seamless app upgrades.
- **Automated Verification Suite:** 19 automated unit, widget, and contract tests in `test/`.

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

### Digital Image Processing (Pre-Processing & Feature Extraction)

- **Quality Gate:** Discrete Laplacian kernel convolution for blur variance ($\sigma^2_{blur}$) and luma histogram evaluation for exposure bounds.
- **Background Isolate Auto-Enhancement:** Gray-World White Balance, Contrast Stretching, Adaptive Gamma correction ($\gamma = 0.70 - 1.30$), and Gaussian Unsharp Mask sharpening.
- **Real-Time Sobel Surface Roughness:** Computes edge density ($D_{edge}$) on standardized $256\text{ px}$ patches to categorize surfaces as `Smooth`, `Semi-Smooth`, or `Textured / Rough`.
- **HSV Contamination & Residue Extraction:** Adaptive stride sampling within segmented masks to estimate food/oil/dirt soil ratios ($R_{soil}$) and contamination severity tiers.
- **Dominant Glass Cullet Hue Extraction:** Fast K-Means clustering ($k=3$) to determine cullet tint (`Clear`, `Green`, `Amber / Brown`).
- **Morphological Mask Refinement:** 3×3 binary opening, closing, and breadth-first search (BFS) largest connected component filtering on a standardized $160 \times 160$ prototype grid.

### Waste Detection & Classification

- **YOLO11n-seg Instance Segmentation:** Generates class-agnostic candidate bounding boxes and prototype masks.
- **MobileNetV3-Large Classifier:** 9-class waste categorization on $224 \times 224$ crops with Test-Time Augmentation (TTA).
- **Bayesian Prior Calibration:** Soft temperature prior discounting ($\gamma = 0.60$) to eliminate dominant dataset class biases (e.g. textile over-representation).
- **Dynamic India SWM 2016 Routing:** Automatically re-routes contaminated recyclables to municipal wet/compost bins based on DIP soil metrics.

### User Experience & Offline Workflow

- **Integrated Pipeline Flow:** Transparent 3-stage capture pipeline with live visual status updates.
- **Interactive Before/After Wipe Comparator:** Draggable split slider (`BeforeAfterSlider`) comparing raw camera capture vs. DIP conditioned neural input.
- **Pipeline Inspector:** Real-time telemetry inspector displaying blur variance, mean luma, isolate processing logs, and per-stage latency benchmarks.
- **Active Learning & Dataset Export:** HITL confirmation for low-confidence classifications with offline COCO 1.0 JSON + image zip export.

## Testing and validation

The repository includes a comprehensive automated test suite with **19 tests** passing:

- **`test/dip_test.dart` (12 Unit Tests):** Quality gate blur/exposure checks, morphological mask opening and BFS connected component isolation, HSV soil estimation, glass cullet tint mapping, 256-bin histogram and entropy calculations, and Sobel edge density surface roughness classification.
- **`test/model_contract_test.dart` (4 Contract Tests):** 9 PRD taxonomy classes, display name mappings, confidence thresholds, and DIP configuration invariants.
- **`test/tflite_models_test.dart` (2 Model Asset Tests):** Verifies physical presence and byte limits for `mobilenetv3_large.tflite`, `yolo11n-seg.tflite`, and `labels.txt`.
- **`test/widget_test.dart` (1 Widget Test):** Validates app launch, home screen actions, and pipeline guide rendering.

## Licensing and privacy

- Application code is treated as project source for this repository.
- The project is designed to avoid cloud APIs and to keep inference on-device.
- Model and data licensing should be reviewed separately when shipping or publishing a production build.

## Related documentation

- project-report.md — detailed implementation and technical design notes
- assets/ and lib/ — actual app code and ML assets

If you are working on this project, keep the README aligned with the actual implementation rather than the broader concept document, especially when features are added or removed from the app.
