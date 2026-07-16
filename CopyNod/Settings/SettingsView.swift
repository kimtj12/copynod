import SwiftUI

/// 작은 설정 창 1개 (planning.md 2.4)
struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    let checkForUpdates: () -> Void

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                Picker("HUD Position", selection: $store.hudPosition) {
                    ForEach(HUDPosition.allCases, id: \.self) { position in
                        Text(position.label).tag(position)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.set(newValue)
                        launchAtLogin = LaunchAtLogin.isEnabled  // 실패 시 실제 상태로 복원
                    }
                Toggle("Hide Menu Bar Icon", isOn: $store.hideMenuBarIcon)
                if store.hideMenuBarIcon {
                    Text("To open settings again, launch CopyNod from Spotlight or Launchpad.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent("Version \(version)") {
                    Button(action: checkForUpdates) {
                        Text("Check for Updates…")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }
}
