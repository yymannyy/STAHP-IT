import AppKit
import CoreGraphics

func createSquirclePath(in rect: CGRect, cornerRadius: CGFloat) -> NSBezierPath {
    return NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
}

func createOctagonPath(in rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    let w = rect.width
    let inset: CGFloat = w * 0.2929 // 1 - 1/sqrt(2)
    
    let p1 = CGPoint(x: rect.minX + inset, y: rect.maxY)
    let p2 = CGPoint(x: rect.maxX - inset, y: rect.maxY)
    let p3 = CGPoint(x: rect.maxX, y: rect.maxY - inset)
    let p4 = CGPoint(x: rect.maxX, y: rect.minY + inset)
    let p5 = CGPoint(x: rect.maxX - inset, y: rect.minY)
    let p6 = CGPoint(x: rect.minX + inset, y: rect.minY)
    let p7 = CGPoint(x: rect.minX, y: rect.minY + inset)
    let p8 = CGPoint(x: rect.minX, y: rect.maxY - inset)
    
    path.move(to: p1)
    path.line(to: p2)
    path.line(to: p3)
    path.line(to: p4)
    path.line(to: p5)
    path.line(to: p6)
    path.line(to: p7)
    path.line(to: p8)
    path.close()
    return path
}

func renderDesignerMacOSAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let scale = size / 1024.0
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // -------------------------------------------------------------
    // 1. Standard macOS Squircle Canvas Geometry (824 x 824 on 1024)
    // -------------------------------------------------------------
    let squircleInset: CGFloat = 100 * scale
    let squircleSize: CGFloat = size - (2 * squircleInset)
    let cornerRadius: CGFloat = 185 * scale
    let squircleRect = CGRect(x: squircleInset, y: squircleInset, width: squircleSize, height: squircleSize)
    
    // -------------------------------------------------------------
    // 2. Stopwatch Hardware Crown (Top Chronometer Pusher)
    // -------------------------------------------------------------
    ctx.saveGState()
    let crownWidth: CGFloat = 96 * scale
    let crownHeight: CGFloat = 46 * scale
    let crownRect = CGRect(x: squircleRect.midX - (crownWidth / 2), y: squircleRect.maxY - (14 * scale), width: crownWidth, height: crownHeight)
    let crownPath = NSBezierPath(roundedRect: crownRect, xRadius: 10 * scale, yRadius: 10 * scale)
    
    // Crown 3D shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -6 * scale), blur: 10 * scale, color: NSColor.black.withAlphaComponent(0.40).cgColor)
    
    // Metallic chrome gradient
    let chromeColors = [
        NSColor(white: 0.98, alpha: 1.0).cgColor,
        NSColor(white: 0.65, alpha: 1.0).cgColor,
        NSColor(white: 0.88, alpha: 1.0).cgColor,
        NSColor(white: 0.50, alpha: 1.0).cgColor
    ] as CFArray
    let chromeLocations: [CGFloat] = [0.0, 0.35, 0.70, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: chromeColors, locations: chromeLocations) {
        ctx.saveGState()
        crownPath.addClip()
        ctx.drawLinearGradient(gradient, start: CGPoint(x: crownRect.minX, y: crownRect.midY), end: CGPoint(x: crownRect.maxX, y: crownRect.midY), options: [])
        
        // Crown knurled texture lines
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(2.0 * scale)
        for i in 1...6 {
            let xPos = crownRect.minX + (CGFloat(i) * (crownWidth / 7))
            ctx.move(to: CGPoint(x: xPos, y: crownRect.minY))
            ctx.addLine(to: CGPoint(x: xPos, y: crownRect.maxY))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    
    // Crown red jewel accent
    let jewelRect = CGRect(x: crownRect.midX - (18 * scale), y: crownRect.maxY - (5 * scale), width: 36 * scale, height: 6 * scale)
    let jewelPath = NSBezierPath(roundedRect: jewelRect, xRadius: 3 * scale, yRadius: 3 * scale)
    NSColor(red: 1.0, green: 0.15, blue: 0.25, alpha: 1.0).setFill()
    jewelPath.fill()
    ctx.restoreGState()
    
    // -------------------------------------------------------------
    // 3. Multi-Tiered macOS 3D Drop Shadow for Squircle
    // -------------------------------------------------------------
    let squirclePath = createSquirclePath(in: squircleRect, cornerRadius: cornerRadius)
    
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -26 * scale), blur: 34 * scale, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    NSColor.black.setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 12 * scale, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    NSColor.black.setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // -------------------------------------------------------------
    // 4. Vibrant Radiant Apple Red Squircle Base
    // -------------------------------------------------------------
    ctx.saveGState()
    squirclePath.addClip()
    
    let redColors = [
        NSColor(red: 1.00, green: 0.26, blue: 0.30, alpha: 1.0).cgColor, // Top radiant coral #FF424D
        NSColor(red: 0.92, green: 0.08, blue: 0.14, alpha: 1.0).cgColor, // Mid vibrant red #EB1424
        NSColor(red: 0.74, green: 0.02, blue: 0.08, alpha: 1.0).cgColor, // Lower crimson #BD0514
        NSColor(red: 0.52, green: 0.00, blue: 0.06, alpha: 1.0).cgColor  // Bottom dark vignette #85000F
    ] as CFArray
    let redLocations: [CGFloat] = [0.0, 0.35, 0.75, 1.0]
    
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: redColors, locations: redLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY), end: CGPoint(x: squircleRect.midX, y: squircleRect.minY), options: [])
    }
    
    // Center spotlight glow
    if let spotGrad = CGGradient(colorsSpace: colorSpace, colors: [NSColor(red: 1.0, green: 0.45, blue: 0.50, alpha: 0.35).cgColor, NSColor.clear.cgColor] as CFArray, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(spotGrad, startCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY + (40 * scale)), startRadius: 10 * scale, endCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY), endRadius: 360 * scale, options: [])
    }
    
    // -------------------------------------------------------------
    // 5. Classic Traffic Stop Sign Octagonal Inner Framing
    // -------------------------------------------------------------
    let octInset: CGFloat = 50 * scale
    let octRect = squircleRect.insetBy(dx: octInset, dy: octInset)
    let octPath = createOctagonPath(in: octRect)
    
    // Octagon Outer Rim Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4 * scale), blur: 8 * scale, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    NSColor.white.withAlphaComponent(0.95).setStroke()
    octPath.lineWidth = 14 * scale
    octPath.stroke()
    ctx.restoreGState()
    
    // Inner Octagonal Accent Line
    let innerOctRect = octRect.insetBy(dx: 18 * scale, dy: 18 * scale)
    let innerOctPath = createOctagonPath(in: innerOctRect)
    NSColor.white.withAlphaComponent(0.40).setStroke()
    innerOctPath.lineWidth = 2.5 * scale
    innerOctPath.stroke()
    
    // Corner Chronometer Tick Marks
    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.45).cgColor)
    ctx.setLineWidth(2.0 * scale)
    let tickRadius: CGFloat = (innerOctRect.width / 2) - (6 * scale)
    let center = CGPoint(x: innerOctRect.midX, y: innerOctRect.midY)
    for i in 0..<12 {
        let angle = CGFloat(i) * (.pi / 6.0)
        let innerR = tickRadius - (6 * scale)
        let pStart = CGPoint(x: center.x + innerR * cos(angle), y: center.y + innerR * sin(angle))
        let pEnd = CGPoint(x: center.x + tickRadius * cos(angle), y: center.y + tickRadius * sin(angle))
        ctx.move(to: pStart)
        ctx.addLine(to: pEnd)
        ctx.strokePath()
    }
    ctx.restoreGState()
    
    // -------------------------------------------------------------
    // 6. Bold Typography: "STAHP" & "IT!" (SF Pro Rounded Black)
    // -------------------------------------------------------------
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let font1 = NSFont.systemFont(ofSize: 155 * scale, weight: .black)
    let text1 = "STAHP"
    let attrs1: [NSAttributedString.Key: Any] = [
        .font: font1,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle,
        .kern: 3.5 * scale
    ]
    
    let font2 = NSFont.systemFont(ofSize: 165 * scale, weight: .black)
    let text2 = "IT!"
    let attrs2: [NSAttributedString.Key: Any] = [
        .font: font2,
        .foregroundColor: NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0),
        .paragraphStyle: paragraphStyle,
        .kern: 5.0 * scale
    ]
    
    let text1Size = (text1 as NSString).size(withAttributes: attrs1)
    let text2Size = (text2 as NSString).size(withAttributes: attrs2)
    
    let spacing: CGFloat = 2 * scale
    let totalTextHeight = text1Size.height + text2Size.height + spacing
    let startY = squircleRect.midY + (totalTextHeight / 2) - text1Size.height + (8 * scale)
    
    let rect1 = CGRect(x: squircleRect.minX, y: startY, width: squircleRect.width, height: text1Size.height)
    let rect2 = CGRect(x: squircleRect.minX, y: startY - text2Size.height - spacing, width: squircleRect.width, height: text2Size.height)
    
    // Text Drop Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4 * scale), blur: 8 * scale, color: NSColor.black.withAlphaComponent(0.55).cgColor)
    (text1 as NSString).draw(in: rect1, withAttributes: attrs1)
    (text2 as NSString).draw(in: rect2, withAttributes: attrs2)
    ctx.restoreGState()
    
    // Crisp White Fill
    (text1 as NSString).draw(in: rect1, withAttributes: attrs1)
    (text2 as NSString).draw(in: rect2, withAttributes: attrs2)
    
    // -------------------------------------------------------------
    // 7. Signature macOS Curved Specular Glass Sheen
    // -------------------------------------------------------------
    let glossPath = NSBezierPath()
    glossPath.move(to: CGPoint(x: squircleRect.minX, y: squircleRect.maxY))
    glossPath.line(to: CGPoint(x: squircleRect.maxX, y: squircleRect.maxY))
    glossPath.line(to: CGPoint(x: squircleRect.maxX, y: squircleRect.midY + (80 * scale)))
    glossPath.curve(
        to: CGPoint(x: squircleRect.minX, y: squircleRect.midY + (180 * scale)),
        controlPoint1: CGPoint(x: squircleRect.midX + (100 * scale), y: squircleRect.midY + (60 * scale)),
        controlPoint2: CGPoint(x: squircleRect.midX - (100 * scale), y: squircleRect.midY + (160 * scale))
    )
    glossPath.close()
    
    let glossColors = [
        NSColor.white.withAlphaComponent(0.24).cgColor,
        NSColor.white.withAlphaComponent(0.04).cgColor
    ] as CFArray
    if let glossGradient = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        glossPath.addClip()
        ctx.drawLinearGradient(glossGradient, start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY), end: CGPoint(x: squircleRect.midX, y: squircleRect.midY), options: [])
        ctx.restoreGState()
    }
    
    ctx.restoreGState() // restore squircle clip
    
    // -------------------------------------------------------------
    // 8. macOS Continuous Top Rim Specular Highlight (1.5pt Studio Light)
    // -------------------------------------------------------------
    ctx.saveGState()
    let rimColors = [
        NSColor.white.withAlphaComponent(0.55).cgColor,
        NSColor.white.withAlphaComponent(0.18).cgColor,
        NSColor.white.withAlphaComponent(0.02).cgColor
    ] as CFArray
    let rimLocations: [CGFloat] = [0.0, 0.4, 1.0]
    if let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: rimLocations) {
        ctx.saveGState()
        squirclePath.lineWidth = 2.0 * scale
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(rimGradient, start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY), end: CGPoint(x: squircleRect.midX, y: squircleRect.minY), options: [])
        ctx.restoreGState()
    }
    ctx.restoreGState()
    
    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to convert image to PNG for \(path)")
        return
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = renderDesignerMacOSAppIcon(size: size)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
    print("Generated \(name) (\(Int(size))x\(Int(size)))")
}

print("Designer macOS iconset generated successfully.")
