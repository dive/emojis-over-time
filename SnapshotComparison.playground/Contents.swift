import AppKit
import PlaygroundSupport

struct Config {
    // Specify the path where folders with snapshots are stored.
    static let workingPath: URL = URL(fileURLWithPath: ("~/Downloads/emojis" as NSString).expandingTildeInPath)
    // Specify versions to compare (A < B)
    static let A: URL = Config.workingPath.appendingPathComponent("13.2")
    static let B: URL = Config.workingPath.appendingPathComponent("13.3")
}

let fileManager = FileManager.default

extension NSImage {
    func diff(with image: NSImage) -> NSImage {
        let diff = NSImage(size: self.size)
        diff.lockFocus()
        let rect = NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect, from: rect, operation: .copy, fraction: 1.0)
        // Subtracts the darker value from the lighter value
        image.draw(in: rect, from: rect, operation: .difference, fraction: 1.0)
        diff.unlockFocus()
        return diff
    }

    func preview(first: NSImage, second: NSImage) -> NSImage {
        let vPadding = self.size.width * 0.1
        let hPadding = self.size.height * 0.1
        let size = CGSize(width: (self.size.width + (vPadding * 2)) * 3, height: self.size.height + (hPadding * 2))
        let preview = NSImage(size: size)
        preview.lockFocus()
        self.draw(in: CGRect(x: vPadding, y: hPadding, width: self.size.width, height: self.size.height))
        first.draw(in: CGRect(x: (vPadding * 3) + first.size.width, y: hPadding, width: self.size.width, height: self.size.height))
        second.draw(in: CGRect(x: (vPadding * 5) + (second.size.width * 2), y: hPadding, width: self.size.width, height: self.size.height))
        preview.unlockFocus()
        return preview
    }
}

// More or less quick and dirty initial comparison function
func filesEqual(_ original: URL, with reference: URL) -> Bool {
    let originalData = try! Data(contentsOf: original)
    let referenceData = try! Data(contentsOf: reference)
    return originalData == referenceData
}

func differentFiles() -> [URL: URL] {
    let aFiles = try! fileManager.contentsOfDirectory(at: Config.A, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    var files = [URL: URL]()
    aFiles.forEach { aFileURL in
        let bFileURL = Config.B.appendingPathComponent(aFileURL.lastPathComponent)
        guard fileManager.fileExists(atPath: bFileURL.path) else { fatalError("Cannot find the same file for B version: \(aFileURL.lastPathComponent)") }
        if filesEqual(aFileURL, with: bFileURL) == false { files[aFileURL] = bFileURL }
    }
    return files
}

var diffs = [String: NSImage]()
for (A, B) in differentFiles() {
    autoreleasepool {
        guard let originalImage = NSImage(contentsOf: A) else { fatalError() }
        guard let referenceImage = NSImage(contentsOf: B) else { fatalError() }
        let diffImage = originalImage.diff(with: referenceImage)
        let preview = originalImage.preview(first: referenceImage, second: diffImage)
        diffs[A.lastPathComponent] = preview
    }
}

let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SnapshotComparison").appendingPathComponent("\(Config.A.lastPathComponent)->\(Config.B.lastPathComponent)")
guard !FileManager.default.fileExists(atPath: folder.path) else { fatalError("Folder \(folder.path) already exists. Delete it to record again.") }
try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
for (name, image) in diffs {
    guard let imageData = NSBitmapImageRep(data: image.tiffRepresentation!)?.representation(using: .png, properties: [:]) else { fatalError() }
    try! imageData.write(to: folder.appendingPathComponent(name))
}
print("Images saved to \(folder.path)")
print("Done.")
diffs
