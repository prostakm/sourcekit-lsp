#if !canImport(ObjectiveC)
import XCTest

extension CrashRecoveryTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CrashRecoveryTests = [
        ("testClangdCrashRecovery", testClangdCrashRecovery),
        ("testClangdCrashRecoveryReopensWithCorrectBuildSettings", testClangdCrashRecoveryReopensWithCorrectBuildSettings),
        ("testPreventClangdCrashLoop", testPreventClangdCrashLoop),
        ("testSourcekitdCrashRecovery", testSourcekitdCrashRecovery),
    ]
}

extension SourceKitDRegistryTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SourceKitDRegistryTests = [
        ("testAdd", testAdd),
        ("testRemove", testRemove),
        ("testRemoveResurrect", testRemoveResurrect),
    ]
}

extension SourceKitDTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__SourceKitDTests = [
        ("testMultipleNotificationHandlers", testMultipleNotificationHandlers),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CrashRecoveryTests.__allTests__CrashRecoveryTests),
        testCase(SourceKitDRegistryTests.__allTests__SourceKitDRegistryTests),
        testCase(SourceKitDTests.__allTests__SourceKitDTests),
    ]
}
#endif
