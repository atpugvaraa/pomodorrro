import SwiftUI

/// How the circuit and car look. Widths are in viewBox units (scaled by camera
/// zoom when drawn). Defaults aim for a light, elegant look with the car as the focus.
struct F1TrackStyle {
    var trackWidth: CGFloat = 13        // asphalt band
    var outlineWidth: CGFloat = 17      // outer border band (border = (outline − track)/2 each side)

    var asphaltColor = Color(white: 0.17)
    var outlineColor = Color(white: 0.62)
    var startLineColor = Color.white
    // Any ShapeStyle — a plain Color or a gradient (e.g. `.green.gradient`).
    var background = AnyShapeStyle(Color(white: 0.10))

    var lapTrailColor = Color(red: 0.90, green: 0.22, blue: 0.27)
    var showsLapTrail = false

    var carSize = CGSize(width: 22, height: 60)
}
