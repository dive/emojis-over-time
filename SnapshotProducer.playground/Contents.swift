//: A UIKit based Playground for producing snapshots with Emojis for different iOS version
//: iOS SDK version aligned with Xcode, so, you have to switch Xcode versions to produce emoji's snapshots retrospectively.

import UIKit
import PlaygroundSupport

let previewSize = CGSize(width: 164, height: 164)
let fontSize: CGFloat = 140

struct Debug {
    static let showSkipped: Bool = false
}

class EmojiViewController : UIViewController {
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .center
        return view
    }()

    override func loadView() {
        self.view = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: previewSize.width, height: previewSize.height))
            view.backgroundColor = .clear
            return view
        }()
        self.setUpImageView()
    }

    private func setUpImageView() {
        guard self.imageView.superview == nil else { fatalError("The view already has a superview") }
        self.view.addSubview(self.imageView)
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func show(_ image: UIImage) { self.imageView.image = image }
}

class EmojisExplorer {

    struct Emoji {
        let hex: String
        let scalar: String
        let name: String
    }

    // It is a bit complicated to convince iOS to give us all the supported emojis.
    // So, I took "emoji-test.txt" from https://unicode.org/Public/emoji/12.1/ and just parse it.
    lazy var fileContent: String = {
        guard let fileUrl = Bundle.main.url(forResource: "emoji-test-12-1", withExtension: "txt") else { fatalError("Cannot read file.") }
        guard let data = try? Data(contentsOf: fileUrl) else { fatalError("Cannot read the data from the file.") }
        guard let content = String(data: data, encoding: .utf8) else { fatalError("Cannot parse the data.") }
        return content
    }()

    // We parse the file mentioned above, ignore empty lines, comments and emojis that are variants for different skin tones.
    lazy var all: [Emoji] = {
        var emojis: [Emoji] = [Emoji]()
        self.fileContent.components(separatedBy: .newlines).forEach { line in
            // Ignore comments and empty lines in the file.
            guard !line.hasPrefix("#") && !line.isEmpty else { return }
            // Ignore skin tone emoji's variants. Comment the next line out if you are curious about changes within tones.
            guard !line.contains("skin tone") else { return }
            // Mhm, this is a regex... Do not do it on production.
            // 1 - hexes, 2 - status, 3 - scalar, 4 - text representation.
            let pattern = #"^((?:.{4,5}\s{1}){1,8})\s{1};\s{1}(\w*-{0,1}\w*)\s*\W\s{1}([^\s]*)\s{1}E\d{1}\.\d{1}\s{1}(.*)$"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { fatalError("Cannot build the regular expression.") }
            let nsrange = NSRange(line.startIndex..<line.endIndex, in: line)
            regex.enumerateMatches(in: line, options: [], range: nsrange) { (match, _, _) in
                guard let match = match else { return }
                let hex: String = {
                    guard let firstCaptureRange = Range(match.range(at: 1), in: line) else { fatalError("Something is wrong with the range.") }
                    let _hex: String = {
                        let raw = String(line[firstCaptureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let components = raw.components(separatedBy: .whitespacesAndNewlines)
                        let hexArray = components.map { Int($0, radix: 16)! }
                        var unicode = String()
                        hexArray.map { unicode.append(Character(Unicode.Scalar($0)!)) }
                        return unicode
                    }()
                    return _hex
                }()
                let status: String = {
                    guard let secondCaptureRange = Range(match.range(at: 2), in: line) else { fatalError("Something is wrong with the range.") }
                    return String(line[secondCaptureRange])
                }()
                let scalar: String = {
                    guard let thirdCaptureRange = Range(match.range(at: 3), in: line) else { fatalError("Something is wrong with the range.") }
                    return String(line[thirdCaptureRange])
                }()
                let name: String = {
                    guard let fourthCaptureRange = Range(match.range(at: 4), in: line) else { fatalError("Something is wrong with the range.") }
                    var _name = String(line[fourthCaptureRange])
                    // Replace some characters in the name for better readability and file system requirements
                    [" ", "”", "“", "\"", "(", ")", ":", ",", "-", "’"].forEach { _name = _name.replacingOccurrences(of: $0, with: "_") }
                    return _name
                }()
                // Do not process unqualified & minimally-qualified emojis (check the "emoji-test.txt" for additional information).
                guard status == "fully-qualified" else {
                    if Debug.showSkipped { print("SKIPPED: \(status) \t \(name) \t \(scalar)") }
                    return
                }
                let emoji = Emoji(hex: hex, scalar: scalar, name: name)
                emojis.append(emoji)
            }
        }
        return emojis
    }()
}

extension String {
    func image() -> UIImage? {
        let rect = CGRect(origin: CGPoint(), size: previewSize)
        let attributes: [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: fontSize)]
        return UIGraphicsImageRenderer(size: self.size(withAttributes: attributes) ).image { (context) in
            (self as NSString).draw(in: rect, withAttributes: attributes)
        }
    }
}

// Xcode Playground uses the default device support shipped with Xcode, but let's log it, just to be sure...
print("iOS version: \(UIDevice.current.systemVersion)")

let emojiViewController = EmojiViewController()
PlaygroundPage.current.liveView = emojiViewController.view

let emojis = EmojisExplorer().all
print("Number of fully-qualified emojis: \(emojis.count)")
DispatchQueue.global().async {
    // Prepare the folder. Let's store everything in the temp.
    // This is iOS Playground and these entities are sandboxed by iOS rules, so, folders will have different destinations between Xcode versions.
    let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("EmojisOverTime").appendingPathComponent(UIDevice.current.systemVersion)
    guard !FileManager.default.fileExists(atPath: folder.path) else { fatalError("Folder \(folder.path) already exists. Delete it to record again.") }
    try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
    for emoji in emojis {
        guard let image = emoji.hex.image() else { fatalError("Cannot create an image.") }
        DispatchQueue.main.async { emojiViewController.show(image) }
        // Uncomment if you want to slow down the animation of the process in the live preview
        // Thread.sleep(forTimeInterval: 0.1)

        // Bullshit
        guard let pngData = image.pngData() else { fatalError("Cannot create png data from the image.") }
        let url = folder.appendingPathComponent("\(emoji.name).png")
        try! pngData.write(to: url)
    }

    print("Images saved to \(folder.path)")
    print("Done.")
}
