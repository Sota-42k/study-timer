import SwiftUI

struct LapListView: View {
    let laps: [FocusSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !laps.isEmpty {
                Text("Sessions")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(laps.enumerated()), id: \.element.id) { _, session in
                            LapRow(session: session, number: laps.count - (laps.firstIndex(where: { $0.id == session.id }) ?? 0))
                            Divider().opacity(0.15)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct LapRow: View {
    let session: FocusSession
    let number: Int

    var body: some View {
        HStack {
            Text("#\(number)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.textSecondary)
                .frame(width: 32, alignment: .leading)
            Text(formatDuration(session.duration))
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(DateFormatter.timeOnly.string(from: session.endDate))
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
