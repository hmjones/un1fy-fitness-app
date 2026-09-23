import Foundation

nonisolated enum MindbodyConnectionState: String, Sendable {
    case disconnected
    case connecting
    case connected
}
