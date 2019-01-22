#if !canImport(ObjectiveC)
import XCTest

extension CompilationDatabaseTests {
    // DO NOT MODIFY: This is autogenerated, use: 
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CompilationDatabaseTests = [
        ("testCompilationDatabaseBuildSystem", testCompilationDatabaseBuildSystem),
        ("testDecodeCompDBCommand", testDecodeCompDBCommand),
        ("testEncodeCompDBCommand", testEncodeCompDBCommand),
        ("testJSONCompilationDatabaseCoding", testJSONCompilationDatabaseCoding),
        ("testJSONCompilationDatabaseFromDirectory", testJSONCompilationDatabaseFromDirectory),
        ("testJSONCompilationDatabaseLookup", testJSONCompilationDatabaseLookup),
        ("testSplitShellEscapedCommand", testSplitShellEscapedCommand),
    ]
}

extension FallbackBuildSystemTests {
    // DO NOT MODIFY: This is autogenerated, use: 
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FallbackBuildSystemTests = [
        ("testC", testC),
        ("testCXX", testCXX),
        ("testObjC", testObjC),
        ("testObjCXX", testObjCXX),
        ("testSwift", testSwift),
        ("testUnknown", testUnknown),
    ]
}

extension ToolchainRegistryTests {
    // DO NOT MODIFY: This is autogenerated, use: 
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ToolchainRegistryTests = [
        ("testDefaultBasic", testDefaultBasic),
        ("testDefaultDarwin", testDefaultDarwin),
        ("testDuplicateError", testDuplicateError),
        ("testDuplicatePathError", testDuplicatePathError),
        ("testDuplicateXcodeError", testDuplicateXcodeError),
        ("testDylibNames", testDylibNames),
        ("testFromDirectory", testFromDirectory),
        ("testMultipleXcodes", testMultipleXcodes),
        ("testSearchDarwin", testSearchDarwin),
        ("testSearchExplicitEnv", testSearchExplicitEnv),
        ("testSearchExplicitEnvBuiltin", testSearchExplicitEnvBuiltin),
        ("testSearchPATH", testSearchPATH),
        ("testSubDirs", testSubDirs),
        ("testUnknownPlatform", testUnknownPlatform),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CompilationDatabaseTests.__allTests__CompilationDatabaseTests),
        testCase(FallbackBuildSystemTests.__allTests__FallbackBuildSystemTests),
        testCase(ToolchainRegistryTests.__allTests__ToolchainRegistryTests),
    ]
}
#endif
