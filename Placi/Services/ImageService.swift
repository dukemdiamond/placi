import UIKit
import Supabase
import Storage

struct ImageService {
    private static let bucket = "post-photos"
    private static let maxLongEdge: CGFloat = 1200

    /// Resize, compress, and upload an image. Returns the storage path.
    static func uploadPostPhoto(image: UIImage, postId: UUID, order: Int) async throws -> String {
        let resized = resize(image: image, maxLongEdge: maxLongEdge)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw ImageServiceError.compressionFailed
        }
        let path = "\(postId.uuidString)/\(order).jpg"
        try await supabase.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        return path
    }

    static func publicURL(for path: String) -> URL? {
        try? supabase.storage.from(bucket).getPublicURL(path: path)
    }

    static func deletePhoto(path: String) async throws {
        try await supabase.storage.from(bucket).remove(paths: [path])
    }

    // MARK: - Helpers

    private static func resize(image: UIImage, maxLongEdge: CGFloat) -> UIImage {
        let size = image.size
        let longEdge = max(size.width, size.height)
        guard longEdge > maxLongEdge else { return image }
        let scale = maxLongEdge / longEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    enum ImageServiceError: LocalizedError {
        case compressionFailed
        var errorDescription: String? { "Failed to compress image for upload." }
    }
}
