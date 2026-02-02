#!/bin/bash
#
# ADVANCED macOS LCD Pixel Refresh / Ghosting Cleaner
# Uses Swift + Cocoa (compiled & run automatically)
#

#############################
# CONFIGURATION
#############################

FLASH_COUNT=40       # white/black flashes
FLASH_DELAY=1     # seconds

RGB_CYCLES=60        # RGB cycles
RGB_DELAY=1

CHECKER_TIME=20      # seconds
SWEEP_TIME=20        # seconds

#############################

TMP=$(mktemp /tmp/lcdrefresh.XXXX.swift)

cat > "$TMP" <<EOF
import Cocoa
import Foundation

let flashCount = $FLASH_COUNT
let flashDelay = $FLASH_DELAY
let rgbCycles  = $RGB_CYCLES
let rgbDelay   = $RGB_DELAY
let checkerTime = $CHECKER_TIME
let sweepTime   = $SWEEP_TIME

class RefreshWindow: NSWindow {
    let view = NSView()

    init() {
        let screen = NSScreen.main!
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .mainMenu + 2
        isOpaque = true
        backgroundColor = .black
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = view
    }

    func setColor(_ color: NSColor) {
        DispatchQueue.main.sync {
            self.backgroundColor = color
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.001))
    }

    func flashBW() {
        for _ in 0..<flashCount {
            setColor(.black)
            RunLoop.current.run(until: Date().addingTimeInterval(flashDelay))
            setColor(.white)
            RunLoop.current.run(until: Date().addingTimeInterval(flashDelay))
        }
    }

    func cycleRGB() {
        let colors: [NSColor] = [.red, .green, .blue, .white, .black]
        for _ in 0..<rgbCycles {
            for c in colors {
                setColor(c)
                RunLoop.current.run(until: Date().addingTimeInterval(rgbDelay))
            }
        }
    }

    func checkerboard() {
        let end = Date().addingTimeInterval(TimeInterval(checkerTime))
        let size = 40

        while Date() < end {
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(frame.width),
                pixelsHigh: Int(frame.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )!

            let ctx = NSGraphicsContext(bitmapImageRep: rep)!
            NSGraphicsContext.current = ctx

            for y in stride(from: 0, to: Int(frame.height), by: size) {
                for x in stride(from: 0, to: Int(frame.width), by: size) {
                    let even = ((x / size) + (y / size)) % 2 == 0
                    (even ? NSColor.white : NSColor.black).setFill()
                    NSRect(x: x, y: y, width: size, height: size).fill()
                }
            }

            let img = NSImage(size: frame.size)
            img.addRepresentation(rep)
            view.layer?.contents = img
            RunLoop.current.run(until: Date().addingTimeInterval(0.03))
        }
    }

    func sweep() {
        let end = Date().addingTimeInterval(TimeInterval(sweepTime))
        let width = Int(frame.width)

        while Date() < end {
            for x in 0..<width {
                setColor(.black)
                let rect = NSView(frame: frame)
                rect.wantsLayer = true
                rect.layer?.backgroundColor = NSColor.white.cgColor
                rect.frame = NSRect(x: x, y: 0, width: 20, height: Int(frame.height))
                contentView?.addSubview(rect)
                RunLoop.current.run(until: Date().addingTimeInterval(0.002))
                rect.removeFromSuperview()
            }
        }
    }
}

let app = NSApplication.shared
let win = RefreshWindow()
win.makeKeyAndOrderFront(nil)

DispatchQueue.global().async {
    win.flashBW()
    win.cycleRGB()
    win.checkerboard()
    win.sweep()

    DispatchQueue.main.async {
        win.close()
        app.terminate(nil)
    }
}

app.run()
EOF

echo "Starting ADVANCED LCD refresh..."
echo "This will take ~2–3 minutes."
echo "To abort: ⌘⌥⎋ (Force Quit)"

swift "$TMP"
rm "$TMP"
echo "Done."

