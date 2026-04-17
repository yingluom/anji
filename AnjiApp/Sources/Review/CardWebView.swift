import SwiftUI
import WebKit
import AVFoundation

/// Displays rendered card HTML inside a WKWebView with support for local media files and audio autoplay.
struct CardWebView: UIViewRepresentable {
    let html: String
    var autoplayAudio: Bool = true
    @State private var audioPlayer: AVAudioPlayer?
    @State private var pendingAudioFiles: [String] = []

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false

        // Register custom URL scheme handler for media files
        let handler = MediaURLSchemeHandler()
        config.setURLSchemeHandler(handler, forURLScheme: "ankimedia")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Collect audio files before rewriting HTML
        let audioFiles = extractAudioFiles(from: html)
        pendingAudioFiles = audioFiles
        
        // Rewrite media references to use our custom scheme
        let processedHTML = rewriteMediaPaths(html)

        let autoplayScript = autoplayAudio ? """
        <script>
            // Auto-play audio files in sequence
            (function() {
                let audioElements = [];
                let currentIndex = 0;
                
                function playNext() {
                    if (currentIndex < audioElements.length) {
                        const audio = audioElements[currentIndex];
                        audio.volume = 1.0;
                        audio.play().catch(e => console.log('Audio play failed:', e));
                        currentIndex++;
                    }
                }
                
                // Find all audio elements and set up sequential playback
                window.addEventListener('load', function() {
                    audioElements = Array.from(document.querySelectorAll('audio'));
                    audioElements.forEach((audio, index) => {
                        audio.addEventListener('ended', function() {
                            if (index + 1 < audioElements.length) {
                                audioElements[index + 1].play().catch(e => console.log('Next audio play failed:', e));
                            }
                        });
                    });
                    // Start playing first audio
                    if (audioElements.length > 0) {
                        setTimeout(() => {
                            audioElements[0].play().catch(e => console.log('First audio play failed:', e));
                        }, 100);
                    }
                });
            })();
        </script>
        """ : ""
        
        let wrapper = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, system-ui, sans-serif;
                font-size: 18px;
                line-height: 1.6;
                padding: 20px;
                color: #1a1a2e;
                word-wrap: break-word;
            }
            @media (prefers-color-scheme: dark) {
                body { color: #e0e0e0; background: transparent; }
            }
            img { max-width: 100%; height: auto; border-radius: 8px; }
            hr { border: none; border-top: 1px solid rgba(128,128,128,0.3); margin: 16px 0; }
            audio { width: 100%; margin: 8px 0; }
            .cloze { color: #007AFF; font-weight: 500; }
        </style>
        </head>
        <body>\(processedHTML)</body>
        \(autoplayScript)
        </html>
        """
        webView.loadHTMLString(wrapper, baseURL: nil)
        
        // Also play audio files using native AVAudioPlayer as fallback
        if autoplayAudio && !audioFiles.isEmpty {
            playAudioFilesSequentially(audioFiles)
        }
    }
    
    /// Extract audio file names from [sound:...] tags
    private func extractAudioFiles(from html: String) -> [String] {
        let pattern = #"\[sound:([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        return matches.map { match in
            let range = match.range(at: 1)
            return String(html[Range(range, in: html)!])
        }
    }
    
    /// Play audio files sequentially using native player
    private func playAudioFilesSequentially(_ files: [String]) {
        guard !files.isEmpty else { return }
        
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mediaDir = appSupport.appendingPathComponent("AnjiCollection/media", isDirectory: true)
        
        // Filter files that exist locally
        let existingFiles = files.filter { filename in
            let fileURL = mediaDir.appendingPathComponent(filename)
            return FileManager.default.fileExists(atPath: fileURL.path)
        }
        
        guard !existingFiles.isEmpty else { return }
        
        // Play first file
        playAudioFile(at: mediaDir.appendingPathComponent(existingFiles[0]))
    }
    
    private func playAudioFile(at url: URL) {
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    /// Rewrite relative media paths to use ankimedia:// scheme.
    private func rewriteMediaPaths(_ html: String) -> String {
        // Match src="filename.jpg" or [sound:filename.mp3]
        var result = html

        // Rewrite img src references
        result = result.replacingOccurrences(
            of: #"<img\s+[^>]*src\s*=\s*"([^"]+)""#,
            with: "<img src=\"ankimedia://$1\"",
            options: .regularExpression
        )

        // Rewrite [sound:...] to audio elements
        result = result.replacingOccurrences(
            of: #"\[sound:([^\]]+)\]"#,
            with: "<audio controls src=\"ankimedia://$1\"></audio>",
            options: .regularExpression
        )

        return result
    }
}

// MARK: - URL Scheme Handler

/// Handles ankimedia:// URLs to load files from the collection media folder.
class MediaURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let filename = url.host else {
            urlSchemeTask.didFailWithError(NSError(domain: "MediaError", code: 400))
            return
        }

        // Get media folder path (same as in AnjiApp.swift)
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mediaDir = appSupport.appendingPathComponent("AnjiCollection/media", isDirectory: true)
        let fileURL = mediaDir.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(NSError(domain: "MediaError", code: 404))
            return
        }

        // Determine MIME type
        let mimeType: String
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "png": mimeType = "image/png"
        case "gif": mimeType = "image/gif"
        case "svg": mimeType = "image/svg+xml"
        case "mp3": mimeType = "audio/mpeg"
        case "m4a": mimeType = "audio/mp4"
        case "ogg": mimeType = "audio/ogg"
        case "wav": mimeType = "audio/wav"
        default: mimeType = "application/octet-stream"
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: nil
        )

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Cancelled - no cleanup needed for file loading
    }
}

