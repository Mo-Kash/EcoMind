"""
EcoMind 2.0 - YOLO11n-seg Fine-Tuning Script
Trains YOLO11n-seg on TACO polygon annotations mapped to a single class: 'waste_item'.
Exports to TFLite format with embedded metadata for on-device inference.
"""

import os

try:
    from ultralytics import YOLO
except ImportError:
    print("Please install ultralytics: pip install ultralytics")

def train_and_export_yolo(data_yaml="taco_seg.yaml", epochs=100, imgsz=640):
    print("Loading pretrained YOLO11n-seg...")
    model = YOLO("yolo11n-seg.pt")

    print(f"Starting training on {data_yaml} for {epochs} epochs...")
    results = model.train(
        data=data_yaml,
        epochs=epochs,
        imgsz=imgsz,
        batch=16,
        mosaic=1.0,
        mixup=0.1,
        save=True,
        device=0
    )

    print("Evaluating validation set...")
    val_metrics = model.val()
    print(f"mAP@50: {val_metrics.seg.map50}")

    print("Exporting model to TFLite format with float16 quantization...")
    export_path = model.export(format="tflite", imgsz=imgsz, half=True)
    print(f"Export completed: {export_path}")
    print("Next step: copy the exported .tflite to assets/models/yolo11n-seg.tflite")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="YOLO11n-seg Training and Export")
    parser.add_argument("--data", type=str, default="taco_seg.yaml", help="Path to TACO dataset YAML")
    parser.add_argument("--epochs", type=int, default=100)
    args = parser.parse_args()
    print("To run in Colab:")
    print("!pip install ultralytics")
    print("python train_yolo11_seg.py --data path/to/taco.yaml")

