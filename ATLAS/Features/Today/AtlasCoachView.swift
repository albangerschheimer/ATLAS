import SwiftUI

struct AtlasCoachView: View {
    let context: AtlasCoachContext
    let insights: [AtlasCoachInsight]
    @State private var question = ""
    @State private var messages: [CoachMessage] = []
    @State private var isResponding = false
    @State private var aiAvailability = AtlasAIAvailability.checking

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    aiStatusCard
                    ForEach(insights) { insight in insightCard(insight) }
                    ForEach(messages) { message in bubble(message) }
                    if isResponding { ProgressView("ATLAS réfléchit sur l’appareil…").font(.caption) }
                }.padding()
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Demande quelque chose au coach", text: $question, axis: .vertical)
                        .textFieldStyle(.roundedBorder).lineLimit(1...3)
                    Button("Envoyer", systemImage: "arrow.up.circle.fill") { ask() }
                        .labelStyle(.iconOnly).font(.title2).disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isResponding)
                }.padding().background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Coach ATLAS")
        .navigationBarTitleDisplayMode(.inline)
        .task { aiAvailability = AtlasOnDeviceCoach.availability() }
    }

    private var aiStatusCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: aiAvailability.usesAppleIntelligence ? "apple.intelligence" : "gearshape.2.fill")
                .foregroundStyle(aiAvailability.usesAppleIntelligence ? AtlasTheme.accent : .secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(aiAvailability.title).font(.subheadline.bold())
                Text(aiAvailability.detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func insightCard(_ insight: AtlasCoachInsight) -> some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: 7) {
                Label(insight.title, systemImage: insight.priority == .important ? "exclamationmark.triangle.fill" : "sparkles")
                    .font(.headline).foregroundStyle(insight.priority == .important ? AtlasTheme.warning : AtlasTheme.accent)
                Text(insight.message)
                if let action = insight.action { Text(action).font(.caption.bold()).foregroundStyle(AtlasTheme.accent) }
            }
        }
    }

    private func bubble(_ message: CoachMessage) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding(12)
                .background(message.isUser ? AtlasTheme.accent : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(message.isUser ? .white : .primary)
            if let source = message.source {
                Text(source).font(.caption2).foregroundStyle(.tertiary).padding(.horizontal, 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }

    private func ask() {
        let value = question.trimmingCharacters(in: .whitespacesAndNewlines)
        question = ""
        messages.append(.init(text: value, isUser: true, source: nil))
        isResponding = true
        Task {
            let generated = await AtlasOnDeviceCoach.answer(question: value, context: context, insights: insights)
            let answer = generated ?? AtlasCoachEngine.fallbackAnswer(to: value, insights: insights)
            let source = generated == nil ? "Moteur de règles ATLAS" : "Apple Intelligence · sur l’appareil"
            await MainActor.run { messages.append(.init(text: answer, isUser: false, source: source)); isResponding = false }
        }
    }
}

private struct CoachMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let source: String?
}
