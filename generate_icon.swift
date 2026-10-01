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
    
    // -----------------------------------------------------------------
    // 1. Apple macOS Canonical Squircle Canvas Geometry (824 x 824 pt)
    // -----------------------------------------------------------------
    let squircleInset: CGFloat = 100 * scale
    let squircleSize: CGFloat = size - (2 * squircleInset)
    let cornerRadius: CGFloat = 185 * scale
    let squircleRect = CGRect(x: squircleInset, y: squircleInset, width: squircleSize, height: squircleSize)
    
    // -----------------------------------------------------------------
    // 2. Hardware Chronometer Crown & Pusher (Stainless Steel & Ruby)
    // -----------------------------------------------------------------
    ctx.saveGState()
    let crownWidth: CGFloat = 104 * scale
    let crownHeight: CGFloat = 48 * scale
    let crownRect = CGRect(
        x: squircleRect.midX - (crownWidth / 2),
        y: squircleRect.maxY - (12 * scale),
        width: crownWidth,
        height: crownHeight
    )
    let crownPath = NSBezierPath(roundedRect: crownRect, xRadius: 10 * scale, yRadius: 10 * scale)
    
    // Crown ambient drop shadow
    ctx.setShadow(
        offset: CGSize(width: 0, height: -6 * scale),
        blur: 12 * scale,
        color: NSColor.black.withAlphaComponent(0.45).cgColor
    )
    
    // Machined metallic chrome gradient
    let chromeColors = [
        NSColor(white: 0.98, alpha: 1.0).cgColor,
        NSColor(white: 0.62, alpha: 1.0).cgColor,
        NSColor(white: 0.90, alpha: 1.0).cgColor,
        NSColor(white: 0.48, alpha: 1.0).cgColor,
        NSColor(white: 0.85, alpha: 1.0).cgColor
    ] as CFArray
    let chromeLocations: [CGFloat] = [0.0, 0.25, 0.50, 0.75, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: chromeColors, locations: chromeLocations) {
        ctx.saveGState()
        crownPath.addClip()
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: crownRect.minX, y: crownRect.midY),
            end: CGPoint(x: crownRect.maxX, y: crownRect.midY),
            options: []
        )
        
        // Mechanical knurled grip lines
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(2.2 * scale)
        for i in 1...7 {
            let xPos = crownRect.minX + (CGFloat(i) * (crownWidth / 8))
            ctx.move(to: CGPoint(x: xPos, y: crownRect.minY))
            ctx.addLine(to: CGPoint(x: xPos, y: crownRect.maxY))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    
    // Crown ruby jewel button cap
    let jewelRect = CGRect(
        x: crownRect.midX - (22 * scale),
        y: crownRect.maxY - (6 * scale),
        width: 44 * scale,
        height: 7 * scale
    )
    let jewelPath = NSBezierPath(roundedRect: jewelRect, xRadius: 3.5 * scale, yRadius: 3.5 * scale)
    NSColor(red: 1.0, green: 0.18, blue: 0.26, alpha: 1.0).setFill()
    jewelPath.fill()
    
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 3. Multi-Tiered macOS 3D Drop Shadows (HIG Elevation)
    // -----------------------------------------------------------------
    let squirclePath = createSquirclePath(in: squircleRect, cornerRadius: cornerRadius)
    
    // Deep ambient floor shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -28 * scale),
        blur: 36 * scale,
        color: NSColor.black.withAlphaComponent(0.48).cgColor
    )
    NSColor.black.setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // Key directional contact shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -10 * scale),
        blur: 14 * scale,
        color: NSColor.black.withAlphaComponent(0.32).cgColor
    )
    NSColor.black.setFill()
    squirclePath.fill()
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 4. Squircle Body: Radiant Apple Red & Deep Crimson Vignette
    // -----------------------------------------------------------------
    ctx.saveGState()
    squirclePath.addClip()
    
    let baseRedColors = [
        NSColor(red: 1.00, green: 0.28, blue: 0.32, alpha: 1.0).cgColor, // Top coral red #FF4752
        NSColor(red: 0.94, green: 0.10, blue: 0.16, alpha: 1.0).cgColor, // Mid vibrant red #F01A29
        NSColor(red: 0.78, green: 0.04, blue: 0.10, alpha: 1.0).cgColor, // Crimson shadow #C70A1A
        NSColor(red: 0.50, green: 0.00, blue: 0.06, alpha: 1.0).cgColor  // Bottom dark vignette #80000F
    ] as CFArray
    let baseRedLocations: [CGFloat] = [0.0, 0.32, 0.72, 1.0]
    
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: baseRedColors, locations: baseRedLocations) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
            options: []
        )
    }
    
    // Radial top-center spotlight
    if let spotGrad = CGGradient(
        colorsSpace: colorSpace,
        colors: [NSColor(red: 1.0, green: 0.50, blue: 0.55, alpha: 0.40).cgColor, NSColor.clear.cgColor] as CFArray,
        locations: [0.0, 1.0]
    ) {
        ctx.drawRadialGradient(
            spotGrad,
            startCenter: CGPoint(x: squircleRect.midX, y: squircleRect.maxY - (120 * scale)),
            startRadius: 20 * scale,
            endCenter: CGPoint(x: squircleRect.midX, y: squircleRect.midY),
            endRadius: 440 * scale,
            options: []
        )
    }
    
    // -----------------------------------------------------------------
    // 5. Inset Circular Chronometer Dial with Guilloché Grooves
    // -----------------------------------------------------------------
    let dialDiameter: CGFloat = squircleSize * 0.78
    let dialRect = CGRect(
        x: squircleRect.midX - (dialDiameter / 2),
        y: squircleRect.midY - (dialDiameter / 2),
        width: dialDiameter,
        height: dialDiameter
    )
    let dialCenter = CGPoint(x: dialRect.midX, y: dialRect.midY)
    
    // Concentric Guilloché rings
    ctx.saveGState()
    for ring in 1...4 {
        let r = (dialDiameter / 2) - (CGFloat(ring) * 16 * scale)
        let ringPath = NSBezierPath(
            ovalIn: CGRect(x: dialCenter.x - r, y: dialCenter.y - r, width: r * 2, height: r * 2)
        )
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
        ctx.setLineWidth(1.0 * scale)
        ringPath.stroke()
    }
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 6. Chronometer 60-Tick Marks & 12-Hour Markers
    // -----------------------------------------------------------------
    ctx.saveGState()
    let outerTickRadius = (dialDiameter / 2) - (8 * scale)
    for i in 0..<60 {
        let isMajor = (i % 5 == 0)
        let angle = CGFloat(i) * (2.0 * .pi / 60.0)
        let tickLen: CGFloat = isMajor ? (14 * scale) : (7 * scale)
        let innerR = outerTickRadius - tickLen
        
        let pStart = CGPoint(x: dialCenter.x + innerR * cos(angle), y: dialCenter.y + innerR * sin(angle))
        let pEnd = CGPoint(x: dialCenter.x + outerTickRadius * cos(angle), y: dialCenter.y + outerTickRadius * sin(angle))
        
        ctx.move(to: pStart)
        ctx.addLine(to: pEnd)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(isMajor ? 0.85 : 0.35).cgColor)
        ctx.setLineWidth(isMajor ? (3.0 * scale) : (1.4 * scale))
        ctx.setLineCap(.round)
        ctx.strokePath()
    }
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 7. Dynamic Island Notch Accent Symbol (Top Center of Dial)
    // -----------------------------------------------------------------
    let islandW: CGFloat = 130 * scale
    let islandH: CGFloat = 28 * scale
    let islandRect = CGRect(
        x: dialCenter.x - (islandW / 2),
        y: dialRect.maxY - (54 * scale),
        width: islandW,
        height: islandH
    )
    let islandPath = NSBezierPath(roundedRect: islandRect, xRadius: 14 * scale, yRadius: 14 * scale)
    
    ctx.saveGState()
    NSColor.black.withAlphaComponent(0.65).setFill()
    islandPath.fill()
    
    // Notch subtle rim stroke
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
    ctx.setLineWidth(1.2 * scale)
    islandPath.stroke()
    
    // Notch camera dot & live green LED indicator
    let camRect = CGRect(x: islandRect.midX - (16 * scale), y: islandRect.midY - (4 * scale), width: 8 * scale, height: 8 * scale)
    NSColor.white.withAlphaComponent(0.25).setFill()
    NSBezierPath(ovalIn: camRect).fill()
    
    let ledRect = CGRect(x: islandRect.midX + (8 * scale), y: islandRect.midY - (4 * scale), width: 8 * scale, height: 8 * scale)
    NSColor(red: 0.18, green: 0.88, blue: 0.35, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: ledRect).fill()
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 8. Classic Octagonal Stop Sign Inner Bezel
    // -----------------------------------------------------------------
    let octInset: CGFloat = 72 * scale
    let octRect = squircleRect.insetBy(dx: octInset, dy: octInset)
    let octPath = createOctagonPath(in: octRect)
    
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -4 * scale),
        blur: 8 * scale,
        color: NSColor.black.withAlphaComponent(0.40).cgColor
    )
    NSColor.white.withAlphaComponent(0.92).setStroke()
    octPath.lineWidth = 12 * scale
    octPath.stroke()
    ctx.restoreGState()
    
    // -----------------------------------------------------------------
    // 9. Bold Apple SF Pro Rounded Typography: "STAHP" & "IT!"
    // -----------------------------------------------------------------
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let font1 = NSFont.systemFont(ofSize: 142 * scale, weight: .black)
    let text1 = "STAHP"
    let attrs1: [NSAttributedString.Key: Any] = [
        .font: font1,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle,
        .kern: 3.0 * scale
    ]
    
    let font2 = NSFont.systemFont(ofSize: 152 * scale, weight: .black)
    let text2 = "IT!"
    let attrs2: [NSAttributedString.Key: Any] = [
        .font: font2,
        .foregroundColor: NSColor(red: 1.0, green: 0.96, blue: 0.96, alpha: 1.0),
        .paragraphStyle: paragraphStyle,
        .kern: 4.5 * scale
    ]
    
    let text1Size = (text1 as NSString).size(withAttributes: attrs1)
    let text2Size = (text2 as NSString).size(withAttributes: attrs2)
    
    let textSpacing: CGFloat = 2 * scale
    let totalTextHeight = text1Size.height + text2Size.height + textSpacing
    let startY = squircleRect.midY + (totalTextHeight / 2) - text1Size.height - (6 * scale)
    
    let rect1 = CGRect(x: squircleRect.minX, y: startY, width: squircleRect.width, height: text1Size.height)
    let rect2 = CGRect(x: squircleRect.minX, y: startY - text2Size.height - textSpacing, width: squircleRect.width, height: text2Size.height)
    
    // Text 3D drop shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -5 * scale),
        blur: 10 * scale,
        color: NSColor.black.withAlphaComponent(0.55).cgColor
    )
    (text1 as NSString).draw(in: rect1, withAttributes: attrs1)
    (text2 as NSString).draw(in: rect2, withAttributes: attrs2)
    ctx.restoreGState()
    
    // Crisp white foreground text
    (text1 as NSString).draw(in: rect1, withAttributes: attrs1)
    (text2 as NSString).draw(in: rect2, withAttributes: attrs2)
    
    // -----------------------------------------------------------------
    // 10. macOS Signature Curved Specular Glass Sheen
    // -----------------------------------------------------------------
    let glossPath = NSBezierPath()
    glossPath.move(to: CGPoint(x: squircleRect.minX, y: squircleRect.maxY))
    glossPath.line(to: CGPoint(x: squircleRect.maxX, y: squircleRect.maxY))
    glossPath.line(to: CGPoint(x: squircleRect.maxX, y: squircleRect.midY + (70 * scale)))
    glossPath.curve(
        to: CGPoint(x: squircleRect.minX, y: squircleRect.midY + (170 * scale)),
        controlPoint1: CGPoint(x: squircleRect.midX + (90 * scale), y: squircleRect.midY + (50 * scale)),
        controlPoint2: CGPoint(x: squircleRect.midX - (90 * scale), y: squircleRect.midY + (150 * scale))
    )
    glossPath.close()
    
    let glossColors = [
        NSColor.white.withAlphaComponent(0.25).cgColor,
        NSColor.white.withAlphaComponent(0.03).cgColor
    ] as CFArray
    if let glossGradient = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        glossPath.addClip()
        ctx.drawLinearGradient(
            glossGradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.midY),
            options: []
        )
        ctx.restoreGState()
    }
    
    ctx.restoreGState() // restore squircle clip
    
    // -----------------------------------------------------------------
    // 11. Continuous Top Rim Specular Highlight (macOS Studio Light)
    // -----------------------------------------------------------------
    ctx.saveGState()
    let rimColors = [
        NSColor.white.withAlphaComponent(0.60).cgColor,
        NSColor.white.withAlphaComponent(0.20).cgColor,
        NSColor.white.withAlphaComponent(0.02).cgColor
    ] as CFArray
    let rimLocations: [CGFloat] = [0.0, 0.35, 1.0]
    if let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: rimLocations) {
        ctx.saveGState()
        squirclePath.lineWidth = 2.0 * scale
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        ctx.drawLinearGradient(
            rimGradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
            options: []
        )
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
