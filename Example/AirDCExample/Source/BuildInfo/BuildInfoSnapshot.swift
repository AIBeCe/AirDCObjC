import AirDCObjC

public struct BuildInfoSnapshot: Equatable, Sendable {
    public let coreCommit: String
    public let coreVersion: String
    public let coreBuildNumber: Int
    public let coreName: String

    public init() {
        coreCommit = ADCBuildInfo.coreCommit
        coreVersion = ADCBuildInfo.coreVersion
        coreBuildNumber = ADCBuildInfo.coreBuildNumber
        coreName = ADCBuildInfo.coreName
    }

    public var displayTitle: String { "\(coreName) \(coreVersion)" }
    public var scopeStatus: String {
        "Phase 2 runtime scenario — isolated Core lifecycle only; networking and domain APIs are not exposed here."
    }
}
