import AppKit
import ApplicationServices

@_silgen_name("_AXUIElementGetWindow")
func axWindowID(_ window: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func run(_ args: [String]) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

guard AXIsProcessTrusted() else {
    FileHandle.standardError.write(Data("Voice follow: accessibility access unavailable; no windows moved.\n".utf8))
    exit(1)
}
let dryRun = CommandLine.arguments.contains("--dry-run")
for app in NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex") {
    let element = AXUIElementCreateApplication(app.processIdentifier)
    guard let windows = attribute(element, kAXWindowsAttribute) as? [AXUIElement] else { continue }
    for window in windows {
        // Match only the observed nonmodal, buttonless voice dialog, never a main window.
        guard attribute(window, kAXSubroleAttribute) as? String == kAXDialogSubrole,
              attribute(window, kAXTitleAttribute) as? String == "ChatGPT",
              attribute(window, kAXModalAttribute) as? Bool == false,
              attribute(window, kAXMainAttribute) as? Bool == false,
              attribute(window, kAXCloseButtonAttribute) == nil else { continue }
        var id: CGWindowID = 0
        guard axWindowID(window, &id) == .success, id != 0 else { continue }
        if dryRun { print(id); continue }
        // Query current focus, not a possibly stale workspace-change event.
        guard let target = run(["list-workspaces", "--focused", "--format", "%{workspace}"]),
              !target.isEmpty,
              let current = run(["list-windows", "--all", "--format", "%{window-id}|%{workspace}"]),
              let row = current.split(separator: "\n").first(where: { $0.hasPrefix("\(id)|") }),
              row != "\(id)|\(target)" else { continue }
        // No focus or activation command: preserve the app the user selected.
        _ = run(["move-node-to-workspace", "--window-id", String(id), target])
    }
}
