import Cocoa
import SwiftUI

public final class PopoverViewController: NSViewController {
    
    public override func loadView() {
        // Embed the SwiftUI view inside a native AppKit NSHostingView
        let contentView = MainPopoverView()
        let hostingView = NSHostingView(rootView: contentView)
        
        // Match bounds to content
        hostingView.frame = NSRect(x: 0, y: 0, width: 380, height: 475)
        self.view = hostingView
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad();
    }
}
