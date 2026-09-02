import SwiftUI
import UniformTypeIdentifiers

enum AtlasExportFormat: String, CaseIterable, Identifiable {
    case json
    case csv

    var id: Self { self }

    var contentType: UTType {
        switch self {
        case .json: .json
        case .csv: .commaSeparatedText
        }
    }

    var fileExtension: String { rawValue }

    var title: String {
        switch self {
        case .json: "Export complet JSON"
        case .csv: "Historique CSV"
        }
    }

    var detail: String {
        switch self {
        case .json: "Exercices, programmes, brouillons, séances, notes et métriques."
        case .csv: "Une ligne par série terminée, pratique pour Numbers ou Excel."
        }
    }

    var systemImage: String {
        switch self {
        case .json: "curlybraces.square"
        case .csv: "tablecells"
        }
    }
}

struct AtlasExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json, .commaSeparatedText]
    }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
