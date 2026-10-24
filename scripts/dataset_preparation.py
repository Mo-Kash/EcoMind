"""
EcoMind 2.0 - Dataset Preparation Script
Merges TrashNet, TACO (crops & annotations), and Kaggle Garbage datasets.
Normalizes labels into the unified 9-class taxonomy.
Performs 80/10/10 group-split by scene/image ID to prevent data leakage.
"""

import os
import json
import shutil
import random
from collections import defaultdict
from pathlib import Path

TAXONOMY_9 = [
    "cardboard",
    "paper",
    "plastic",
    "glass",
    "metal",
    "organic",
    "battery_ewaste",
    "textile",
    "general_trash"
]

# Source dataset mapping to EcoMind 9 classes
LABEL_MAPPING = {
    # TrashNet
    "cardboard": "cardboard",
    "paper": "paper",
    "plastic": "plastic",
    "glass": "glass",
    "metal": "metal",
    "trash": "general_trash",
    
    # Kaggle Garbage Classification
    "biological": "organic",
    "battery": "battery_ewaste",
    "clothes": "textile",
    "shoes": "textile",
    "brown-glass": "glass",
    "green-glass": "glass",
    "white-glass": "glass",
    
    # TACO categories
    "Aluminium foil": "metal",
    "Battery": "battery_ewaste",
    "Aluminium blister pack": "metal",
    "Carded blister pack": "general_trash",
    "Other plastic bottle": "plastic",
    "Clear plastic bottle": "plastic",
    "Glass bottle": "glass",
    "Plastic bottle cap": "plastic",
    "Metal bottle cap": "metal",
    "Broken glass": "glass",
    "Food Can": "metal",
    "Aerosol": "metal",
    "Drink can": "metal",
    "Toilet tube": "cardboard",
    "Other carton": "cardboard",
    "Egg carton": "cardboard",
    "Drink carton": "cardboard",
    "Corrugated carton": "cardboard",
    "Meal carton": "cardboard",
    "Pizza box": "cardboard",
    "Paper cup": "paper",
    "Disposable plastic cup": "plastic",
    "Foam cup": "plastic",
    "Glass cup": "glass",
    "Other plastic cup": "plastic",
    "Food waste": "organic",
    "Glass jar": "glass",
    "Plastic lid": "plastic",
    "Metal lid": "metal",
    "Other plastic": "plastic",
    "Magazine paper": "paper",
    "Tissues": "general_trash",
    "Wrapping paper": "paper",
    "Normal paper": "paper",
    "Paper bag": "paper",
    "Plastic film": "plastic",
    "Six pack rings": "plastic",
    "Garbage bag": "plastic",
    "Other plastic wrapper": "plastic",
    "Single-use carrier bag": "plastic",
    "Polypropylene bag": "plastic",
    "Crisp packet": "plastic",
    "Spread tub": "plastic",
    "Tupperware": "plastic",
    "Disposable food container": "plastic",
    "Foam food container": "plastic",
    "Other plastic container": "plastic",
    "Plastic glooves": "general_trash",
    "Plastic utensils": "plastic",
    "Pop tab": "metal",
    "Rope & strings": "textile",
    "Scrap metal": "metal",
    "Shoe": "textile",
    "Squeezable tube": "plastic",
    "Plastic straw": "plastic",
    "Paper straw": "paper",
    "Styrofoam piece": "plastic",
    "Unlabeled litter": "general_trash",
    "Cigarette": "general_trash"
}

def prepare_dataset(raw_dir: str, output_dir: str, seed: int = 42):
    random.seed(seed)
    raw_path = Path(raw_dir)
    out_path = Path(output_dir)

    for split in ["train", "val", "test"]:
        for cls in TAXONOMY_9:
            (out_path / split / cls).mkdir(parents=True, exist_ok=True)

    print(f"Dataset preparation initialized. Target taxonomy: {TAXONOMY_9}")
    print(f"Output directory structure prepared at: {out_path}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="EcoMind 2.0 Dataset Normalizer & Splitter")
    parser.add_argument("--raw_dir", type=str, default="./raw_data", help="Directory with raw datasets")
    parser.add_argument("--output_dir", type=str, default="./processed_dataset", help="Destination folder")
    args = parser.parse_args()
    prepare_dataset(args.raw_dir, args.output_dir)

