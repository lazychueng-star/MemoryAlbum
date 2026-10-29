import Nuke
import SwiftUI

@main
struct MemoryAlbumApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

private struct AppRootView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 32 / 255, green: 38 / 255, blue: 58 / 255),
                    Color(red: 23 / 255, green: 24 / 255, blue: 32 / 255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "house.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Color(red: 242 / 255, green: 168 / 255, blue: 91 / 255))
                    .accessibilityHidden(true)

                Text("app.name")
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(Color(red: 231 / 255, green: 214 / 255, blue: 180 / 255))

                Text("app.subtitle")
                    .font(.system(.body, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 157 / 255, green: 184 / 255, blue: 216 / 255))
            }
            .padding(32)
        }
        .preferredColorScheme(.dark)
    }
}
