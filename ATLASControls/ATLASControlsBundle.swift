import AppIntents
import SwiftUI
import WidgetKit

@main
struct ATLASControlsBundle: WidgetBundle {
    var body: some Widget {
        StartWorkoutControl()
        DailyCheckInControl()
        LogWeightControl()
        StartRestControl()
    }
}

@available(iOSApplicationExtension 18.0, *)
private struct StartWorkoutControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.alban.atlas.start-workout") {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "atlas://train")!)) {
                Label("Commencer", systemImage: "play.fill")
            }
        }
        .displayName("Commencer une séance")
        .description("Ouvre ATLAS directement dans Train.")
    }
}

@available(iOSApplicationExtension 18.0, *)
private struct DailyCheckInControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.alban.atlas.daily-check-in") {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "atlas://today")!)) {
                Label("Check-in", systemImage: "checkmark.circle.fill")
            }
        }
        .displayName("Check-in ATLAS")
        .description("Ouvre le score et le coach du jour.")
    }
}

@available(iOSApplicationExtension 18.0, *)
private struct LogWeightControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.alban.atlas.log-weight") {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "atlas://progress/measurements")!)) {
                Label("Poids", systemImage: "scalemass.fill")
            }
        }
        .displayName("Ajouter un poids")
        .description("Ouvre les mesures corporelles ATLAS.")
    }
}

@available(iOSApplicationExtension 18.0, *)
private struct StartRestControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.alban.atlas.rest-timer") {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "atlas://rest?seconds=120")!)) {
                Label("Repos 2 min", systemImage: "timer")
            }
        }
        .displayName("Repos 2 minutes")
        .description("Lance le timer de repos ATLAS.")
    }
}
