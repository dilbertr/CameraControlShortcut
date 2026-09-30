import SwiftUI

/// The icon-on-dark screen matching the app's launch screen (`UILaunchScreen` in
/// App/Info.plist). The icon sits exactly where the launch screen puts it.
struct SplashBackdrop<Caption: View>: View {
    private let caption: Caption

    init(@ViewBuilder caption: () -> Caption) {
        self.caption = caption()
    }

    var body: some View {
        ZStack {
            Color("SplashBackground")
            Image("SplashIcon")
                .overlay(alignment: .bottom) {
                    caption
                        .fixedSize()
                        .offset(y: 44)
                }
        }
        .ignoresSafeArea()
    }
}

extension SplashBackdrop where Caption == EmptyView {
    init() {
        self.init { EmptyView() }
    }
}
