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
        case .checking: AppLanguage.localized("Checking…")
        case .available: AppLanguage.localized("On")
        case .noAccount: AppLanguage.localized("Sign In Required")
        case .restricted: AppLanguage.localized("Restricted")
        case .temporarilyUnavailable: AppLanguage.localized("Temporarily Unavailable")
        case .unavailable: AppLanguage.localized("Unavailable")
        }
    }

    var message: String {
        switch self {
        case .checking:
            AppLanguage.localized("Checking your iCloud account status.")
        case .available:
            AppLanguage.localized("Your collection and photos sync automatically across devices signed in to this Apple Account.")
        case .noAccount:
            AppLanguage.localized("Sign in to iCloud in Settings to sync your collection across devices.")
        case .restricted:
            AppLanguage.localized("iCloud access is restricted on this device. Check Screen Time or device-management settings.")
        case .temporarilyUnavailable:
            AppLanguage.localized("iCloud is temporarily unavailable. StageLight will keep your changes locally and retry automatically.")
        case .unavailable:
            AppLanguage.localized("StageLight could not determine your iCloud status. Your collection remains available on this device.")
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
