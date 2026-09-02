import SwiftUI

enum AtlasTheme {
    // Primitive → semantic tokens. The interface stays monochrome; indigo marks action.
    static let accent = Color(red: 0.29, green: 0.36, blue: 0.98)
    static let success = Color(red: 0.18, green: 0.67, blue: 0.44)
    static let warning = Color(red: 0.95, green: 0.57, blue: 0.18)
    static let danger = Color(red: 0.90, green: 0.23, blue: 0.28)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .systemBackground)
    static let outline = Color.primary.opacity(0.075)

    static let cardCornerRadius: CGFloat = 22
    static let compactCornerRadius: CGFloat = 16
    static let screenPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 24
}

extension MuscleGroup {
    /// Stable ATLAS semantic palette: a muscle keeps the same meaning everywhere.
    var atlasColor: Color {
        switch self {
        case .chest: Color(red: 0.92, green: 0.25, blue: 0.34)
        case .back, .lats, .upperBack, .traps, .lowerBack: Color(red: 0.12, green: 0.52, blue: 0.88)
        case .shoulders: Color(red: 0.96, green: 0.55, blue: 0.14)
        case .biceps: Color(red: 0.55, green: 0.35, blue: 0.92)
        case .triceps: Color(red: 0.76, green: 0.25, blue: 0.67)
        case .forearms: Color(red: 0.55, green: 0.42, blue: 0.30)
        case .quadriceps: Color(red: 0.45, green: 0.30, blue: 0.92)
        case .hamstrings: Color(red: 0.20, green: 0.62, blue: 0.62)
        case .glutes, .abductors: Color(red: 0.92, green: 0.30, blue: 0.62)
        case .adductors: Color(red: 0.62, green: 0.38, blue: 0.72)
        case .calves: Color(red: 0.24, green: 0.67, blue: 0.38)
        case .core, .obliques: Color(red: 0.94, green: 0.68, blue: 0.12)
        case .fullBody: AtlasTheme.accent
        }
    }
}

struct AtlasCard<Content: View>: View {
    private let tint: Color?
    @ViewBuilder private var content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(AtlasTheme.surface, in: RoundedRectangle(cornerRadius: AtlasTheme.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AtlasTheme.cardCornerRadius, style: .continuous)
                    .stroke((tint ?? Color.primary).opacity(tint == nil ? 0.07 : 0.18), lineWidth: 0.75)
            }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    var tint: Color = AtlasTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(AtlasTheme.surface, in: RoundedRectangle(cornerRadius: AtlasTheme.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtlasTheme.compactCornerRadius, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 0.75)
        }
    }
}

struct AtlasSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title2.bold())
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline.weight(.semibold))
            }
        }
    }
}

struct AtlasIconBadge: View {
    let systemImage: String
    var tint: Color = AtlasTheme.accent

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct AtlasStatusPill: View {
    let text: String
    let systemImage: String
    var tint: Color = AtlasTheme.accent

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(tint.opacity(0.11), in: Capsule())
    }
}

struct AtlasPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(AtlasTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
