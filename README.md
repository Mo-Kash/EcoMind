# EcoMind 2.0

> **On-Device AI Waste-Sorting Assistant with Digital Image Processing (DIP)**  
> *Transforming waste management with multi-item instance segmentation, 9-class deep classification, contamination estimation, and context-aware conversational guidance.*

---

## 📖 Overview

**EcoMind 2.0** is an image-processing-driven waste-sorting assistant built with Flutter. It lets users photograph a single item or an entire cluttered pile of waste. The app processes the image completely on-device, enhances visual quality, segments every item using a YOLO instance-segmentation model, classifies materials using a fine-tuned MobileNetV3-Large model into nine official categories, estimates surface contamination using HSV color thresholding, and displays interactive colored mask overlays with municipal disposal guidance.

All computer vision and rules inference run **100% on-device and offline**. No user accounts, cloud databases, or marketplace features are required.

---

## 🏆 Key Features

- **Multi-Item Instance Segmentation (YOLO11n-seg):** Detects, bounds, and segments up to 20 items per scene with morphological mask refinement (opening, closing, hole filling, overlap suppression).
- **Digital Image Processing (DIP) Pipeline:**
  - **Quality Gate:** Automated blur estimation (Laplacian variance) and exposure checking (mean luma, pixel clipping) with plain-language warning and retake overrides.
  - **Conditional Auto-Enhancement:** Gray-world white balance, CLAHE adaptive contrast on LAB L-channel, gamma adjustment, noise reduction, and unsharp masking executed in background Dart isolates ($\le 150\text{ ms}$).
  - **HSV Contamination Analysis:** Mask-bounded erosion and circular hue/saturation/value thresholding to categorize residue and staining into *Clean* ($<10\%$), *Light* ($10\text{--}30\%$), or *Heavy* ($>30\%$).
  - **Glass Color Extraction:** $k$-means clustering ($k=3$) inside segmented glass masks to isolate clear, green, brown, or other cullet colors.
- **India Solid Waste Management (SWM 3-Stream) Rules Engine:**
  - 🟢 **Green Bin (Wet / Biodegradable):** Organic food waste, peels, compostables, and heavily soiled greasy paper/cardboard.
  - 🔵 **Blue Bin (Dry Recyclable):** Clean paper, cardboard, plastics, glass bottles, metals, and clean textiles.
  - 🔴 **Red / Black Bin (Domestic Hazardous & E-Waste):** Batteries, electronics, and toxic chemicals.
- **Context-Aware EcoBot (Gemini 1.5 Flash via Firebase AI Logic):**
  - Prompt-injection hardened chatbot with strict waste-sorting guardrails.
  - Injects detected material, confidence, contamination level, and scene summary directly into conversation context.
  - Offline fallback directly to municipal rules when disconnected.
- **Human-in-the-Loop (HITL) Dataset Exporter:**
  - One-tap "Wrong?" correction sheet on every item.
  - Saves crops, masks, and metadata to local SQLite (`sqflite`).
  - Single-tap ZIP export (`manifest.csv`, COCO-format `annotations.json`, cropped PNGs) for iterative model retraining.
- **Pipeline Inspector:** Real-time stage-by-stage visualizer comparing original vs. enhanced images, Canny edges, masks, and microsecond latency timings.

---

## 📊 Model Evaluation & Training Results

The 9-class MobileNetV3-Large classifier was trained using 2-phase transfer learning on merged datasets (Kaggle Garbage Classification 12-class + TrashNet) and converted to Float16 quantized TFLite.

### Executive Summary vs. PRD Targets

| Metric | PRD Target | Achieved Result | Status |
| :--- | :---: | :---: | :---: |
| **Top-1 Accuracy** | $\ge 92.0\%$ (test) / $\ge 85.0\%$ (field) | **98.76%** | **PASS** |
| **Top-3 Accuracy** | — | **99.77%** | **PASS** |
| **Macro-F1 Score** | $\ge 0.880$ | **0.9805** | **PASS** |
| **Weighted-F1 Score** | — | **0.9876** | **PASS** |
| **Min. Per-Class Recall** | $\ge 0.750$ | **0.951** (`general_trash`) | **PASS** |
| **TFLite Model Size** | $\le 12.0\text{ MB}$ | **5.73 MB** (Float16) | **PASS** |
| **Inference Latency** | $\le 40.0\text{ ms}$ / crop | **7.80 ms** / crop | **PASS** |

*Evaluation performed on **2,666 unseen validation images** across all 9 classes (Tesla T4 GPU).*

---

### Detailed Per-Class Performance Table

```text
                  precision    recall  f1-score   support

     cardboard      0.994     0.978     0.986       183
         paper      0.983     0.987     0.985       237
       plastic      0.989     0.958     0.973       191
         glass      0.977     0.995     0.986       380
         metal      0.964     0.958     0.961       167
       organic      0.987     1.000     0.993       148
battery_ewaste      0.972     0.993     0.983       142
       textile      0.999     0.998     0.999      1096
 general_trash      0.967     0.951     0.959       122

      accuracy                          0.988      2666
     macro avg      0.981     0.980     0.981      2666
  weighted avg      0.988     0.988     0.988      2666
```

---

### Confusion Matrix

```text
                  card  pape  plas  glas  meta  orga  batt  text  gene
       cardboard   179     2     0     1     1     0     0     0     0
           paper     1   234     0     0     1     0     0     0     1
         plastic     0     0   183     4     1     0     1     0     2
           glass     0     0     1   378     1     0     0     0     0
           metal     0     0     0     3   160     0     3     0     1
         organic     0     0     0     0     0   148     0     0     0
  battery_ewaste     0     0     1     0     0     0   141     0     0
         textile     0     1     0     0     0     1     0  1094     0
   general_trash     0     1     0     1     2     1     0     1   116
```

---

## 🛠️ Architecture & Tech Stack

```text
lib/
├── core/
│   ├── config/              # AppConfig (thresholds, model paths, defaults)
│   ├── constants/           # Taxonomy, color palettes, display names
│   ├── theme/               # Modern green accessible theme (48dp touch targets)
│   └── utils/               # IsolateRunner for background compute
├── data/
│   ├── local/               # AppDatabase (sqflite schema for scans, items, corrections)
│   └── models/              # Data models (ScanRecord, DetectedItem, QualityMetrics)
├── features/
│   ├── capture/             # CaptureScreen with live quality gate feedback
│   ├── dip/                 # Pure Dart DIP algorithms (QualityGate, AutoEnhancement,
│   │                        # MaskUtils, HsvContamination, KMeansColor)
│   ├── detection/           # YoloDetectorService (YOLO11n-seg inference & NMS)
│   ├── classification/      # MobileNetClassifierService (TFLite, TTA, contracts)
│   ├── rules/               # DisposalRulesService (India SWM 3-stream JSON engine)
│   ├── results/             # ResultsScreen, mask overlays, donut chart, item cards
│   ├── chat/                # EcoBotService & EcoBotChatScreen (Gemini + guardrails)
│   ├── hitl/                # CorrectionSheet & DatasetExporter (ZIP with COCO/CSV)
│   ├── inspector/           # PipelineInspectorScreen (stage metrics & profiling)
│   ├── history/             # HistoryScreen (local past scans & deletion)
│   └── settings/            # SettingsScreen (toggles, Gemini key, data wipe)
└── main.dart
assets/
├── models/
│   ├── mobilenetv3_large.tflite   # 9-class classifier (5.73 MB)
│   ├── yolo11n-seg.tflite         # Instance segmentation model (11.18 MB)
│   └── labels.txt                 # Exact taxonomy ordering
└── rules/
    ├── disposal_rules.json        # India SWM 3-stream rules & overrides
    └── contamination_config.json  # Calibrated HSV thresholds
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK $\ge 3.6.0$
- Android SDK $\ge 23$ (Android 6.0+)
- Google Chrome or physical Android device / emulator

### 1. Clone & Install
```bash
git clone https://github.com/your-username/EcoMind.git
cd EcoMind
flutter pub get
```

### 2. Verify Models & Rules
Ensure the trained models and configuration files are present in `assets/`:
- `assets/models/mobilenetv3_large.tflite`
- `assets/models/yolo11n-seg.tflite`
- `assets/models/labels.txt`
- `assets/rules/disposal_rules.json`

### 3. Run Automated Tests
```bash
flutter test
```
All 13 test suites (DIP algorithms, mask morphology, color extraction, model contracts, model sizes, and widget rendering) will execute and verify the pipeline.

### 4. Launch the App
```bash
flutter run
```

---

## 🛡️ Privacy & Licensing

- **Privacy:** 100% on-device inference. No user login, no tracking, no cloud telemetry. User corrections stay in the local SQLite database until the user explicitly taps "Export Retraining Dataset".
- **Licensing:**
  - Application Source: MIT License.
  - Segmentation Engine: Ultralytics YOLO (AGPL-3.0).
  - Datasets: TACO, TrashNet, Kaggle Garbage Classification.
