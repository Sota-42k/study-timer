import SwiftUI

struct CycleProgressBar: View {
    let vm: TimerViewModel

    @AppStorage(UserDefaultsKeys.focusDuration)      private var focusDuration: Double = 1500
    @AppStorage(UserDefaultsKeys.shortBreakDuration) private var shortBreakDuration: Double = 300
    @AppStorage(UserDefaultsKeys.longBreakDuration)  private var longBreakDuration: Double = 1800
    @AppStorage(UserDefaultsKeys.sessionsBeforeLong) private var lapsPerCycle: Int = 4
    @AppStorage(UserDefaultsKeys.cycleCount)          private var cycleCount: Int = 1

    private struct Segment {
        let type: SessionType
        let duration: TimeInterval
    }

    private var segments: [Segment] {
        let laps   = max(lapsPerCycle, 1)
        let cycles = max(cycleCount, 1)
        var result: [Segment] = []
        for _ in 0..<cycles {
            for lap in 1...laps {
                result.append(Segment(type: .focus, duration: max(focusDuration, 1)))
                if lap < laps {
                    result.append(Segment(type: .shortBreak, duration: max(shortBreakDuration, 1)))
                } else {
                    result.append(Segment(type: .longBreak, duration: max(longBreakDuration, 1)))
                }
            }
        }
        return result
    }

    var body: some View {
        let segs = segments
        let total = segs.reduce(0.0) { $0 + $1.duration }
        let currentIdx = vm.currentPhaseIndex
        let barH:  CGFloat = 5
        let triH:  CGFloat = 7
        let vGap:  CGFloat = 3
        let segGap: CGFloat = segs.count > 1 ? 1.5 : 0

        GeometryReader { geo in
            let w = geo.size.width
            let usable = w - segGap * CGFloat(segs.count - 1)

            // Cumulative center x for each segment
            var acc: CGFloat = 0
            let centers: [CGFloat] = segs.indices.map { i in
                let sw = CGFloat(segs[i].duration / total) * usable
                let cx = acc + segGap * CGFloat(i) + sw / 2
                acc += sw
                return cx
            }

            ZStack(alignment: .topLeading) {
                // Proportional phase bar
                HStack(spacing: segGap) {
                    ForEach(Array(segs.enumerated()), id: \.offset) { idx, seg in
                        let sw = max(0, CGFloat(seg.duration / total) * usable)
                        Rectangle()
                            .fill(segmentColor(for: seg.type, lit: idx <= (currentIdx ?? -1)))
                            .frame(width: sw, height: barH)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 2.5))
                .frame(width: w)
                .offset(y: triH + vGap)

                // Triangle indicator
                if let idx = currentIdx, idx >= 0, idx < centers.count {
                    DownwardTriangle()
                        .fill(Color.black)
                        .frame(width: triH, height: triH * 0.75)
                        .offset(x: centers[idx] - triH / 2)
                        .animation(.easeInOut(duration: 0.35), value: currentIdx)
                }
            }
        }
        .frame(height: barH + triH + vGap)
    }

    private func segmentColor(for type: SessionType, lit: Bool) -> Color {
        let base: Color
        switch type {
        case .focus:      base = .focusRing
        case .shortBreak: base = .breakRing
        case .longBreak:  base = .longBreakRing
        }
        return lit ? base : base.opacity(0.18)
    }
}

private struct DownwardTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
