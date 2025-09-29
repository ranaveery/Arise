import SwiftUI

struct SkillXP: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let level: Int
    let xp: Int
    
    var xpProgress: Double {
        min(Double(xp % 1000) / 1000.0, 1.0)
    }
}

struct Rank: Identifiable {
    let id: Int
    let name: String
    let emblemName: String
    let requiredXP: Double
    let subtitle: String
    let themeColors: [Color]
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let index: Int
    var unlocked: Bool = false
    var title: String
    var imageName: String
    var description: String
    var quote: String
    var unlockedDate: Date?
}
