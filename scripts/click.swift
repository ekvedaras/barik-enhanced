// Posts a real mouse click at a screen point (top-left origin, points).
// Usage: swift scripts/click.swift <x> <y> [left|right]
// Needs Accessibility permission for the terminal that runs it.
import CoreGraphics
import Foundation

let args = CommandLine.arguments
guard args.count >= 3, let x = Double(args[1]), let y = Double(args[2]) else {
    FileHandle.standardError.write("usage: swift click.swift <x> <y> [left|right]\n".data(using: .utf8)!)
    exit(64)
}
let right = args.count > 3 && args[3] == "right"
let point = CGPoint(x: x, y: y)
let (down, up, button): (CGEventType, CGEventType, CGMouseButton) =
    right ? (.rightMouseDown, .rightMouseUp, .right) : (.leftMouseDown, .leftMouseUp, .left)

CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: button)?.post(tap: .cghidEventTap)
usleep(50_000)
CGEvent(mouseEventSource: nil, mouseType: down, mouseCursorPosition: point, mouseButton: button)?.post(tap: .cghidEventTap)
usleep(30_000)
CGEvent(mouseEventSource: nil, mouseType: up, mouseCursorPosition: point, mouseButton: button)?.post(tap: .cghidEventTap)
