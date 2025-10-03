import SwiftUI

let skillLevelThresholds: [Int] = [
    0,    // Level 1
    150,  // Level 2
    350,  // Level 3
    500,  // Level 4
    850,  // Level 5
    1150, // Level 6
    1500, // Level 7
    2000, // Level 8
    2500, // Level 9
    3350  // Level 10
]

struct SkillXP: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let level: Int
    let xp: Int
    
    var xpProgress: Double {
        min(Double(xp) / Double(currentLevelCap), 1.0)
    }

    var currentLevelCap: Int {
        skillLevelThresholds[min(level, skillLevelThresholds.count - 1)]
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
