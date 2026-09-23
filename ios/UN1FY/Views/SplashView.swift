import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.96

    var body: some View {
        ZStack {
            Color.black

            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 56)
                .opacity(opacity)
                .scaleEffect(scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

#Preview {
    SplashView()
}
