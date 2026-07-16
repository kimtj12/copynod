import SwiftUI

/// 최초 실행 시 Accessibility 권한 안내 (planning.md 4절)
struct OnboardingView: View {
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("CopyNod needs Accessibility access")
                .font(.title3)
                .bold()
            Text("CopyNod shows a small checkmark when ⌘C or ⌘X actually copies something. Detecting those keys requires Accessibility access. CopyNod never reads your clipboard contents.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: openSettings) {
                Text("Open System Settings…")
            }
            .keyboardShortcut(.defaultAction)
            Text("Enable CopyNod under Privacy & Security → Accessibility.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 400)
    }
}
