import SwiftUI
import PhotosUI

/// Friendly card shown right after a class auto-posts, inviting the member to
/// attach a photo (and optional caption) to their workout post.
struct FeedPhotoPromptCard: View {
    let feed: FeedStore
    let post: FeedPost

    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var caption: String = ""
    @State private var showCamera: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.featuredText)
                    .frame(width: 40, height: 40)
                    .background(Theme.featuredFill)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nice work!")
                        .font(.headline)
                        .foregroundStyle(Theme.featuredText)
                    Text("Your \(post.displayClassName) post is live. Add a photo?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.featuredTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if let pickedImageData, let image = UIImage(data: pickedImageData) {
                Theme.featuredFill
                    .frame(height: 180)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 12))

                TextField("Add a caption (optional)", text: $caption, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Theme.featuredText)
                    .tint(Theme.featuredText)
                    .lineLimit(1...3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.featuredFill)
                    )
            }

            HStack(spacing: 12) {
                if pickedImageData == nil {
                    if CameraPicker.isAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            promptActionLabel("Camera", icon: "camera.fill")
                        }
                    }

                    PhotosPicker(selection: $pickedItem, matching: .images) {
                        promptActionLabel("Library", icon: "photo.badge.plus")
                    }
                } else {
                    Button {
                        Task {
                            if let pickedImageData {
                                await feed.attachPhoto(imageData: pickedImageData, caption: caption)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if feed.isUploadingPhoto {
                                ProgressView()
                                    .tint(Theme.featuredBackground)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text(feed.isUploadingPhoto ? "Posting…" : "Post Photo")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Theme.featuredBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.featuredText)
                        .clipShape(.rect(cornerRadius: 12))
                    }
                    .disabled(feed.isUploadingPhoto)
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        feed.dismissPhotoPrompt()
                    }
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.featuredTextSecondary)
                        .frame(width: 72)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.featuredFill)
                        )
                }
                .disabled(feed.isUploadingPhoto)
            }
        }
        .padding(16)
        .featuredCard()
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    pickedImageData = data
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        pickedImageData = data
                    }
                }
            }
        }
    }

    private func promptActionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.featuredBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.featuredText)
            .clipShape(.rect(cornerRadius: 12))
    }
}
