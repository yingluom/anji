import SwiftUI
import AnkiBackend
import AnkiKit
import Dependencies
import Logging
import Sharing
import MachO

/// Enhanced debug tools for developers and power users.
struct DebugView: View {
    @Dependency(\.ankiBackend) private var backend
    @Dependency(\.collectionService) private var collectionService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("debugUnlocked") private var debugUnlocked = false

    // App Info
    @State private var collectionPath = ""
    @State private var mediaPath = ""
    @State private var lastSync = "N/A"

    // Database Stats
    @State private var totalCards = 0
    @State private var totalNotes = 0
    @State private var totalDecks = 0
    @State private var dbSize: Int64 = 0

    // Media Stats
    @State private var mediaFileCount = 0
    @State private var mediaTotalSize: Int64 = 0

    // System Info
    @State private var memoryUsage = ""
    @State private var diskFree = ""

    // Actions
    @State private var showingResetAlert = false
    @State private var showingExportAlert = false
    @State private var toastMessage: String?

    var body: some View {
        List {
            // MARK: - App Info
            Section {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
                LabeledContent("iOS", value: UIDevice.current.systemVersion)
                LabeledContent("Device", value: UIDevice.current.model)
                LabeledContent("Anki Protocol", value: "anki/anki#6038")
            } header: {
                Text("App Information")
            }

            // MARK: - Database Stats
            Section {
                LabeledContent("Cards", value: "\(totalCards)")
                LabeledContent("Notes", value: "\(totalNotes)")
                LabeledContent("Decks", value: "\(totalDecks)")
                LabeledContent("DB Size", value: formatBytes(dbSize))

                Button("Refresh Stats") {
                    loadDatabaseStats()
                }
                .font(.caption)
            } header: {
                Text("Collection Stats")
            }

            // MARK: - Media Stats
            Section {
                LabeledContent("Files", value: "\(mediaFileCount)")
                LabeledContent("Total Size", value: formatBytes(mediaTotalSize))

                Button("Recalculate") {
                    loadMediaStats()
                }
                .font(.caption)
            } header: {
                Text("Media Library")
            }

            // MARK: - System
            Section {
                LabeledContent("Memory", value: memoryUsage)
                LabeledContent("Free Disk", value: diskFree)
            } header: {
                Text("System Resources")
            }

            // MARK: - Paths
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Collection").font(.caption).foregroundStyle(.secondary)
                    Text(collectionPath)
                        .font(.caption2)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Media").font(.caption).foregroundStyle(.secondary)
                    Text(mediaPath)
                        .font(.caption2)
                        .textSelection(.enabled)
                }
            } header: {
                Text("File Paths")
            }

            // MARK: - Maintenance
            Section {
                Button {
                    performDatabaseCheck()
                } label: {
                    Label("Check Database Integrity", systemImage: "stethoscope")
                }

                Button {
                    URLCache.shared.removeAllCachedResponses()
                    showToast("URL cache cleared")
                } label: {
                    Label("Clear URL Cache", systemImage: "xmark.circle")
                }

                Button {
                    NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
                    showToast("Memory warning triggered")
                } label: {
                    Label("Simulate Memory Warning", systemImage: "memorychip")
                }

                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("Reset Debug Unlock", systemImage: "lock.fill")
                }
            } header: {
                Text("Maintenance")
            }

            // MARK: - Export
            Section {
                Button {
                    showingExportAlert = true
                } label: {
                    Label("Export Collection Path", systemImage: "doc.on.doc")
                }
            } header: {
                Text("Export")
            }

            // MARK: - Close
            Section {
                Button("Done") { dismiss() }
            }
        }
        .navigationTitle("Debug Tools")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadAllInfo()
        }
        .alert("Reset Debug Access?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                debugUnlocked = false
                dismiss()
            }
        } message: {
            Text("This will hide the debug menu. You'll need to tap the version 8 times again to re-enable it.")
        }
        .alert("Export Path", isPresented: $showingExportAlert) {
            Button("Copy Collection Path") {
                UIPasteboard.general.string = collectionPath
                showToast("Path copied to clipboard")
            }
            Button("Copy Media Path") {
                UIPasteboard.general.string = mediaPath
                showToast("Path copied to clipboard")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Copy file paths to clipboard for debugging.")
        }
        .overlay {
            if let toast = toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func loadAllInfo() {
        loadPaths()
        loadDatabaseStats()
        loadMediaStats()
        loadSystemInfo()
    }

    private func loadPaths() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let ankiDir = appSupport.appendingPathComponent("AnjiCollection", isDirectory: true)
        collectionPath = ankiDir.appendingPathComponent("collection.anki2").path
        mediaPath = ankiDir.appendingPathComponent("media").path

        // Get DB file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: collectionPath) {
            dbSize = attrs[.size] as? Int64 ?? 0
        }
    }

    private func loadDatabaseStats() {
        // These would need actual implementation via backend
        // For now using placeholder values that update when possible
        totalCards = 0 // Would be fetched from collectionService
        totalNotes = 0
        totalDecks = 0
    }

    private func loadMediaStats() {
        let mediaDir = URL(fileURLWithPath: mediaPath)
        guard FileManager.default.fileExists(atPath: mediaPath) else {
            mediaFileCount = 0
            mediaTotalSize = 0
            return
        }

        if let enumerator = FileManager.default.enumerator(at: mediaDir, includingPropertiesForKeys: [.fileSizeKey]) {
            var count = 0
            var totalSize: Int64 = 0

            for case let fileURL as URL in enumerator {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let size = attrs[.size] as? Int64 {
                    count += 1
                    totalSize += size
                }
            }

            mediaFileCount = count
            mediaTotalSize = totalSize
        }
    }

    private func loadSystemInfo() {
        // Memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        var kerr: kern_return_t

        withUnsafeMutablePointer(to: &info) { infoPtr in
            kerr = infoPtr.withMemoryRebound(to: integer_t.self, capacity: 1) { ptr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), ptr, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            memoryUsage = String(format: "%.1f MB", usedMB)
        } else {
            memoryUsage = "N/A"
        }

        // Disk space
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSize = attrs[.systemFreeSize] as? NSNumber {
                diskFree = formatBytes(freeSize.int64Value)
            }
        } catch {
            diskFree = "N/A"
        }
    }

    private func performDatabaseCheck() {
        do {
            try backend.checkDatabase()
            showToast("Database check completed")
        } catch {
            showToast("Check failed: \(error.localizedDescription)")
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toastMessage = nil
        }
    }
}
