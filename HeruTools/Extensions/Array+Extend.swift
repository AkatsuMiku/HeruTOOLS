import Foundation

extension Array {
    mutating func extend(_ elements: [Element]) {
        self.append(contentsOf: elements)
    }
}
