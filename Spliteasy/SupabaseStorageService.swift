//
//  SupabaseStorageService.swift
//  Spliteasy
//

import Foundation
import UIKit
import Supabase

final class SupabaseStorageService {
    static let shared = SupabaseStorageService()

    private let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://ojjnkmorgesubvswzqff.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qam5rbW9yZ2VzdWJ2c3d6cWZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMzA2OTYsImV4cCI6MjA5MTcwNjY5Nn0.eI5gbrCjgDy6JXnBcP_V1Ep02IfgH8CLRM-pcNDMpXo"
        )
    }

    private func normalizedJPEGData(
        from image: UIImage,
        compression: CGFloat = 0.8
    ) -> Data? {
        image.jpegData(compressionQuality: compression)
    }

    func uploadProfile(
        image: UIImage,
        userId: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let data = normalizedJPEGData(from: image, compression: 0.8) else {
            print("❌ Profile image conversion failed")
            completion(nil)
            return
        }

        let fileName = "\(UUID().uuidString).jpg"
        let path = "profiles/\(userId)/\(fileName)"
        print("🚀 Uploading profile to path:", path)
        print("🚀 Bucket:", "profile-pictures")

        Task {
            do {
                _ = try await client.storage
                    .from("profile-pictures")
                    .upload(
                        path,
                        data: data,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )

                let url = try await client.storage
                    .from("profile-pictures")
                    .getPublicURL(path: path)

                print("✅ Profile upload success")
                print("🌍 Profile URL:", url.absoluteString)
                completion(url.absoluteString)
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
        completion: @escaping (String?) -> Void
    ) {
        guard let data = normalizedJPEGData(from: image, compression: 0.8) else {
            print("❌ Receipt image conversion failed")
            completion(nil)
            return
        }

        let path = "receipts/\(userId)/\(expenseId).jpg"
        print("🚀 Uploading receipt to path:", path)
        print("🚀 Bucket:", "Receipts")

        Task {
            do {
                _ = try await client.storage
                    .from("Receipts")
                    .upload(
                        path,
                        data: data,
                        options: FileOptions(
                            contentType: "image/jpeg",
                            upsert: true
                        )
                    )

                let url = try await client.storage
                    .from("Receipts")
                    .getPublicURL(path: path)

                print("✅ Receipt upload success")
                print("🌍 Receipt URL:", url.absoluteString)
                completion(url.absoluteString)
            } catch {
                print("❌ Receipt upload failed localized:", error.localizedDescription)
                print("❌ Receipt upload failed full:", error)
                completion(nil)
            }
        }
    }
}
