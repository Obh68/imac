#!/bin/bash
#
# macOS LCD Ghosting Refresher (Fullscreen Flash)
# Completely standalone: uses Swift script compiled on the fly.
#

FLASHES=50        # number of flashes
DELAY=1        # seconds between flashes

TMPFILE=$(mktemp /tmp/flashscreen.XXXX.swift)

cat > "$TMPFILE" <<EOF
import Cocoa
import Foundation

let flashes = $FLASHES
let delay = $DELAY

class FlashWindow: NSWindow {
    init() {
        let screen = NSScreen.main!
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .mainMenu + 1
        self.isOpaque = true
        self.backgroundColor = NSColor.black
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func flash() {
        for _ in 0..<flashes {
            self.backgroundColor = NSColor.black
            RunLoop.current.run(until: Date().addingTimeInterval(delay))
            self.backgroundColor = NSColor.white
            RunLoop.current.run(until: Date().addingTimeInterval(delay))
        }
    }
}

let app = NSApplication.shared
let win = FlashWindow()
win.makeKeyAndOrderFront(nil)

DispatchQueue.global().async {
    win.flash()
    DispatchQueue.main.async {
        win.close()
        app.terminate(nil)
    }
}

app.run()
EOF

echo "Running fullscreen flash… (press ⌘+⌥+Esc if you must force quit)"
swift "$TMPFILE"

rm "$TMPFILE"
echo "Done."

