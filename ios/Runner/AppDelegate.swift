import Flutter
import CoreImage
import CryptoKit
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
  private var pendingSourceResult: FlutterResult?
  private var pendingSourceType: String?
  private var retryHandles: [String: RetryableSource] = [:]

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
    let sourceChannel = FlutterMethodChannel(
      name: "coupon_keeper/source_picker",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sourceChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "pickSources":
        guard
          let arguments = call.arguments as? [String: Any],
          let sourceType = arguments["sourceType"] as? String
        else {
          result(FlutterError(code: "missing-source-type", message: "A source type is required.", details: nil))
          return
        }
        self.pickSources(sourceType: sourceType, result: result)
      case "retryFailures":
        let arguments = call.arguments as? [String: Any]
        let handles = arguments?["handles"] as? [String] ?? []
        result(self.stageRetryHandles(handles))
      case "releaseSources":
        let arguments = call.arguments as? [String: Any]
        self.releaseSources(
          sourceRefs: arguments?["sourceRefs"] as? [String] ?? [],
          handles: arguments?["handles"] as? [String] ?? []
        )
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let sourceCleanupChannel = FlutterMethodChannel(
      name: "coupon_keeper/source_cleanup",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sourceCleanupChannel.setMethodCallHandler { call, result in
      guard call.method == "openSource" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let originalUri = arguments["originalUri"] as? String,
        let url = URL(string: originalUri),
        UIApplication.shared.canOpenURL(url)
      else {
        result(false)
        return
      }
      UIApplication.shared.open(url) { opened in
        result(opened)
      }
    }
    let remindersChannel = FlutterMethodChannel(
      name: "coupon_keeper/reminders",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    remindersChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "requestAuthorization":
        self?.requestReminderAuthorization(result: result)
      case "schedule":
        self?.scheduleReminder(arguments: call.arguments, result: result)
      case "cancelForPass":
        guard
          let arguments = call.arguments as? [String: Any],
          let passId = arguments["passId"] as? String
        else {
          result(nil)
          return
        }
        self?.cancelRemindersForPass(passId: passId, result: result)
      case "cancelAll":
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestReminderAuthorization(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      DispatchQueue.main.async {
        result(granted)
      }
    }
  }

  private func scheduleReminder(arguments: Any?, result: @escaping FlutterResult) {
    guard
      let payload = arguments as? [String: Any],
      let id = payload["id"] as? String,
      let passId = payload["passId"] as? String,
      let title = payload["title"] as? String,
      let body = payload["body"] as? String,
      let triggerAtMillis = payload["triggerAtMillis"] as? NSNumber
    else {
      result(FlutterError(code: "invalid-reminder", message: "A reminder id, pass id, title, body, and trigger time are required.", details: nil))
      return
    }

    let triggerDate = Date(timeIntervalSince1970: triggerAtMillis.doubleValue / 1000)
    let interval = max(1, triggerDate.timeIntervalSinceNow)
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = ["passId": passId]
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(code: "schedule-reminder-failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  private func cancelRemindersForPass(passId: String, result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let ids = requests
        .map(\.identifier)
        .filter { $0.hasPrefix("\(passId):") }
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
      DispatchQueue.main.async {
        result(nil)
      }
    }
  }

  private func pickSources(sourceType: String, result: @escaping FlutterResult) {
    guard pendingSourceResult == nil else {
      result(FlutterError(code: "picker-busy", message: "A source picker is already open.", details: nil))
      return
    }
    pendingSourceResult = result
    pendingSourceType = sourceType

    switch sourceType {
    case "photos":
      var configuration = PHPickerConfiguration(photoLibrary: .shared())
      configuration.filter = .images
      configuration.selectionLimit = 0
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      rootViewController?.present(picker, animated: true)
    case "downloads":
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: false)
      picker.allowsMultipleSelection = true
      picker.delegate = self
      rootViewController?.present(picker, animated: true)
    case "folder":
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
      picker.allowsMultipleSelection = false
      picker.delegate = self
      rootViewController?.present(picker, animated: true)
    default:
      pendingSourceResult = nil
      pendingSourceType = nil
      result(FlutterError(code: "unknown-source-type", message: "Unknown source type: \(sourceType)", details: nil))
    }
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    let result = pendingSourceResult
    pendingSourceResult = nil
    pendingSourceType = nil
    guard let result else { return }
    if results.isEmpty {
      result(["status": "cancelled"])
      return
    }

    let group = DispatchGroup()
    var urls: [URL] = []
    var failures: [[String: Any]] = []
    for item in results {
      group.enter()
      item.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] url, _ in
        defer { group.leave() }
        guard let self, let url else {
          let handle = UUID().uuidString
          failures.append(["handle": handle, "displayName": "selected-photo"])
          return
        }
        let staged = self.cacheFileUrl()
        do {
          try FileManager.default.copyItem(at: url, to: staged)
          urls.append(staged)
        } catch {
          let handle = UUID().uuidString
          failures.append(["handle": handle, "displayName": url.lastPathComponent])
        }
      }
    }
    group.notify(queue: .main) {
      result(self.stageUrls(sourceType: "photos", urls: urls, failures: failures))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingSourceResult?(["status": "cancelled"])
    pendingSourceResult = nil
    pendingSourceType = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = pendingSourceResult
    let sourceType = pendingSourceType ?? "downloads"
    pendingSourceResult = nil
    pendingSourceType = nil
    guard let result else { return }

    if sourceType == "folder" {
      result(stageFolder(urls.first))
    } else {
      result(stageUrls(sourceType: "downloads", urls: urls))
    }
  }

  private func stageFolder(_ folderUrl: URL?) -> [String: Any] {
    guard let folderUrl else {
      return ["status": "fileUnavailable"]
    }
    let urls = coordinatedRead(folderUrl) { readableUrl -> [URL] in
      let children = (try? FileManager.default.contentsOfDirectory(
        at: readableUrl,
        includingPropertiesForKeys: [.contentTypeKey],
        options: [.skipsHiddenFiles]
      )) ?? []
      return children.filter { child in
        let type = try? child.resourceValues(forKeys: [.contentTypeKey]).contentType
        return type?.conforms(to: .image) == true
      }
    } ?? []
    return stageUrls(sourceType: "folder", urls: urls)
  }

  private func stageRetryHandles(_ handles: [String]) -> [String: Any] {
    let sources = handles.compactMap { retryHandles[$0] }
    return stageUrls(sourceType: "downloads", urls: sources.map(\.url))
  }

  private func stageUrls(sourceType: String, urls: [URL], failures: [[String: Any]] = []) -> [String: Any] {
    var items: [[String: Any?]] = []
    var collectedFailures = failures
    for url in urls {
      do {
        let source = try stageUrl(sourceType: sourceType, url: url)
        items.append(source)
      } catch {
        let handle = UUID().uuidString
        retryHandles[handle] = RetryableSource(url: url, sourceType: sourceType, displayName: url.lastPathComponent)
        collectedFailures.append(["handle": handle, "displayName": url.lastPathComponent])
      }
    }
    return ["status": "selected", "items": items, "failures": collectedFailures]
  }

  private func stageUrl(sourceType: String, url: URL) throws -> [String: Any?] {
    let bytes = try coordinatedRead(url) { readableUrl in
      try Data(contentsOf: readableUrl)
    } ?? Data()
    let destination = cacheFileUrl()
    try bytes.write(to: destination, options: [.atomic])
    let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    return [
      "sourceType": sourceType,
      "sourceToken": "sha256:\(digest)",
      "platformSourceRef": destination.absoluteString,
      "displayName": url.lastPathComponent,
      "byteSize": bytes.count,
      "modifiedAt": nil,
    ]
  }

  private func coordinatedRead<T>(_ url: URL, read: (URL) throws -> T) rethrows -> T? {
    let didAccess = url.startAccessingSecurityScopedResource()
    defer {
      if didAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }
    var result: T?
    var coordinationError: NSError?
    NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableUrl in
      result = try? read(readableUrl)
    }
    return result
  }

  private func releaseSources(sourceRefs: [String], handles: [String]) {
    for sourceRef in sourceRefs {
      if let url = URL(string: sourceRef), url.isFileURL {
        try? FileManager.default.removeItem(at: url)
      }
    }
    for handle in handles {
      retryHandles.removeValue(forKey: handle)
    }
  }

  private func cacheFileUrl() -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("coupon-keeper-selected", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory.appendingPathComponent("\(UUID().uuidString).image")
  }

  private var rootViewController: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }?
      .rootViewController
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

private struct RetryableSource {
  let url: URL
  let sourceType: String
  let displayName: String
}
