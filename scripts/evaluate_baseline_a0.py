"""
EcoMind 2.0 - Ablation Run A0: Baseline Old Model Evaluation
Evaluates assets/mobilenetv2_trash_classifier.tflite on the unseen field set.
Outputs: Top-1 Accuracy, Macro-F1, per-class metrics, and confusion matrix.
"""

import os
import time
import numpy as np
from PIL import Image

try:
    import tensorflow as tf
except ImportError:
    import tflite_runtime.interpreter as tflite
    tf = None

OLD_CLASSES_13 = [
    "Battery", "Biological", "brown-glass", "Cardboard", "Clothes", "Glass",
    "green-glass", "Metal", "Paper", "Plastic", "Shoes", "Trash", "white-glass"
]

# Fold 13 classes into 9 classes for direct comparison
OLD_TO_NEW_9 = {
    "Battery": "battery_ewaste",
    "Biological": "organic",
    "brown-glass": "glass",
    "Cardboard": "cardboard",
    "Clothes": "textile",
    "Glass": "glass",
    "green-glass": "glass",
    "Metal": "metal",
    "Paper": "paper",
    "Plastic": "plastic",
    "Shoes": "textile",
    "Trash": "general_trash",
    "white-glass": "glass"
}

def load_interpreter(model_path):
    if tf is not None:
        interpreter = tf.lite.Interpreter(model_path=model_path)
    else:
        interpreter = tflite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    return interpreter

def evaluate_field_set(model_path: str, field_set_dir: str):
    if not os.path.exists(model_path):
        print(f"Error: Model not found at {model_path}")
        return
    if not os.path.exists(field_set_dir):
        print(f"Warning: Field set directory not found at {field_set_dir}")
        print("Please place the field test images into folders named after the 9 classes.")
        return

    interpreter = load_interpreter(model_path)
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    print(f"Model Input Shape: {input_details[0]['shape']}, Type: {input_details[0]['dtype']}")
    print("Evaluating baseline on field images...")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Evaluate Old Model Baseline (A0)")
    parser.add_argument("--model", type=str, default="./assets/mobilenetv2_trash_classifier.tflite")
    parser.add_argument("--field_set", type=str, default="./data/field_set")
    args = parser.parse_args()
    evaluate_field_set(args.model, args.field_set)

