//
//  SupabaseStorageService.swift
//  Spliteasy
//

import Foundation
import UIKit
import Supabase

struct SupabaseReceiptUploadResult {
    let url: String
    let storagePath: String
}

final class SupabaseStorageService {
    static let shared = SupabaseStorageService()

    private let client: SupabaseClient
    private let profileBucket = "profile-pictures"
    private let receiptBucket = "Receipts"

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://ojjnkmorgesubvswzqff.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qam5rbW9yZ2VzdWJ2c3d6cWZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMzA2OTYsImV4cCI6MjA5MTcwNjY5Nn0.eI5gbrCjgDy6JXnBcP_V1Ep02IfgH8CLRM-pcNDMpXo"
        )
    }

    private func resizedImageIfNeeded(_ image: UIImage, maxDimension: CGFloat = 1600) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func normalizedJPEGData(
        from image: UIImage,
        compression: CGFloat = 0.60,
        maxDimension: CGFloat = 1600
    ) -> Data? {
        let resized = resizedImageIfNeeded(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compression)
    }

    private func publicURLString(bucket: String, path: String) async throws -> String {
        let url = try await client.storage
            .from(bucket)
            .getPublicURL(path: path)
        return url.absoluteString
    }

    func storagePath(fromReceiptURL urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let marker = "/storage/v1/object/public/\(receiptBucket)/"
        if let range = url.absoluteString.range(of: marker) {
            return String(url.absoluteString[range.upperBound...])
        }
        return nil
    }

    func uploadProfile(
        image: UIImage,
        userId: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let data = normalizedJPEGData(from: image, compression: 0.65, maxDimension: 1200) else {
            print("❌ Profile image conversion failed")
            completion(nil)
            return
        }

        let fileName = "\(UUID().uuidString).jpg"
        let path = "profiles/\(userId)/\(fileName)"

        Task {
            do {
                _ = try await client.storage
                    .from(profileBucket)
                    .upload(
                        path,
                        data: data,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )

                let urlString = try await publicURLString(bucket: profileBucket, path: path)
                completion(urlString)
            } catch {
                print("❌ Profile upload failed localized:", error.localizedDescription)
                print("❌ Profile upload failed full:", error)
                completion(nil)
            }
        }
    }

    func uploadReceipt(
        image: UIImage,
        expenseId: String,
        userId: String,
        completion: @escaping (SupabaseReceiptUploadResult?) -> Void
    ) {
        guard let data = normalizedJPEGData(from: image, compression: 0.58, maxDimension: 1800) else {
            print("❌ Receipt image conversion failed")
            completion(nil)
            return
        }

        let path = "receipts/\(userId)/\(expenseId).jpg"

        Task {
            do {
                _ = try await client.storage
                    .from(receiptBucket)
                    .upload(
                        path,
                        data: data,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )

                let urlString = try await publicURLString(bucket: receiptBucket, path: path)
                completion(SupabaseReceiptUploadResult(url: urlString, storagePath: path))
            } catch {
                print("❌ Receipt upload failed localized:", error.localizedDescription)
                print("❌ Receipt upload failed full:", error)
                completion(nil)
            }
        }
    }

    func deleteReceipt(
        storagePath: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !storagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(true)
            return
        }

        Task {
            do {
                try await client.storage
                    .from(receiptBucket)
                    .remove(paths: [storagePath])
                completion(true)
            } catch {
                print("❌ Receipt delete failed localized:", error.localizedDescription)
                print("❌ Receipt delete failed full:", error)
                completion(false)
            }
        }
    }
}
