import SwiftData
import SwiftUI

@main
struct MyApp: App {
    @State private var hasFinishedLaunch = false

    private let modelContainer: ModelContainer = {
        let schema = Schema([Team.self, Player.self, Match.self, PlayerMatchStat.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create the local StatTracker database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasFinishedLaunch {
                    ContentView()
                        .transition(.opacity)
                } else {
                    LoadingScreen()
                        .transition(.opacity)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut(duration: 0.55)) {
                    hasFinishedLaunch = true
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
