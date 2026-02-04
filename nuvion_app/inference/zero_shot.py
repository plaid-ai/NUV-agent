import logging
from typing import List, Optional

log = logging.getLogger(__name__)


class ZeroShotAnomalyDetector:
    def __init__(
        self,
        enabled: bool,
        model_name: str,
        labels: List[str],
        anomaly_labels: List[str],
        threshold: float,
    ):
        self.enabled = enabled
        self.ready = False
        self.labels = [label.strip() for label in labels if label and label.strip()]
        self.anomaly_labels = {label.strip().lower() for label in anomaly_labels if label and label.strip()}
        self.threshold = threshold
        self.model_name = model_name
        self._model = None
        self._processor = None
        self._device = None

        if not self.enabled:
            return
        if not self.labels:
            log.warning("Zero-shot enabled but labels are empty. Disabling.")
            self.enabled = False
            return

        try:
            import torch
            from transformers import AutoModel, AutoProcessor
            from PIL import Image
        except Exception as exc:
            log.warning("Zero-shot dependencies not available: %s", exc)
            self.enabled = False
            return

        device = "cpu"
        if torch.backends.mps.is_available():
            device = "mps"
        elif torch.cuda.is_available():
            device = "cuda"

        try:
            self._model = AutoModel.from_pretrained(self.model_name).to(device).eval()
            try:
                self._processor = AutoProcessor.from_pretrained(self.model_name)
            except AttributeError:
                from transformers import SiglipImageProcessor, GemmaTokenizerFast, SiglipProcessor
                image_processor = SiglipImageProcessor.from_pretrained(self.model_name)
                tokenizer = GemmaTokenizerFast.from_pretrained(self.model_name)
                self._processor = SiglipProcessor(image_processor=image_processor, tokenizer=tokenizer)
                log.info("Used manual SiglipProcessor construction (transformers compat workaround)")
            self._torch = torch
            self._Image = Image
            self._device = device
            self.ready = True
            log.info("Zero-shot model loaded: %s (device=%s)", self.model_name, device)
        except Exception as exc:
            log.warning("Failed to load zero-shot model '%s': %s", self.model_name, exc)
            self.enabled = False

    def classify(self, frame_rgb) -> Optional[dict]:
        if not self.enabled or not self.ready:
            return None

        try:
            image = self._Image.fromarray(frame_rgb)
            texts = [f"This is a photo of {label}." for label in self.labels]
            inputs = self._processor(
                text=texts,
                images=image,
                padding="max_length",
                max_length=64,
                return_tensors="pt",
            )
            inputs = {k: v.to(self._device) for k, v in inputs.items()}
            with self._torch.no_grad():
                outputs = self._model(**inputs)

            if hasattr(outputs, "logits_per_image") and outputs.logits_per_image is not None:
                logits = outputs.logits_per_image
            else:
                image_features = self._model.get_image_features(**{k: inputs[k] for k in ("pixel_values",) if k in inputs})
                text_features = self._model.get_text_features(**{k: inputs[k] for k in ("input_ids", "attention_mask") if k in inputs})
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                text_features = text_features / text_features.norm(dim=-1, keepdim=True)
                logits = image_features @ text_features.T

            probs = self._torch.sigmoid(logits).squeeze(0).tolist()
        except Exception as exc:
            log.warning("Zero-shot inference failed: %s", exc)
            return None

        if not probs:
            return None

        scored = list(zip(self.labels, probs))
        scored.sort(key=lambda item: item[1], reverse=True)
        labels = [item[0] for item in scored]
        scores = [float(item[1]) for item in scored]
        return {
            "label": labels[0],
            "score": scores[0],
            "labels": labels,
            "scores": scores,
        }

    def is_anomaly(self, frame_rgb):
        result = self.classify(frame_rgb)
        if not result:
            return False, None
        label = result["label"].lower()
        score = result["score"]
        if label in self.anomaly_labels and score >= self.threshold:
            return True, result
        return False, result
