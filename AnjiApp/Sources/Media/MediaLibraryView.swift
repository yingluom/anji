import SwiftUI
import AVFoundation

/// Media library view showing all synced media files with details.
struct MediaLibraryView: View {
    @State private var mediaFiles: [MediaFile] = []
    @State private var totalSize: Int64 = 0
    @State private var isLoading = true
    @State private var selectedFile: MediaFile?
    @State private var showPreview = false
    
    struct MediaFile: Identifiable {
        let id = UUID()
        let name: String
        let size: Int64
        let modifiedDate: Date
        let url: URL
        let type: MediaType
        
        enum MediaType {
            case audio, image, video, other
            
            var icon: String {
                switch self {
                case .audio: return "speaker.wave.2.fill"
                case .image: return "photo.fill"
                case .video: return "video.fill"
                case .other: return "doc.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .audio: return .purple
                case .image: return .blue
                case .video: return .red
                case .other: return .gray
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading media...")
            } else if mediaFiles.isEmpty {
                ContentUnavailableView(
                    "No Media Files",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Sync your collection to download media files.")
                )
            } else {
                List {
                    Section {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Files",
                                value: "\(mediaFiles.count)",
                                icon: "folder.fill",
                                color: .blue
                            )
                            StatCard(
                                title: "Size",
                                value: formatBytes(totalSize),
                                icon: "externaldrive.fill",
                                color: .green
                            )
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    
                    Section("Files") {
                        ForEach(mediaFiles) { file in
                            MediaFileRow(file: file)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedFile = file
                                    showPreview = true
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Media Library")
        .task { loadMediaFiles() }
        .refreshable { loadMediaFiles() }
        .sheet(isPresented: $showPreview) {
            if let file = selectedFile {
                MediaPreviewSheet(file: file)
            }
        }
    }
    
    private func loadMediaFiles() {
        let mediaDir = MediaPaths.mediaDirectory
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: mediaDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else {
            mediaFiles = []
            isLoading = false
            return
        }
        
        var files: [MediaFile] = []
        var total: Int64 = 0
        
        for url in contents {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64,
                  let date = attributes[.modificationDate] as? Date else {
                continue
            }
            
            total += size
            
            let ext = url.pathExtension.lowercased()
            let type: MediaFile.MediaType
            switch ext {
            case "mp3", "wav", "m4a", "ogg", "aac", "flac":
                type = .audio
            case "jpg", "jpeg", "png", "gif", "webp", "svg", "bmp":
                type = .image
            case "mp4", "mov", "avi", "mkv", "webm":
                type = .video
            default:
                type = .other
            }
            
            files.append(MediaFile(
                name: url.lastPathComponent,
                size: size,
                modifiedDate: date,
                url: url,
                type: type
            ))
        }
        
        mediaFiles = files.sorted { $0.modifiedDate > $1.modifiedDate }
        totalSize = total
        isLoading = false
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            
            HStack {
                Spacer()
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.anjiPrimary)
            }
            
            HStack {
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.anjiSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.anjiSurface)
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }
}

// MARK: - Media File Row

private struct MediaFileRow: View {
    let file: MediaLibraryView.MediaFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.type.icon)
                .font(.system(size: 24))
                .foregroundStyle(file.type.color)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(file.type.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(Color.anjiPrimary)
                
                HStack(spacing: 8) {
                    Text(formatBytes(file.size))
                        .font(.caption)
                        .foregroundStyle(Color.anjiSecondary)
                    
                    Text("\u{00B7}")
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                    
                    Text(formatDate(file.modifiedDate))
                        .font(.caption)
                        .foregroundStyle(Color.anjiTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.anjiTertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Media Preview Sheet

private struct MediaPreviewSheet: View {
    let file: MediaLibraryView.MediaFile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                switch file.type {
                case .image:
                    AsyncImage(url: file.url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        default:
                            ProgressView()
                        }
                    }
                case .audio:
                    AudioPlayerView(url: file.url)
                default:
                    ContentUnavailableView(
                        "Preview Not Available",
                        systemImage: file.type.icon,
                        description: Text("This file type cannot be previewed.")
                    )
                }
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Audio Player View

private struct AudioPlayerView: View {
    let url: URL
    @State private var isPlaying = false
    @StateObject private var player = AudioPlayer()
    
    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
            
            Text(url.lastPathComponent)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button {
                if isPlaying {
                    player.pause()
                } else {
                    player.play(url: url)
                }
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }
            .foregroundStyle(.purple)
        }
        .padding()
        .onDisappear {
            player.stop()
        }
    }
}

// MARK: - Audio Player

private class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    
    func play(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func stop() {
        player?.stop()
        player = nil
    }
}
