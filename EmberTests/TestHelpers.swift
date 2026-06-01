import Foundation
@testable import Ember

struct FixedClock: EmberClock {
    let now: Date
}
