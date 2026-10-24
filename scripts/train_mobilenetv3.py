"""
EcoMind 2.0 - MobileNetV3-Large Classifier Training Script
Trains a 9-class classifier using 2-phase transfer learning on merged waste datasets.
Exports float16 quantized TFLite model (< 12 MB).

CRITICAL INPUT CONTRACT:
tf.keras.applications.MobileNetV3Large includes an internal Rescaling layer when
instantiated with include_preprocessing=True (default), expecting input values in [0, 255].
The Flutter inference engine must feed [0, 255] float or uint8 according to this contract.
"""

import os
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
NUM_CLASSES = 9
CLASSES = [
    "cardboard", "paper", "plastic", "glass", "metal",
    "organic", "battery_ewaste", "textile", "general_trash"
]

def build_model(num_classes=NUM_CLASSES):
    # Backbone with ImageNet weights. include_preprocessing=False allows explicit control
    backbone = tf.keras.applications.MobileNetV3Large(
        input_shape=(IMG_SIZE[0], IMG_SIZE[1], 3),
        include_top=False,
        weights="imagenet",
        pooling="avg",
        include_preprocessing=False
    )
    backbone.trainable = False

    inputs = layers.Input(shape=(IMG_SIZE[0], IMG_SIZE[1], 3), name="input_image")
    # Explicit normalization layer: converts [0, 255] floats to [-1, 1] internally
    x = layers.Rescaling(scale=1./127.5, offset=-1.0)(inputs)
    x = backbone(x, training=False)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    model = models.Model(inputs=inputs, outputs=outputs, name="EcoMind_MobileNetV3")
    return model, backbone

def train_mobilenetv3(data_dir, output_dir="./models_output"):
    os.makedirs(output_dir, exist_ok=True)
    
    # Load dataset splits
    train_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(data_dir, "train"),
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        class_names=CLASSES
    )
    val_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(data_dir, "val"),
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        class_names=CLASSES
    )

    model, backbone = build_model()
    
    # Phase 1: Train classification head only
    print("=== Phase 1: Training Classification Head (Backbone Frozen) ===")
    model.compile(
        optimizer=optimizers.Adam(learning_rate=1e-3),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.1),
        metrics=["accuracy"]
    )
    model.fit(train_ds, validation_data=val_ds, epochs=8)

    # Phase 2: Unfreeze top 40% of backbone layers for fine-tuning
    print("=== Phase 2: Fine-Tuning Top Layers with Cosine Decay ===")
    backbone.trainable = True
    fine_tune_at = int(len(backbone.layers) * 0.6)
    for layer in backbone.layers[:fine_tune_at]:
        layer.trainable = False

    total_epochs = 30
    decay_steps = total_epochs * len(train_ds)
    lr_schedule = optimizers.schedules.CosineDecay(initial_learning_rate=1e-4, decay_steps=decay_steps)
    model.compile(
        optimizer=optimizers.Adam(learning_rate=lr_schedule),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.1),
        metrics=["accuracy", tf.keras.metrics.Precision(name="precision"), tf.keras.metrics.Recall(name="recall")]
    )
    model.fit(train_ds, validation_data=val_ds, epochs=22)

    # Save Keras Model
    keras_path = os.path.join(output_dir, "mobilenetv3_large_ecomind.keras")
    model.save(keras_path)
    print(f"Keras model saved to {keras_path}")

    # Export Float16 TFLite
    print("=== Exporting Float16 Quantized TFLite Model ===")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_model = converter.convert()

    tflite_path = os.path.join(output_dir, "mobilenetv3_large.tflite")
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    
    size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"TFLite exported to: {tflite_path} ({size_mb:.2f} MB)")
    print("Target size: <= 12 MB")

if __name__ == "__main__":
    print("Run in Google Colab with GPU acceleration:")
    print("python train_mobilenetv3.py")

