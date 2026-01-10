#!/usr/bin/swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Center Mouse
// @raycast.mode silent

// Optional parameters:
// @raycast.icon 🐁

// Documentation:
// @raycast.author gshahbazian
// @raycast.authorURL https://raycast.com/gshahbazian

import Foundation
import Cocoa
import ApplicationServices

func getFocusedWindowRect() -> CGRect? {
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
    let appPID = frontmostApp.processIdentifier

    let appElement = AXUIElementCreateApplication(appPID)

    var window: AnyObject?
    let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &window)

    guard result == .success, let win = window else { return nil }

    var posValue: CFTypeRef?
    var sizeValue: CFTypeRef?

    if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXPositionAttribute as CFString, &posValue) != .success { return nil }
    if AXUIElementCopyAttributeValue(win as! AXUIElement, kAXSizeAttribute as CFString, &sizeValue) != .success { return nil }

    var point = CGPoint.zero
    var size = CGSize.zero

    AXValueGetValue(posValue as! AXValue, .cgPoint, &point)
    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)

    return CGRect(origin: point, size: size)
}

if let rect = getFocusedWindowRect() {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    CGWarpMouseCursorPosition(center)
}
