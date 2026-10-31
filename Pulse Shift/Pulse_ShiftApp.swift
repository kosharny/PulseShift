import SwiftUI

@main struct PulseShiftAppPS: App {
    @State private var model = PulseShiftViewModelPS()
    var body: some Scene { WindowGroup { RootViewPS().environment(model) } }
}
