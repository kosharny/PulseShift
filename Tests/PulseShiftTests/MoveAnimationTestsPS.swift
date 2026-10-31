import XCTest
@testable import PulseShiftEnginePS

final class MoveAnimationTestsPS: XCTestCase {
    func testStraightTravelKeepsPortalAndDirectionChangesInOrder() {
        let events: [GameEventPS] = [
            event(.move, from: .init(row: 0, column: 0), to: .init(row: 0, column: 1), group: 0),
            event(.move, from: .init(row: 0, column: 1), to: .init(row: 0, column: 2), group: 1),
            event(.portal, from: .init(row: 0, column: 2), to: .init(row: 4, column: 4), group: 2),
            event(.move, from: .init(row: 4, column: 4), to: .init(row: 3, column: 4), group: 3),
            event(.redirect, from: .init(row: 3, column: 4), to: .init(row: 3, column: 4), group: 4),
            event(.move, from: .init(row: 3, column: 4), to: .init(row: 3, column: 3), group: 5),
            event(.exit, from: .init(row: 3, column: 3), to: .init(row: 3, column: 2), group: 6)
        ]
        let groups = MoveAnimationPS(events: events).groups
        XCTAssertEqual(groups.count, 6)
        XCTAssertEqual(groups[0][0].from, events[0].from)
        XCTAssertEqual(groups[0][0].to, events[1].to)
        XCTAssertEqual(groups.compactMap { $0.first?.kind }, [.move, .portal, .move, .redirect, .move, .exit])
    }

    func testConcurrentEventsAndReversedMovementStaySeparate() {
        let start = BoardPositionPS(row: 2, column: 2)
        let next = BoardPositionPS(row: 2, column: 3)
        let events = [
            event(.move, from: start, to: next, group: 0),
            event(.move, from: next, to: start, group: 1),
            event(.magnet, from: start, to: next, group: 2),
            GameEventPS(kind: .magnet, entityID: "b", from: next, to: start, group: 2)
        ]
        let groups = MoveAnimationPS(events: events).groups
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[2].count, 2)
        XCTAssertEqual(groups[0][0].to, next)
        XCTAssertEqual(groups[1][0].to, start)
    }

    private func event(_ kind: GameEventKindPS, from: BoardPositionPS, to: BoardPositionPS, group: Int) -> GameEventPS {
        .init(kind: kind, entityID: "a", from: from, to: to, group: group)
    }
}
