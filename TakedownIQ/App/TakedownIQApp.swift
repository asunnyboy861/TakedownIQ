import SwiftUI
import SwiftData

@main
struct TakedownIQApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            UserProfile.self, BreakdownResult.self, EventObservation.self,
            DrillItem.self, MatchRecord.self, WeighIn.self, StreakState.self, ChatMessage.self
        ])
        do {
            let config = ModelConfiguration("TakedownIQ", schema: schema, cloudKitDatabase: .private("iCloud.com.zzoutuo.TakedownIQ"))
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let config = ModelConfiguration("TakedownIQ", schema: schema)
            container = (try? ModelContainer(for: schema, configurations: [config])) ?? {
                fatalError("Unable to create ModelContainer: \(error)")
            }()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(container)
                .environmentObject(FilmViewModel())
                .tint(.volt)
                .preferredColorScheme(.dark)
        }
    }
}
