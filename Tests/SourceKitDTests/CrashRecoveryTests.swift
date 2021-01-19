//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ISDBTestSupport
import LanguageServerProtocol
import SourceKitLSP
import SourceKitD
import SKTestSupport
import XCTest

fileprivate extension HoverResponse {
  func contains(string: String) -> Bool {
    switch self.contents {
    case .markedStrings(let markedStrings):
      for markedString in markedStrings {
        switch markedString {
        case .markdown(value: let value), .codeBlock(language: _, value: let value):
          if value.contains(string) {
            return true
          }
        }
      }
    case .markupContent(let markdownString):
      if markdownString.value.contains(string) {
        return true
      }
    }
    return false
  }
}

final class CrashRecoveryTests: XCTestCase {
  func testSourcekitdCrashRecovery() throws {
    try XCTSkipUnless(longTestsEnabled)

    let ws = try! staticSourceKitTibsWorkspace(name: "sourcekitdCrashRecovery")!
    let loc = ws.testLoc("loc")

    try! ws.openDocument(loc.url, language: .swift)

    // Make a change to the file that's not saved to disk. This way we can check that we re-open the correct in-memory state.

    let addFuncChange = TextDocumentContentChangeEvent(range: loc.position..<loc.position, rangeLength: 0, text: """

      func foo() {
        print("Hello world")
      }
      """)
    ws.sk.send(DidChangeTextDocumentNotification(textDocument: VersionedTextDocumentIdentifier(loc.docUri, version: 2), contentChanges: [addFuncChange]))

    // Do a sanity check and verify that we get the expected result from a hover response before crashing sourcekitd.

    let hoverRequest = HoverRequest(textDocument: loc.docIdentifier, position: Position(line: 1, utf16index: 6))
    let preCrashHoverResponse = try! ws.sk.sendSync(hoverRequest)
    precondition(preCrashHoverResponse?.contains(string: "foo()") ?? false, "Sanity check failed. The Hover response did not contain foo(), even before crashing sourcekitd. Received response: \(String(describing: preCrashHoverResponse))")

    // Crash sourcekitd

    let sourcekitdServer = ws.testServer.server!._languageService(for: loc.docUri, .swift, in: ws.testServer.server!.workspace!) as! SwiftLanguageServer

    let sourcekitdCrashed = expectation(description: "sourcekitd has crashed")
    let sourcekitdRestarted = expectation(description: "sourcekitd has been restarted (syntactic only)")
    let semanticFunctionalityRestored = expectation(description: "sourcekitd has restored semantic language functionality")

    sourcekitdServer.addStateChangeHandler { (oldState, newState) in
      switch newState {
      case .connectionInterrupted:
        sourcekitdCrashed.fulfill()
      case .semanticFunctionalityDisabled:
        sourcekitdRestarted.fulfill()
      case .connected:
        semanticFunctionalityRestored.fulfill()
      }
    }

    sourcekitdServer._crash()

    self.wait(for: [sourcekitdCrashed], timeout: 5)
    self.wait(for: [sourcekitdRestarted], timeout: 30)

    // Check that we have syntactic functionality again

    XCTAssertNoThrow(try ws.sk.sendSync(FoldingRangeRequest(textDocument: loc.docIdentifier)))

    // sourcekitd's semantic request timer is only started when the first semantic request comes in.
    // Send a hover request (which will fail) to trigger that timer.
    // Afterwards wait for semantic functionality to be restored.
    _ = try? ws.sk.sendSync(hoverRequest)
    self.wait(for: [semanticFunctionalityRestored], timeout: 30)

    // Check that we get the same hover response from the restored in-memory state

    XCTAssertNoThrow(try {
      let postCrashHoverResponse = try ws.sk.sendSync(hoverRequest)
      XCTAssertTrue(postCrashHoverResponse?.contains(string: "foo()") ?? false)
    }())
  }
  
  /// Crashes clangd and waits for it to restart
  /// - Parameters:
  ///   - ws: The workspace for which the clangd server shall be crashed
  ///   - loc: A test location that points to the first line of a given file. This line needs to be otherwise empty.
  private func crashClangd(for ws: SKTibsTestWorkspace, firstLineLoc loc: TestLocation) {
    let clangdServer = ws.testServer.server!._languageService(for: loc.docUri, .cpp, in: ws.testServer.server!.workspace!)!
    
    let clangdCrashed = self.expectation(description: "clangd crashed")
    let clangdRestarted = self.expectation(description: "clangd restarted")

    clangdServer.addStateChangeHandler { (oldState, newState) in
      switch newState {
      case .connectionInterrupted:
        clangdCrashed.fulfill()
      case .connected:
        clangdRestarted.fulfill()
      default:
        break
      }
    }

    // Add a pragma to crash clang
    let addCrashPragma = TextDocumentContentChangeEvent(range: loc.position..<loc.position, rangeLength: 0, text: "#pragma clang __debug crash\n")
    ws.sk.send(DidChangeTextDocumentNotification(textDocument: VersionedTextDocumentIdentifier(loc.docUri, version: 3), contentChanges: [addCrashPragma]))

    self.wait(for: [clangdCrashed], timeout: 5)

    // Once clangds has crashed, remove the pragma again to allow it to restart
    let removeCrashPragma = TextDocumentContentChangeEvent(range: loc.position..<Position(line: 1, utf16index: 0), rangeLength: 28, text: "")
    ws.sk.send(DidChangeTextDocumentNotification(textDocument: VersionedTextDocumentIdentifier(loc.docUri, version: 4), contentChanges: [removeCrashPragma]))

    self.wait(for: [clangdRestarted], timeout: 30)
  }

  func testClangdCrashRecovery() throws {
    try XCTSkipUnless(longTestsEnabled)

    let ws = try! staticSourceKitTibsWorkspace(name: "ClangCrashRecovery")!
    let loc = ws.testLoc("loc")

    try! ws.openDocument(loc.url, language: .cpp)

    // Make a change to the file that's not saved to disk. This way we can check that we re-open the correct in-memory state.

    let addFuncChange = TextDocumentContentChangeEvent(range: loc.position..<loc.position, rangeLength: 0, text: """

      void main() {
      }
      """)
    ws.sk.send(DidChangeTextDocumentNotification(textDocument: VersionedTextDocumentIdentifier(loc.docUri, version: 2), contentChanges: [addFuncChange]))

    // Do a sanity check and verify that we get the expected result from a hover response before crashing clangd.

    let expectedHoverRange = Position(line: 1, utf16index: 5)..<Position(line: 1, utf16index: 9)

    let hoverRequest = HoverRequest(textDocument: loc.docIdentifier, position: Position(line: 1, utf16index: 6))
    let preCrashHoverResponse = try! ws.sk.sendSync(hoverRequest)
    precondition(preCrashHoverResponse?.range == expectedHoverRange, "Sanity check failed. The Hover response was not what we expected, even before crashing sourcekitd")

    // Crash clangd

    crashClangd(for: ws, firstLineLoc: loc)

    // Check that we have re-opened the document with the correct in-memory state

    XCTAssertNoThrow(try {
      let postCrashHoverResponse = try ws.sk.sendSync(hoverRequest)
      XCTAssertEqual(postCrashHoverResponse?.range, expectedHoverRange)
    }())
  }
    
  func testClangdCrashRecoveryReopensWithCorrectBuildSettings() throws {
    try XCTSkipUnless(longTestsEnabled)

    let ws = try! staticSourceKitTibsWorkspace(name: "ClangCrashRecoveryBuildSettings")!
    let loc = ws.testLoc("loc")
    
    try! ws.openDocument(loc.url, language: .cpp)
    
    // Do a sanity check and verify that we get the expected result from a hover response before crashing clangd.
    
    let expectedHighlightResponse = [
      DocumentHighlight(range: Position(line: 3, utf16index: 5)..<Position(line: 3, utf16index: 8), kind: .text),
      DocumentHighlight(range: Position(line: 9, utf16index: 2)..<Position(line: 9, utf16index: 5), kind: .text)
    ]
    
    let highlightRequest = DocumentHighlightRequest(textDocument: loc.docIdentifier, position: Position(line: 9, utf16index: 3))
    let preCrashHighlightResponse = try! ws.sk.sendSync(highlightRequest)
    precondition(preCrashHighlightResponse == expectedHighlightResponse, "Sanity check failed. The Hover response was not what we expected, even before crashing sourcekitd")
    
    // Crash clangd

    crashClangd(for: ws, firstLineLoc: loc)
    
    // Check that we have re-opened the document with the correct build settings
    // If we did not recover the correct build settings, document highlight would
    // pick the definition of foo() in the #else branch.

    XCTAssertNoThrow(try {
      let postCrashHighlightResponse = try ws.sk.sendSync(highlightRequest)
      XCTAssertEqual(postCrashHighlightResponse, expectedHighlightResponse)
    }())
  }
  
  func testPreventClangdCrashLoop() throws {
    try XCTSkipUnless(longTestsEnabled)

    let ws = try! staticSourceKitTibsWorkspace(name: "ClangCrashRecovery")!
    let loc = ws.testLoc("loc")

    try! ws.openDocument(loc.url, language: .cpp)

    // Send a nonsensical request to wait for clangd to start up
    
    let hoverRequest = HoverRequest(textDocument: loc.docIdentifier, position: Position(line: 1, utf16index: 6))
    _ = try! ws.sk.sendSync(hoverRequest)
    
    // Keep track of clangd crashes
    
    let clangdServer = ws.testServer.server!._languageService(for: loc.docUri, .cpp, in: ws.testServer.server!.workspace!)!
    
    let clangdCrashed = self.expectation(description: "clangd crashed")
    clangdCrashed.assertForOverFulfill = false
    // assertForOverFulfill is not working on Linux (SR-12575). Manually keep track if we have already called fulfill on the expectation
    var clangdCrashedFulfilled = false
    
    let clangdRestartedFirstTime = self.expectation(description: "clangd restarted for the first time")
    
    let clangdRestartedSecondTime = self.expectation(description: "clangd restarted for the second time")
    clangdRestartedSecondTime.assertForOverFulfill = false
    // assertForOverFulfill is not working on Linux (SR-12575). Manually keep track if we have already called fulfill on the expectation
    var clangdRestartedSecondTimeFulfilled = false
    
    var clangdHasRestartedFirstTime = false

    clangdServer.addStateChangeHandler { (oldState, newState) in
      switch newState {
      case .connectionInterrupted:
        if !clangdCrashedFulfilled {
          clangdCrashed.fulfill()
          clangdCrashedFulfilled = true
        }
      case .connected:
        if !clangdHasRestartedFirstTime {
          clangdRestartedFirstTime.fulfill()
          clangdHasRestartedFirstTime = true
        } else {
          if !clangdRestartedSecondTimeFulfilled {
            clangdRestartedSecondTime.fulfill()
            clangdRestartedSecondTimeFulfilled = true
          }
        }
      default:
        break
      }
    }

    // Add a pragma to crash clang
    
    let addCrashPragma = TextDocumentContentChangeEvent(range: loc.position..<loc.position, rangeLength: 0, text: "#pragma clang __debug crash\n")
    ws.sk.send(DidChangeTextDocumentNotification(textDocument: VersionedTextDocumentIdentifier(loc.docUri, version: 3), contentChanges: [addCrashPragma]))

    self.wait(for: [clangdCrashed], timeout: 5)

    // Clangd has crashed for the first time. Leave the pragma there to crash clangd once again.
    
    self.wait(for: [clangdRestartedFirstTime], timeout: 30)
    // Clangd has restarted. Note the date so we can check that the second restart doesn't happen too quickly.
    let firstRestartDate = Date()
    
    self.wait(for: [clangdRestartedSecondTime], timeout: 30)
    XCTAssert(Date().timeIntervalSince(firstRestartDate) > 5, "Clangd restarted too quickly after crashing twice in a row. We are not preventing crash loops.")
  }
}

