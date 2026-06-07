import Foundation

public struct TaskState: Identifiable {
    public var id = UUID()
    public var name: String
    public var progress: Double = 0.0
    public var eta: String = ""
    public var status: String = "Idle"
    public var isRunning: Bool = false
    public var outputEstimatedSize: String = ""
    
    public init(name: String) {
        self.name = name
    }
}
