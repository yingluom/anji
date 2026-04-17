import SwiftUI
import Sharing

/// Appearance settings — language, theme, accent color.
struct AppearanceSection: View {
    @Shared(.preferredLanguage) private var language
    @Shared(.appTheme) private var theme
    @Shared(.accentPreset) private var accent

    @State private var showRelaunchAlert = false

    var body: some View {
        Section {
            // Language picker
            Picker(selection: Binding(
                get: { language },
                set: { newValue in
                    let changed = newValue != language
                    $language.withLock { $0 = newValue }
                    if changed {
                        LanguageManager.apply(newValue)
                        showRelaunchAlert = true
                    }
                }
            )) {
                ForEach(PreferredLanguage.allCases, id: \.self) { lang in
                    Text(lang.titleKey).tag(lang)
                }
            } label: {
                Label("settings.language", systemImage: "globe")
            }

            // Theme picker
            Picker(selection: Binding(
                get: { theme },
                set: { newValue in $theme.withLock { $0 = newValue } }
            )) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    Text(t.titleKey).tag(t)
                }
            } label: {
                Label("settings.theme", systemImage: "moon.circle")
            }
        } header: {
            Text("settings.section.appearance")
        }

        Section {
            accentGrid
        } header: {
            Text("settings.accent_color")
        } footer: {
            Text("settings.accent_color.footer")
        }
        .alert("settings.relaunch.title", isPresented: $showRelaunchAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("settings.relaunch.message")
        }
    }

    private var accentGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            ForEach(AccentPreset.allCases, id: \.self) { preset in
                Button {
                    $accent.withLock { $0 = preset }
                } label: {
                    ZStack {
                        Circle().fill(preset.color).frame(width: 38, height: 38)
                        if accent == preset {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
