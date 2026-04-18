/// The four answer ratings available during review.
public enum Rating: Int16, Sendable, CaseIterable, Comparable, Hashable {
    case again = 1
    case hard  = 2
    case good  = 3
    case easy  = 4

    public static func < (lhs: Rating, rhs: Rating) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Human-readable label for display in the UI.
    public var label: String {
        switch self {
        case .again: String(localized: "rating.again", bundle: .module, defaultValue: "Again")
        case .hard:  String(localized: "rating.hard", bundle: .module, defaultValue: "Hard")
        case .good:  String(localized: "rating.good", bundle: .module, defaultValue: "Good")
        case .easy:  String(localized: "rating.easy", bundle: .module, defaultValue: "Easy")
        }
    }
}
