import CloudKit

enum CloudSyncAvailability: Equatable {
    case checking
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case unavailable

    init(accountStatus: CKAccountStatus) {
        switch accountStatus {
        case .available:
            self = .available
        case .noAccount:
            self = .noAccount
        case .restricted:
            self = .restricted
        case .temporarilyUnavailable:
            self = .temporarilyUnavailable
        case .couldNotDetermine:
            self = .unavailable
        @unknown default:
            self = .unavailable
        }
    }

    var title: String {
        switch self {
        case .checking: "Checking…"
        case .available: "On"
        case .noAccount: "Sign In Required"
        case .restricted: "Restricted"
        case .temporarilyUnavailable: "Temporarily Unavailable"
        case .unavailable: "Unavailable"
        }
    }

    var message: String {
        switch self {
        case .checking:
            "Checking your iCloud account status."
        case .available:
            "Your collection and photos sync automatically across devices signed in to this Apple Account."
        case .noAccount:
            "Sign in to iCloud in Settings to sync your collection across devices."
        case .restricted:
            "iCloud access is restricted on this device. Check Screen Time or device-management settings."
        case .temporarilyUnavailable:
            "iCloud is temporarily unavailable. StageLight will keep your changes locally and retry automatically."
        case .unavailable:
            "StageLight could not determine your iCloud status. Your collection remains available on this device."
        }
    }
}

struct CloudSyncStatusProvider {
    let containerIdentifier: String

    func currentAvailability() async -> CloudSyncAvailability {
        do {
            let status = try await CKContainer(identifier: containerIdentifier).accountStatus()
            return CloudSyncAvailability(accountStatus: status)
        } catch {
            return .unavailable
        }
    }
}
