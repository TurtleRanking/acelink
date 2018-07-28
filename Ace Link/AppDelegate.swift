import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application finished loading")

        // One unnamed argument, must be the stream hash
        if CommandLine.arguments.count % 1 == 1 {
            print("Open stream from arg", CommandLine.arguments.last!)
            openStream(CommandLine.arguments.last!)
        }

        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarIcon"))
        }

        statusItem.menu = AceLinkMenu(title: "")
    }

    func openStream(_ hash: String) {
        let path = Bundle.main.path(forResource: "StartDocker", ofType: "sh")!
        let task = Process.launchedProcess(launchPath: path, arguments: [hash])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            print("Done")
        }
    }

    func stopStream() {
        let path = Bundle.main.path(forResource: "StopDocker", ofType: "sh")!
        let task = Process.launchedProcess(launchPath: path, arguments: [])
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            print("Done")
        }
    }

    func getClipboardString() -> String {
        let clipboardData = NSPasteboard.general.string(forType: NSPasteboard.PasteboardType.string)

        if clipboardData == nil {
            return ""
        }

        let clipboardString: String = clipboardData!.trimmingCharacters(in: .whitespacesAndNewlines)

        // Verify conform SHA1
        let range = NSMakeRange(0, clipboardString.count)
        let regex = try! NSRegularExpression(
            pattern: "^[a-fA-F0-9]{40}$",
            options: NSRegularExpression.Options.caseInsensitive
        )

        if regex.firstMatch(in: clipboardString, options: [], range: range) != nil  {
            return clipboardString
        }

        return ""
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        stopStream()
    }

}