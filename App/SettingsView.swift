import SwiftUI

/// Video Info → Settings… (⌘,)
struct SettingsView: View {
    @State private var quickLook = SharedSettings.quickLookEnabled

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $quickLook) {
                    Text("Show in Quick Look")
                    Text("Press Space on an MKV, AVI or WMV in Finder to see its info. MP4 and MOV always use Apple's player.")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize()
        .onChange(of: quickLook) { _, on in
            SharedSettings.quickLookEnabled = on // the preview extension reads this
        }
    }
}
