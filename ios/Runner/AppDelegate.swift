import Flutter
import CoreImage
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "coupon_keeper/ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "recognizeText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let sourceRef = arguments["sourceRef"] as? String,
        !sourceRef.isEmpty
      else {
        result(FlutterError(code: "missing-source-ref", message: "A selected image reference is required.", details: nil))
        return
      }
      self?.recognizeText(sourceRef: sourceRef, result: result)
    }
  }

  private func recognizeText(sourceRef: String, result: @escaping FlutterResult) {
    guard let imageUrl = URL(string: sourceRef), let image = CIImage(contentsOf: imageUrl) else {
      result(FlutterError(code: "invalid-source-ref", message: "The selected image could not be opened.", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(code: "recognition-failed", message: error.localizedDescription, details: nil))
          }
          return
        }
        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let blocks = observations.compactMap { observation -> [String: Any]? in
          guard let candidate = observation.topCandidates(1).first else { return nil }
          let bounds = self.normalizedBounds(observation.boundingBox)
          return [
            "text": candidate.string,
            "confidence": candidate.confidence,
            "bounds": bounds,
            "lines": [[
              "text": candidate.string,
              "confidence": candidate.confidence,
              "bounds": bounds,
            ]],
          ]
        }
        DispatchQueue.main.async {
          result([
            "fullText": blocks.compactMap { $0["text"] as? String }.joined(separator: "\n"),
            "blocks": blocks,
          ])
        }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      let supported = (try? VNRecognizeTextRequest.supportedRecognitionLanguages(
        for: .accurate,
        revision: VNRecognizeTextRequestRevision1
      )) ?? []
      request.recognitionLanguages = ["ko-KR", "en-US"].filter { supported.contains($0) }

      do {
        try VNImageRequestHandler(ciImage: image, options: [:]).perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "recognition-failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func normalizedBounds(_ rect: CGRect) -> [String: Double] {
    return [
      "left": rect.origin.x,
      "top": 1 - rect.origin.y - rect.height,
      "width": rect.width,
      "height": rect.height,
    ]
  }
}
