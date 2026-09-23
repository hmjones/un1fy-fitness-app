import SwiftUI

/// Sheet that lets a member share one of their own activities to socials.
/// Swipe between three designed templates (photo overlay, logo card, stats
/// card), then export the selected one as a high-resolution image through
/// the standard iOS share sheet.
struct ShareActivityView: View {
    let post: FeedPost
    let streak: Int
    let totalClasses: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: ShareTemplate
    @State private var loadedPhoto: UIImage?
    @State private var renderedShareImage: UIImage?
    @State private var isShareSheetPresented: Bool = false
    @State private var shareTapCount: Int = 0

    init(post: FeedPost, streak: Int, totalClasses: Int) {
        self.post = post
        self.streak = streak
        self.totalClasses = totalClasses
        _selectedTemplate = State(initialValue: post.photoUrl == nil ? .logo : .photo)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            templatePager
            dotIndicator
            shareButton
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .sensoryFeedback(.selection, trigger: selectedTemplate)
        .sensoryFeedback(.impact(weight: .medium), trigger: shareTapCount)
        .sheet(isPresented: $isShareSheetPresented) {
            if let renderedShareImage {
                ActivityShareSheet(items: [renderedShareImage])
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
        }
        .task {
            await loadPhoto()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Share Activity")
                .font(.headline)
                .foregroundStyle(Theme.cream)
            Text(selectedTemplate.title)
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(Theme.creamTertiary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: selectedTemplate)
        }
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    private var templatePager: some View {
        GeometryReader { geo in
            let scale = min(
                (geo.size.width - 56) / SharePalette.cardSize.width,
                (geo.size.height - 24) / SharePalette.cardSize.height
            )

            TabView(selection: $selectedTemplate) {
                ForEach(ShareTemplate.allCases) { template in
                    templateView(template)
                        .scaleEffect(scale)
                        .frame(
                            width: SharePalette.cardSize.width * scale,
                            height: SharePalette.cardSize.height * scale
                        )
                        .clipShape(.rect(cornerRadius: 18, style: .continuous))
                        .shadow(color: Theme.cardShadow, radius: 16, x: 0, y: 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(template)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .padding(.vertical, 8)
    }

    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(ShareTemplate.allCases) { template in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedTemplate = template
                    }
                } label: {
                    Capsule()
                        .fill(template == selectedTemplate ? Theme.cream : Theme.creamTertiary)
                        .frame(width: template == selectedTemplate ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: selectedTemplate)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(.top, 4)
    }

    private var shareButton: some View {
        Button {
            presentShareSheet()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                Text("Share")
                    .font(.headline)
            }
            .foregroundStyle(Theme.buttonForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.buttonBackground)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func templateView(_ template: ShareTemplate) -> some View {
        switch template {
        case .photo:
            SharePhotoTemplateView(post: post, photo: loadedPhoto)
        case .logo:
            ShareLogoTemplateView(post: post)
        case .stats:
            ShareStatsTemplateView(post: post, streak: streak, totalClasses: totalClasses)
        }
    }

    /// Renders the selected template at 3x (1080 x 1350 px) and opens the
    /// system share sheet with the result.
    private func presentShareSheet() {
        shareTapCount += 1
        let renderer = ImageRenderer(content: templateView(selectedTemplate))
        renderer.scale = 3
        guard let image = renderer.uiImage else {
            print("[UN1FY] Share image render failed")
            return
        }
        renderedShareImage = image
        isShareSheetPresented = true
    }

    /// Downloads the activity's attached photo for the photo template.
    private func loadPhoto() async {
        guard let photoUrl = post.photoUrl, let url = URL(string: photoUrl) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            print("[UN1FY] Share photo download failed")
            return
        }
        loadedPhoto = UIImage(data: data)
    }
}
