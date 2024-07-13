#!/usr/bin/xcrun swift

import AppKit

class ThemeConverter {
  enum ThemeConverterError: Error, CustomStringConvertible {
    case noArguments
    case unableToLoadITermFile(URL)

    var description: String {
      switch self {
      case .noArguments:
        return "Error: No arguments provided"
      case .unableToLoadITermFile(let url):
        return "Error: Unable to load \(url.relativePath)"
      }
    }
  }

  private let files: [String]

  private let iTermColorToTerminalColorMap: [String: String] = [
    "Ansi 0 Color": "ANSIBlackColor",
    "Ansi 1 Color": "ANSIRedColor",
    "Ansi 2 Color": "ANSIGreenColor",
    "Ansi 3 Color": "ANSIYellowColor",
    "Ansi 4 Color": "ANSIBlueColor",
    "Ansi 5 Color": "ANSIMagentaColor",
    "Ansi 6 Color": "ANSICyanColor",
    "Ansi 7 Color": "ANSIWhiteColor",
    "Ansi 8 Color": "ANSIBrightBlackColor",
    "Ansi 9 Color": "ANSIBrightRedColor",
    "Ansi 10 Color": "ANSIBrightGreenColor",
    "Ansi 11 Color": "ANSIBrightYellowColor",
    "Ansi 12 Color": "ANSIBrightBlueColor",
    "Ansi 13 Color": "ANSIBrightMagentaColor",
    "Ansi 14 Color": "ANSIBrightCyanColor",
    "Ansi 15 Color": "ANSIBrightWhiteColor",
    "Background Color": "BackgroundColor",
    "Foreground Color": "TextColor",
    "Selection Color": "SelectionColor",
    "Bold Color": "BoldTextColor",
    "Cursor Color": "CursorColor",
  ]

  required init(files: [String]) throws {
    guard !files.isEmpty else {
      throw ThemeConverterError.noArguments
    }
    self.files = files
  }

  func run() {
    files.forEach { file in
      let src = URL(fileURLWithPath: file).absoluteURL
      let theme = src.deletingPathExtension().lastPathComponent
      let dest = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("dist/\(theme).terminal")

      do {
        try convert(theme: theme, src: src, dest: dest)
      } catch {
        print(error)
      }
    }
  }

  private func convert(theme: String, src: URL, dest: URL) throws {
    guard let iTermScheme = NSDictionary(contentsOf: src) else {
      throw ThemeConverterError.unableToLoadITermFile(src)
    }

    print("Converting `\(src.relativePath)` -> `\(dest.relativePath)`...")

    var converted: [String: Any] = [
      "name": theme,
      "type": "Window Settings",
      "ProfileCurrentVersion": 2.04,
      "BackgroundBlur": 0.0,
      "DisableANSIColor": false,
    ]

    for (iTermColorKey, iTermColorDict) in iTermScheme {
      if let iTermColorKey = iTermColorKey as? String,
        let terminalColorKey = iTermColorToTerminalColorMap[iTermColorKey],
        let iTermColorDict = iTermColorDict as? NSDictionary,

        let r = (iTermColorDict["Red Component"] as? NSNumber)?.floatValue,
        let g = (iTermColorDict["Green Component"] as? NSNumber)?.floatValue,
        let b = (iTermColorDict["Blue Component"] as? NSNumber)?.floatValue
      {

        let color = NSColor(
          calibratedRed: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
        let data = try NSKeyedArchiver.archivedData(
          withRootObject: color, requiringSecureCoding: false)
        converted[terminalColorKey] = data
      }
    }

    NSDictionary(dictionary: converted).write(to: dest, atomically: true)
  }
}

do {
  let files = Array(CommandLine.arguments.dropFirst())
  try ThemeConverter(files: files).run()
} catch {
  print(error)
}
