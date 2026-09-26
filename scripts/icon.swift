import AppKit
let target = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
NSColor(calibratedRed:0.94,green:0.94,blue:0.91,alpha:1).setFill()
NSBezierPath(roundedRect:NSRect(x:30,y:30,width:964,height:964),xRadius:215,yRadius:215).fill()
NSColor(calibratedRed:0.17,green:0.19,blue:0.18,alpha:1).setFill()
NSBezierPath(roundedRect:NSRect(x:164,y:164,width:696,height:696),xRadius:160,yRadius:160).fill()
NSColor(calibratedRed:0.96,green:0.46,blue:0.28,alpha:1).setStroke()
let path = NSBezierPath(); path.lineWidth=37; path.lineCapStyle = .round; path.lineJoinStyle = .round
let points:[NSPoint] = [NSPoint(x:285,y:510),NSPoint(x:342,y:510),NSPoint(x:377,y:630),NSPoint(x:423,y:363),NSPoint(x:478,y:715),NSPoint(x:535,y:319),NSPoint(x:592,y:646),NSPoint(x:641,y:434),NSPoint(x:677,y:510),NSPoint(x:739,y:510)]
path.move(to:points[0]);for p in points.dropFirst(){path.line(to:p)};path.stroke()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data:image.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:target))
