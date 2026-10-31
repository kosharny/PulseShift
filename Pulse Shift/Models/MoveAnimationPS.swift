struct MoveAnimationPS {
    let groups: [[GameEventPS]]

    init(events: [GameEventPS]) {
        let grouped = Dictionary(grouping: events, by: \.group)
        var result: [[GameEventPS]] = []
        for key in grouped.keys.sorted() {
            guard let group = grouped[key] else { continue }
            if group.count == 1, let event = group.first, event.kind == .move,
               let previous = result.last, previous.count == 1, let run = previous.first,
               run.kind == .move, run.entityID == event.entityID, run.to == event.from,
               (run.to.row - run.from.row).signum() == (event.to.row - event.from.row).signum(),
               (run.to.column - run.from.column).signum() == (event.to.column - event.from.column).signum() {
                var extended = result.removeLast()[0]
                extended.to = event.to
                result.append([extended])
            } else { result.append(group) }
        }
        groups = result
    }

}
