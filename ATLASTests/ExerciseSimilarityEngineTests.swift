import XCTest
@testable import ATLAS

final class ExerciseSimilarityEngineTests: XCTestCase {
    func testSameMuscleAndPatternRanksAhead() {
        let source = ExerciseRecord(nameFrench: "Tirage vertical", nameEnglish: "Lat Pulldown", primaryMuscles: [.lats], secondaryMuscles: [.biceps], equipment: .cable, category: .hypertrophy)
        let close = ExerciseRecord(nameFrench: "Tractions assistées", nameEnglish: "Assisted Pull-Up", primaryMuscles: [.lats], secondaryMuscles: [.biceps], equipment: .machine, category: .hypertrophy)
        let distant = ExerciseRecord(nameFrench: "Curl", nameEnglish: "Curl", primaryMuscles: [.biceps], equipment: .dumbbell, category: .hypertrophy)
        let results = ExerciseSimilarityEngine.recommendations(for: source, among: [distant, close])
        XCTAssertEqual(results.first?.exercise.id, close.id)
        XCTAssertGreaterThan(results.first?.percentage ?? 0, 80)
    }
}
