//
//  ImagePicker.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/27/26.
//

//
//  ImagePicker.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/27/26.
//

import SwiftUI

#if canImport(UIKit) && canImport(PhotosUI)
import UIKit
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }
            guard provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    self.parent.image = object as? UIImage
                }
            }
        }
    }
}

#else

struct ImagePicker: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppPalette.accentMid)

            Text("Image picker is only available on iOS.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#endif
