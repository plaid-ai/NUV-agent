import os
import cv2
import numpy as np

from nuvion_app.config import load_env

try:
    import tritonclient.http as httpclient
except Exception as exc:  # pragma: no cover
    httpclient = None
    _IMPORT_ERROR = exc
else:
    _IMPORT_ERROR = None


class TritonAnomalyClient:
    def __init__(self):
        load_env()
        if httpclient is None:
            raise ImportError(f"tritonclient is not available: {_IMPORT_ERROR}")

        self.url = os.getenv("NUVION_TRITON_URL", "localhost:8000")
        self.model_name = os.getenv("NUVION_TRITON_MODEL", "zsad")
        self.input_name = os.getenv("NUVION_TRITON_INPUT", "INPUT__0")
        self.output_name = os.getenv("NUVION_TRITON_OUTPUT", "OUTPUT__0")
        self.input_format = os.getenv("NUVION_TRITON_INPUT_FORMAT", "NHWC").upper()
        self.input_width = int(os.getenv("NUVION_TRITON_INPUT_WIDTH", "224"))
        self.input_height = int(os.getenv("NUVION_TRITON_INPUT_HEIGHT", "224"))
        self.input_dtype = os.getenv("NUVION_TRITON_INPUT_DTYPE", "FP32")
        self.scale = float(os.getenv("NUVION_TRITON_INPUT_SCALE", "255.0"))
        self.output_mode = os.getenv("NUVION_TRITON_OUTPUT_MODE", "score").lower()
        self.output_activation = os.getenv("NUVION_TRITON_OUTPUT_ACTIVATION", "sigmoid").lower()
        self.labels = [label.strip() for label in os.getenv("NUVION_TRITON_LABELS", "").split(",") if label.strip()]

        self.client = httpclient.InferenceServerClient(url=self.url)

    def _preprocess(self, frame_rgb):
        resized = cv2.resize(frame_rgb, (self.input_width, self.input_height))
        arr = resized.astype(np.float32) / self.scale
        if self.input_format == "NCHW":
            arr = np.transpose(arr, (2, 0, 1))
        arr = np.expand_dims(arr, axis=0)
        return arr

    def _activate(self, scores: np.ndarray) -> np.ndarray:
        if self.output_activation == "softmax":
            exps = np.exp(scores - np.max(scores))
            return exps / np.sum(exps)
        if self.output_activation == "sigmoid":
            return 1.0 / (1.0 + np.exp(-scores))
        return scores

    def infer(self, frame_rgb):
        arr = self._preprocess(frame_rgb)
        input_tensor = httpclient.InferInput(self.input_name, arr.shape, self.input_dtype)
        input_tensor.set_data_from_numpy(arr)
        output = httpclient.InferRequestedOutput(self.output_name)
        response = self.client.infer(
            model_name=self.model_name,
            inputs=[input_tensor],
            outputs=[output],
        )
        result = response.as_numpy(self.output_name)
        if result is None:
            raise RuntimeError("No output received from Triton")
        return result

    def predict(self, frame_rgb):
        result = self.infer(frame_rgb)
        flat = result.reshape(-1)
        if self.output_mode == "score":
            return {"label": "ANOMALY", "score": float(flat[0])}
        scores = self._activate(flat)
        scores_list = scores.tolist()
        if not self.labels or len(self.labels) != len(scores_list):
            top_idx = int(np.argmax(scores))
            return {
                "label": f"class_{top_idx}",
                "score": float(scores[top_idx]),
                "scores": scores_list,
            }
        top_idx = int(np.argmax(scores))
        return {
            "label": self.labels[top_idx],
            "score": float(scores[top_idx]),
            "scores": scores_list,
        }
