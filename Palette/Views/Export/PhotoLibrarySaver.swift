import Foundation
#if canImport(UIKit)
import UIKit
import Photos

enum PhotoSaveResult {
    case saved
    case denied
    case failed(Error)
}

enum PhotoLibrarySaver {
    static func saveImage(at url: URL) async -> PhotoSaveResult {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return .failed(NSError(
                domain: "PhotoLibrarySaver",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not load image"]
            ))
        }
        return await save(image: image)
    }

    static func save(image: UIImage) async -> PhotoSaveResult {
        let status = await requestAddOnlyAuthorization()
        guard status == .authorized || status == .limited else {
            return .denied
        }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    continuation.resume(returning: .saved)
                } else if let error {
                    continuation.resume(returning: .failed(error))
                } else {
                    continuation.resume(returning: .failed(NSError(
                        domain: "PhotoLibrarySaver",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown save error"]
                    )))
                }
            })
        }
    }

    private static func requestAddOnlyAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
#endif
