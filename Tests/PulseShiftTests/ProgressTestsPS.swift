import XCTest
@testable import PulseShiftEnginePS

final class ProgressTestsPS: XCTestCase {
    func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text) ?? Date(timeIntervalSince1970: 0) }
    func testDailyStreakAcrossMonthYearAndMissedDay() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let service = DailyChallengeServicePS(calendar: calendar)
        let days: Set<String> = ["2025-12-30", "2025-12-31", "2026-01-01"]
        XCTAssertEqual(service.streak(completedDays: days, today: date("2026-01-01T12:00:00Z")), 3)
        XCTAssertEqual(service.streak(completedDays: days, today: date("2026-01-02T12:00:00Z")), 3)
        XCTAssertEqual(service.streak(completedDays: days, today: date("2026-01-03T12:00:00Z")), 0)
    }
    func testDailyStreakAcrossDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let service = DailyChallengeServicePS(calendar: calendar)
        XCTAssertEqual(service.streak(completedDays: ["2026-03-07", "2026-03-08", "2026-03-09"], today: date("2026-03-09T16:00:00Z")), 3)
    }
    @MainActor func testDiskPersistenceAndRewardIdempotency() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.store")
        let result = GameResultPS(moves: 1, par: 1, chain: 1, seconds: 4, usedHint: false, usedUndo: false)
        var persistence: PersistenceServicePS? = PersistenceServicePS(storeURL: url)
        XCTAssertNil(persistence?.errorMessage)
        XCTAssertEqual(persistence?.record(key: "level-1", levelID: 1, result: result, reward: 10), 35)
        XCTAssertEqual(persistence?.record(key: "level-1", levelID: 1, result: result, reward: 10), 0)
        XCTAssertEqual(persistence?.record(key: "daily-2026-09-13", levelID: 25, result: result, reward: 75), 100)
        XCTAssertEqual(persistence?.record(key: "daily-2026-09-13", levelID: 25, result: result, reward: 75), 0)
        persistence = nil
        let reopened = PersistenceServicePS(storeURL: url)
        XCTAssertNil(reopened.errorMessage)
        XCTAssertEqual(reopened.records.count, 2)
        XCTAssertEqual(reopened.records.first { $0.key == "level-1" }?.stars, 3)
        XCTAssertEqual(reopened.player.energy, 135)
        reopened.resetStatistics(); XCTAssertEqual(reopened.records.count, 2)
        reopened.resetProgress(); XCTAssertTrue(reopened.records.isEmpty)
    }
    @MainActor func testThemeAndSettingsPersist() throws {
        let name = "PulseShiftTestsPS.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let original = SettingsPS(defaults: defaults)
        original.themeID = "frost"; original.haptics = false; original.launched = true
        let restored = SettingsPS(defaults: defaults)
        XCTAssertEqual(restored.themeID, "frost"); XCTAssertFalse(restored.haptics); XCTAssertTrue(restored.launched)
    }
    @MainActor func testStarsImproveWithoutLosingPerfectRecord() {
        let service = PersistenceServicePS(inMemory: true)
        let perfect = GameResultPS(moves: 1, par: 1, chain: 1, seconds: 3, usedHint: false, usedUndo: false)
        let weaker = GameResultPS(moves: 4, par: 1, chain: 1, seconds: 10, usedHint: true, usedUndo: true)
        service.record(key: "level-1", levelID: 1, result: perfect, reward: 10)
        XCTAssertEqual(service.record(key: "level-1", levelID: 1, result: weaker, reward: 10), 0)
        XCTAssertEqual(service.records.first?.stars, 3); XCTAssertEqual(service.records.first?.bestMoves, 1); XCTAssertTrue(service.records.first?.perfect == true)
    }
}

extension ProgressTestsPS {
    @MainActor func testMissingAudioAndDisabledHapticsAreSafe() async {
        let audio = AudioServicePS()
        audio.play("missing-test-asset", enabled: true)
        audio.setMusic(enabled: true)
        audio.pause()
        HapticServicePS().play(.activate, enabled: false)
        let success = await MockAdServicePS().showRewardedHint()
        XCTAssertFalse(success)
    }
}

extension ProgressTestsPS {
    @MainActor func testEveryGameplayPreferencePersists() throws {
        let name = "PulseShiftPreferencesPS.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = SettingsPS(defaults: defaults)
        settings.sound = false
        settings.music = false
        settings.haptics = false
        settings.reducedEffects = true
        settings.tutorialTips = false
        let restored = SettingsPS(defaults: defaults)
        XCTAssertFalse(restored.sound)
        XCTAssertFalse(restored.music)
        XCTAssertFalse(restored.haptics)
        XCTAssertTrue(restored.reducedEffects)
        XCTAssertFalse(restored.tutorialTips)
    }
}
