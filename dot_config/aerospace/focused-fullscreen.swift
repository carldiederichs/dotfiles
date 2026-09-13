import AppKit
import ApplicationServices

// AeroSpace uses this same bridge: titles are not unique window identities.
@_silgen_name("_AXUIElementGetWindow")
func axWindowID(_ window: AXUIElement, _ id: UnsafeMutablePointer<CGWindowID>) -> AXError

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("AeroSpace fullscreen: \(message)\n".utf8))
    exit(1)
}

func aerospace(_ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = arguments
    do { try process.run() } catch { fail("Cannot run aerospace: \(error)") }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { fail("Command failed: \(arguments.joined(separator: " "))") }
}

guard AXIsProcessTrusted() else { fail("Accessibility access is unavailable; no window was changed.") }
guard let application = NSWorkspace.shared.frontmostApplication else { fail("No active application.") }
let appElement = AXUIElementCreateApplication(application.processIdentifier)
var value: CFTypeRef?
guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &value) == .success,
      let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { fail("No native focused window.") }
let window = value as! AXUIElement
var id: CGWindowID = 0
guard axWindowID(window, &id) == .success, id != 0 else { fail("Cannot identify the native focused window.") }

// Native restore can leave AeroSpace's cached focus stale. Never use it to
// choose the target, and never switch to another window and back to repair it.
aerospace(["focus", "--window-id", String(id)])
aerospace(["fullscreen", "--window-id", String(id)])

// AeroSpace's fullscreen only changes geometry. Same-ID focus can be a no-op,
// so explicitly raise the exact captured window above restored normal peers.
let raised = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
guard raised == .success else {
    fail("Fullscreen toggled for window \(id), but raising returned \(raised.rawValue). Do not retry the toggle blindly.")
}
print("Fullscreen toggled and raised window \(id)")
