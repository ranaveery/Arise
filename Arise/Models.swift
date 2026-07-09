import SwiftUI
import CryptoKit

// MARK: - Constants

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

func calculateSkillLevel(from xp: Int) -> Int {
    for (index, threshold) in skillLevelThresholds.enumerated().reversed() {
        if xp >= threshold { return index + 1 }
    }
    return 1
}

func skillProgress(for xp: Int) -> Double {
    let level = calculateSkillLevel(from: xp)
    let currentThreshold = skillLevelThresholds[level - 1]
    let nextThreshold = level < skillLevelThresholds.count
        ? skillLevelThresholds[level]
        : skillLevelThresholds.last ?? 0
    let range = nextThreshold - currentThreshold
    guard range > 0 else { return 1 }
    return min(max(Double(xp - currentThreshold) / Double(range), 0), 1.0)
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Brand Assets

extension LinearGradient {
    static let brand = LinearGradient(
        colors: [
            Color(red: 84/255, green: 0/255, blue: 232/255),
            Color(red: 236/255, green: 71/255, blue: 1/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shared Constants

let allSkillNames = ["Discipline", "Fitness", "Fuel", "Network", "Resilience", "Wisdom"]

let skillIcons: [String: String] = [
    "Resilience": "brain",
    "Fuel":       "fork.knife",
    "Fitness":    "figure.run",
    "Wisdom":     "book.fill",
    "Discipline": "infinity",
    "Network":    "person.2.fill"
]

// MARK: - Models

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

struct Achievement: Identifiable {
    let id = UUID()
    let index: Int
    var unlocked: Bool = false
    var title: String
    var imageName: String
    var description: String
    var quote: String
    var unlockedDate: String? = nil
}

struct DailyLog: Identifiable, Codable {
    var id: String { date }
    let date: String
    let completedCount: Int
    let xpGained: Int
    let skillXP: [String: Int]
    let streak: Int
    let totalPossibleXP: Int
}

/// Wrapper so `String` does not need a global `Identifiable` conformance.
struct IdentifiedString: Identifiable {
    let id: String
    init(_ value: String) { self.id = value }
    var value: String { id }
}

// MARK: - Ranks

let ranks: [Rank] = [
    Rank(id: 1,  name: "Seeker",       emblemName: "seeker_emblem",       requiredXP: 0,
         subtitle: "Every journey begins with a single step.",
         themeColors: [Color(red: 85/255,  green: 64/255,  blue: 44/255),
                       Color(red: 28/255,  green: 23/255,  blue: 19/255)]),
    Rank(id: 2,  name: "Initiate",     emblemName: "initiate_emblem",     requiredXP: 900,
         subtitle: "Commitment is your first victory.",
         themeColors: [Color(red: 85/255,  green: 85/255,  blue: 85/255),
                       Color(red: 169/255, green: 169/255, blue: 169/255)]),
    Rank(id: 3,  name: "Pioneer",      emblemName: "pioneer_emblem",      requiredXP: 2100,
         subtitle: "Forge new paths, leave a mark.",
         themeColors: [Color(red: 184/255, green: 115/255, blue: 51/255),
                       Color(red: 93/255,  green: 46/255,  blue: 12/255)]),
    Rank(id: 4,  name: "Explorer",     emblemName: "explorer_emblem",     requiredXP: 3000,
         subtitle: "Seek the unknown, learn from everything.",
         themeColors: [Color(red: 153/255, green: 0/255,   blue: 0/255),
                       Color(red: 255/255, green: 85/255,  blue: 0/255)]),
    Rank(id: 5,  name: "Challenger",   emblemName: "challenger_emblem",   requiredXP: 5100,
         subtitle: "You only lose when you stop fighting.",
         themeColors: [Color(red: 155/255, green: 102/255, blue: 75/255),
                       Color(red: 33/255,  green: 64/255,  blue: 68/255)]),
    Rank(id: 6,  name: "Refiner",      emblemName: "refiner_emblem",      requiredXP: 6900,
         subtitle: "Strength is forged in relentless practice.",
         themeColors: [Color(red: 4/255,   green: 99/255,  blue: 7/255),
                       Color(red: 212/255, green: 175/255, blue: 55/255)]),
    Rank(id: 7,  name: "Master",       emblemName: "master_emblem",       requiredXP: 9000,
         subtitle: "Discipline shapes mastery.",
         themeColors: [Color(red: 11/255,  green: 29/255,  blue: 58/255),
                       Color(red: 64/255,  green: 224/255, blue: 208/255)]),
    Rank(id: 8,  name: "Conquerer",    emblemName: "conquerer_emblem",    requiredXP: 12000,
         subtitle: "Pain is the path to triumph.",
         themeColors: [Color(red: 71/255,  green: 12/255,  blue: 17/255),
                       Color(red: 86/255,  green: 105/255, blue: 162/255)]),
    Rank(id: 9,  name: "Ascendant",    emblemName: "ascendant_emblem",    requiredXP: 15000,
         subtitle: "Only by fighting do you rise.",
         themeColors: [Color(red: 10/255,  green: 55/255,  blue: 126/255),
                       Color(red: 180/255, green: 124/255, blue: 28/255)]),
    Rank(id: 10, name: "Transcendent", emblemName: "transcendent_emblem", requiredXP: 20100,
         subtitle: "All limits fall before you.",
         themeColors: [Color(red: 84/255,  green: 0/255,   blue: 232/255),
                       Color(red: 236/255, green: 71/255,  blue: 1/255)])
]

// MARK: - Shared Utilities

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func sanitizeName(_ input: String) -> String {
    let allowedCharacterSet = CharacterSet.letters
        .union(.whitespaces)
        .union(CharacterSet(charactersIn: "'-"))
    let filtered = input.unicodeScalars
        .filter { allowedCharacterSet.contains($0) }
    let cleaned = String(String.UnicodeScalarView(filtered))
    let components = cleaned.split(separator: " ")
    let capitalized = components.map { word -> String in
        word.prefix(1).uppercased() + word.dropFirst().lowercased()
    }
    let result = capitalized.joined(separator: " ")
    return String(result.prefix(24))
}

func calculateBedtime(wakeTime: Date, sleepHours: Double) -> String? {
    let calendar = Calendar.current
    guard let bedtime = calendar.date(byAdding: .minute,
                                       value: Int(-sleepHours * 60),
                                       to: wakeTime) else { return nil }

    let minutes = calendar.component(.minute, from: bedtime)
    let remainder = minutes % 15
    let adjustment = remainder < 8 ? -remainder : (15 - remainder)
    guard let roundedBedtime = calendar.date(byAdding: .minute,
                                              value: adjustment,
                                              to: bedtime) else { return nil }

    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: roundedBedtime)
}

func militaryTimeInt(from date: Date) -> Int {
    let hour = Calendar.current.component(.hour, from: date)
    let minute = Calendar.current.component(.minute, from: date)
    return hour * 100 + minute
}
