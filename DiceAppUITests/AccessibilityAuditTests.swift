import XCTest

/// Xcode's accessibility audit over the app's screens: the roller, a result, the bonus picker and Settings.
/// In its own scheme ("Accessibility"), not in CI or release.sh, because UI tests are slow. Run before a release:
/// `xcodebuild test -project Dice.xcodeproj -scheme Accessibility -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    /// Fails on missing labels, small hit areas, wrong traits and the like. Three kinds are reported but allowed:
    /// - Dynamic Type: the app caps text at accessibility2 (RollerView) and the result total has a fixed, already
    ///   large size, both on purpose.
    /// - Contrast: the colors are a design decision (system grey secondary text, tinted buttons, outcome colors).
    /// - Clipped text: reported for text that shows in full on screen (the purpose placeholder, the bonus presets),
    ///   so check the "AUDIT" lines by eye. It did find the history row's cut-off formula.
    func test_audit_defaultTextSize() throws {
        try auditScreens(contentSize: nil) { issue in
            [.contrast, .dynamicType, .textClipped].contains(issue.auditType)
        }
    }

    /// Report only: at the largest size some text is expected to be cut (the purpose placeholder). Read the
    /// "AUDIT" lines in the log.
    func test_audit_largestTextSize() throws {
        try auditScreens(contentSize: "UICTContentSizeCategoryAccessibilityXXXL") { _ in true }
    }

    private func auditScreens(contentSize: String?, allowed: @escaping (XCUIAccessibilityAuditIssue) -> Bool) throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        app.launch()

        func audit(_ screen: String) throws {
            // Let the roll's scale pulse and the picker's slide finish: mid-animation frames are reported as clipped.
            Thread.sleep(forTimeInterval: 1)
            try app.performAccessibilityAudit { issue in
                let element = issue.element?.debugDescription.split(separator: "\n").first ?? "-"
                print("AUDIT [\(screen)] \(issue.compactDescription) | \(element)")
                return allowed(issue)
            }
        }

        try audit("roller")
        app.buttons["Roll"].tap()
        try audit("result")
        app.buttons["Bonus"].tap()
        try audit("bonus picker")
        app.buttons["d4"].firstMatch.tap()
        try audit("bonus added")
        app.buttons["Settings"].tap()
        try audit("settings")
    }
}
