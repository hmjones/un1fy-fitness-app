import SwiftUI
import UIKit

/// Wraps the system `UIActivityViewController` so a rendered share image can
/// be posted to Instagram, Messages, saved to Photos, etc.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
