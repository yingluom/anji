import SwiftUI
import AnkiBackend
import Dependencies

/// Storage settings — collection and media usage.
struct StorageSection: View {
    @Dependency(\.ankiBackend) private var backend

    @State private var collectionSize: Int64 = 0
    @State private var mediaSize: Int64 = 0
    @State private var isLoading = true
    @State private var showMediaLibrary = false

    var body: some View {
        Section {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Label("settings.storage.collection", systemImage: "archivebox")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: collectionSize, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                }

                HStack {
                    Label("settings.storage.media", systemImage: "photo.on.rectangle.angled")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: mediaSize, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                }

                Button {
                    showMediaLibrary = true
                } label: {
                    Label("settings.view_media_library", systemImage: "photo.on.rectangle.angled")
                }
                
                Button(role: .destructive) {
                    clearMediaCache()
                } label: {
                    Label("settings.storage.clear_media", systemImage: "trash")
                }
            }
        } header: {
            Text("settings.section.storage")
        } footer: {
            Text("settings.storage.footer")
        }
        .task { await loadSizes() }
        .sheet(isPresented: $showMediaLibrary) {
            NavigationStack {
                MediaLibraryView()
            }
        }
    }

    private func loadSizes() async {
        // Paths mirror AnjiApp.swift initialization
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let ankiDir = appSupport.appendingPathComponent("AnjiCollection", isDirectory: true)

        let collectionPath = ankiDir.appendingPathComponent("collection.anki2").path
        let mediaPath = ankiDir.appendingPathComponent("media").path

        collectionSize = (try? FileManager.default.attributesOfItem(atPath: collectionPath)[.size] as? Int64) ?? 0
        mediaSize = folderSize(at: mediaPath)
        isLoading = false
    }

    private func folderSize(at path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    private func clearMediaCache() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mediaPath = appSupport.appendingPathComponent("AnjiCollection/media").path
        try? FileManager.default.removeItem(atPath: mediaPath)
        try? FileManager.default.createDirectory(atPath: mediaPath, withIntermediateDirectories: true)
        Task { await loadSizes() }
    }
}
