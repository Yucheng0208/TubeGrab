// 由 assets/logo-source.png 產生 App 圖示：
//   assets/AppIcon.png   （1024×1024，透明背景，符合 macOS 圖示格線）
//   assets/AppIcon.icns  （給 .app 使用）
// 用法：swift scripts/make-icon.swift
import AppKit
import CoreGraphics

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let src = root.appendingPathComponent("assets/logo-source.png")
guard let data = try? Data(contentsOf: src), let rep = NSBitmapImageRep(data: data), let cg = rep.cgImage else {
    fatalError("找不到 assets/logo-source.png")
}
let w = cg.width, h = cg.height

// 1. 轉成 RGBA 方便讀像素
let cs = CGColorSpaceCreateDeviceRGB()
var px = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

// 2. 找出彩色圓角方塊的範圍：
//    統計每一列 / 每一行「明顯彩色」的像素數，只保留超過最大值一半的列與行，
//    這樣背景（白色或黑色）和方塊外圍的光暈都不會被算進去
var colCount = [Int](repeating: 0, count: w), rowCount = [Int](repeating: 0, count: h)
for y in 0..<h {
    for x in 0..<w {
        let i = (y * w + x) * 4
        let r = Double(px[i]), g = Double(px[i + 1]), b = Double(px[i + 2])
        let mx = max(r, g, b), mn = min(r, g, b)
        let sat = mx == 0 ? 0 : (mx - mn) / mx
        if sat > 0.3 && mx > 90 { colCount[x] += 1; rowCount[y] += 1 }
    }
}
let colMax = colCount.max() ?? 0, rowMax = rowCount.max() ?? 0
let cols = colCount.indices.filter { colCount[$0] * 2 >= colMax }
let rows = rowCount.indices.filter { rowCount[$0] * 2 >= rowMax }
let minX = cols.first ?? 0, maxX = cols.last ?? w - 1, minY = rows.first ?? 0, maxY = rows.last ?? h - 1
// 取正方形、稍微內縮，避開邊緣的白色光暈
var side = max(maxX - minX, maxY - minY)
let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
let inset = Int(Double(side) * 0.022)
side -= inset * 2
let crop = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
print("圖示範圍：\(Int(crop.minX)),\(Int(crop.minY)) 大小 \(side)px（原圖 \(w)×\(h)）")
guard let cropped = cg.cropping(to: crop) else { fatalError("裁切失敗") }

// 3. 依 macOS 圖示格線：1024 畫布、主體 824×824、圓角約 185（連續曲率）
let canvas = 1024, body: CGFloat = 824, radius: CGFloat = 185
let out = CGContext(data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
out.clear(CGRect(x: 0, y: 0, width: canvas, height: canvas))
let rect = CGRect(x: (CGFloat(canvas) - body) / 2, y: (CGFloat(canvas) - body) / 2, width: body, height: body)
// 底部淡陰影
out.saveGState()
out.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.28).cgColor)
out.addPath(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).cgPath)
out.setFillColor(NSColor.white.cgColor)
out.fillPath()
out.restoreGState()
// 圓角遮罩 + 圖案
out.addPath(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).cgPath)
out.clip()
out.interpolationQuality = .high
out.draw(cropped, in: rect)

let final = out.makeImage()!
let pngURL = root.appendingPathComponent("assets/AppIcon.png")
let png = NSBitmapImageRep(cgImage: final).representation(using: .png, properties: [:])!
try! png.write(to: pngURL)
print("已輸出 \(pngURL.path)")

// 4. 產生 iconset → icns
let iconset = root.appendingPathComponent("assets/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
func resized(_ size: Int) -> Data {
    let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    c.draw(final, in: CGRect(x: 0, y: 0, width: size, height: size))
    return NSBitmapImageRep(cgImage: c.makeImage()!).representation(using: .png, properties: [:])!
}
for base in [16, 32, 128, 256, 512] {
    try! resized(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! resized(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("assets/AppIcon.icns").path]
try! p.run(); p.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(p.terminationStatus == 0 ? "已輸出 assets/AppIcon.icns" : "iconutil 失敗")
