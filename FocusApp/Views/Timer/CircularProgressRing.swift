import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    let ringColor: Color
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .inset(by: lineWidth / 2)
                .stroke(Color.appDivider, lineWidth: lineWidth)
            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
