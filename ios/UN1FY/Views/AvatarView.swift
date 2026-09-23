import SwiftUI

/// Circular member avatar: shows the profile photo when one exists, otherwise
/// the neutral-gray initials circle used across the app. Resolves its own photo URL
/// from `AvatarStore` inside `body`, so every avatar updates itself the moment
/// the shared photo directory loads or changes — independent of whether its
/// parent view re-renders. Images come from the shared `AvatarImageLoader`
/// cache, so each photo downloads once no matter how many places it appears.
struct AvatarView: View {
    let clientId: Int?
    let initials: String
    let size: CGFloat
    var fill: Color = Theme.neutralFill
    var accent: Color = Theme.creamSecondary

    private var photoUrl: URL? {
        AvatarStore.shared.url(for: clientId)
    }

    var body: some View {
        let url = photoUrl
        Circle()
            .fill(fill)
            .frame(width: size, height: size)
            .overlay {
                ZStack {
                    initialsText
                    if let image = AvatarImageLoader.shared.image(for: url) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                }
            }
            .clipShape(Circle())
            .task(id: url) {
                if let url {
                    await AvatarImageLoader.shared.load(url)
                }
            }
    }

    private var initialsText: some View {
        Text(initials)
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(accent)
            .minimumScaleFactor(0.6)
    }
}
