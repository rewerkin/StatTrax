import SwiftUI

struct LoadingScreen: View {
    @AppStorage("appAppearance") private var appAppearance = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image("StatTrackerIconArtwork")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .padding(22)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(.sRGB, red: 0.756, green: 0.999, blue: 0.223, opacity: 1),
                                Color(.sRGB, red: 0.204, green: 0.780, blue: 0.349, opacity: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 48, style: .continuous)
                    )
                    .shadow(color: .green.opacity(0.25), radius: 24, y: 12)
                    .accessibilityLabel("Stat Tracker app icon")

                Text("STAT TRAX")
					.font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(32)
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    LoadingScreen()
}
