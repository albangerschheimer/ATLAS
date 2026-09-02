import SwiftData
import SwiftUI
import UIKit

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var selection = Self.initialTab
    @State private var systemRestEnd: Date?

    private static var initialTab: Int {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--promo-progress") { return 3 }
        if arguments.contains("--promo-training") { return 1 }
        return 0
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Jour", systemImage: "sun.max.fill") }
                .tag(0)

            TrainHomeView()
                .tabItem { Label("Séance", systemImage: "dumbbell.fill") }
                .tag(1)

            SportsCalendarView()
                .tabItem { Label("Calendrier", systemImage: "calendar") }
                .tag(2)

            TrainingProgressView()
                .tabItem { Label("Progrès", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(AtlasTheme.accent)
        .safeAreaInset(edge: .top) {
            if let systemRestEnd { SystemRestTimerBanner(endDate: systemRestEnd) { self.systemRestEnd = nil }.padding(.horizontal) }
        }
        .onOpenURL(perform: handleControlURL)
        .onReceive(NotificationCenter.default.publisher(for: .atlasSelectTrain)) { _ in
            selection = 1
        }
        .task {
            feedback.run(action: "L’initialisation des exercices") {
                try SeedData.insertIfNeeded(into: modelContext)
            }
        }
        .alert(item: $feedback.failure) { failure in
            if failure.canRetry {
                Alert(
                    title: Text(failure.title),
                    message: Text(failure.message),
                    primaryButton: .default(Text("Réessayer"), action: feedback.retry),
                    secondaryButton: .cancel(Text("Plus tard"), action: feedback.dismissFailure)
                )
            } else {
                Alert(
                    title: Text(failure.title),
                    message: Text(failure.message),
                    dismissButton: .default(Text("OK"), action: feedback.dismissFailure)
                )
            }
        }
    }

    private func handleControlURL(_ url: URL) {
        switch url.host {
        case "train": selection = 1
        case "progress": selection = 3
        case "rest":
            let seconds = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "seconds" })?.value.flatMap(Double.init) ?? 120
            systemRestEnd = .now.addingTimeInterval(seconds)
            selection = 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        default: selection = 0
        }
    }
}

extension Notification.Name {
    static let atlasSelectTrain = Notification.Name("atlas.selectTrain")
}

private struct SystemRestTimerBanner: View {
    let endDate: Date
    let onStop: () -> Void
    @State private var notifiedThirty = false
    @State private var notifiedEnd = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(endDate.timeIntervalSince(context.date).rounded(.up)))
            HStack {
                Label("REST", systemImage: "timer").font(.caption.bold())
                Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond))).font(.headline.monospacedDigit())
                Spacer()
                Button(remaining == 0 ? "Fermer" : "Skip", action: onStop).buttonStyle(.bordered)
            }
            .padding(10).background(.ultraThickMaterial, in: Capsule()).shadow(radius: 8)
            .onChange(of: remaining) { _, value in
                if value <= 30, value > 0, !notifiedThirty { notifiedThirty = true; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                if value == 0, !notifiedEnd { notifiedEnd = true; UINotificationFeedbackGenerator().notificationOccurred(.success) }
            }
        }
    }
}
