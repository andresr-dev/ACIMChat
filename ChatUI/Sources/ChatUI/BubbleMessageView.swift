import SwiftUI

struct BubbleMessageView: View {
  let message: String
  var tailAlignment: BubbleShape.TailAlignment = .bottomRight
  var backgroundColor: Color = Color(.accent)
  var foregroundColor: Color = .white

  private var shape: BubbleShape { BubbleShape(tailAlignment: tailAlignment) }

  var body: some View {
    Text(message)
      .foregroundStyle(foregroundColor)
      .padding(.horizontal, 14)
      .padding(.top, 10)
      .padding(.bottom, 10 + shape.tailSize.height)
      .background(backgroundColor, in: shape)
  }
}

struct BubbleShape: Shape {
  enum TailAlignment {
    case bottomLeft, bottomRight
  }

  var tailAlignment: TailAlignment
  var cornerRadius: CGFloat = 16
  var tailSize: CGSize = CGSize(width: 14, height: 10)

  func path(in rect: CGRect) -> Path {
    let r = min(cornerRadius, (rect.height - tailSize.height) / 2)
    let tailW = tailSize.width
    let tailH = tailSize.height
    let bodyMaxY = rect.maxY - tailH

    var path = Path()

    switch tailAlignment {
    case .bottomRight:
      // Start just after top-left arc, go clockwise
      path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
      path.addArc(
        center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
      )
      // Right edge straight to tail base — no bottom-right corner arc
      path.addLine(to: CGPoint(x: rect.maxX, y: bodyMaxY))
      // Tail tip
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      // Back up to bottom edge
      path.addLine(to: CGPoint(x: rect.maxX - tailW, y: bodyMaxY))
      // Bottom edge leftward
      path.addLine(to: CGPoint(x: rect.minX + r, y: bodyMaxY))
      path.addArc(
        center: CGPoint(x: rect.minX + r, y: bodyMaxY - r),
        radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
      )
      // Left edge upward
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
      path.addArc(
        center: CGPoint(x: rect.minX + r, y: rect.minY + r),
        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
      )

    case .bottomLeft:
      // Start just after top-left arc, go clockwise
      path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
      path.addArc(
        center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
      )
      // Right edge
      path.addLine(to: CGPoint(x: rect.maxX, y: bodyMaxY - r))
      path.addArc(
        center: CGPoint(x: rect.maxX - r, y: bodyMaxY - r),
        radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
      )
      // Bottom edge rightward, stop before tail base
      path.addLine(to: CGPoint(x: rect.minX + tailW, y: bodyMaxY))
      // Tail tip
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      // Left edge straight up — no bottom-left corner arc
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
      path.addArc(
        center: CGPoint(x: rect.minX + r, y: rect.minY + r),
        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
      )
    }

    path.closeSubpath()
    return path
  }
}

#Preview {
  VStack(spacing: 24) {
    HStack {
      Spacer()
      BubbleMessageView(message: "Yeah 👍", tailAlignment: .bottomRight)
    }
    HStack {
      BubbleMessageView(
        message: "Hello! How can I help you today?",
        tailAlignment: .bottomLeft,
        backgroundColor: Color(.secondarySystemBackground),
        foregroundColor: .primary
      )
      Spacer()
    }
  }
  .padding()
}
