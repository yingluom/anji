import Sharing

enum SyncMode: String, Sendable, RawRepresentable {
    case ankiweb
    case custom
    case local
}

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
    static var onboardingDone: Self {
        Self[.appStorage("onboardingDone"), default: false]
    }
}

extension SharedReaderKey where Self == AppStorageKey<SyncMode>.Default {
    static var syncMode: Self {
        Self[.appStorage("syncMode"), default: .ankiweb]
    }
}
