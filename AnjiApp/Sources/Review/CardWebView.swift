import SwiftUI
import WebKit
import AVFoundation

/// Media directory used by Anji to cache card media (matches AnjiApp collection location).
enum MediaPaths {
    static var mediaDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("AnjiCollection/media", isDirectory: true)
    }
}

/// Displays rendered card HTML inside a WKWebView with:
/// - Local media resolution via `ankimedia://` scheme
/// - JavaScript-driven sequential audio autoplay
/// - Native AVAudioPlayer fallback (also honors iOS silent switch override)
/// - Support for images, audio, and video referenced by Anki note templates
struct CardWebView: UIViewRepresentable {
    let html: String
    var autoplayAudio: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // JavaScript is required for sequential audio playback and cloze interactions.
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Register custom URL scheme handler for media files.
        config.setURLSchemeHandler(MediaURLSchemeHandler(), forURLScheme: "ankimedia")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator

        // Ensure audio plays even when device is on silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let audioFiles = Self.extractAudioFiles(from: html)
        let processedHTML = Self.rewriteMediaPaths(html)

        // Disable JS autoplay - use native player only to avoid double playback
        let wrapper = Self.buildDocument(bodyHTML: processedHTML, autoplayAudio: false)
        webView.loadHTMLString(wrapper, baseURL: nil)

        // Use native player exclusively for reliable iOS audio playback
        if autoplayAudio {
            context.coordinator.playAudioSequence(audioFiles)
        } else {
            context.coordinator.stopAudio()
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.stopAudio()
    }

    // MARK: - HTML Document

    private static func buildDocument(bodyHTML: String, autoplayAudio: Bool) -> String {
        let autoplayScript = autoplayAudio ? """
        <script>
        (function() {
            function playSequentially(elements, index) {
                if (index >= elements.length) return;
                const el = elements[index];
                el.volume = 1.0;
                const p = el.play();
                if (p && p.catch) p.catch(function(){});
                el.addEventListener('ended', function(){ playSequentially(elements, index + 1); }, { once: true });
            }
            document.addEventListener('DOMContentLoaded', function() {
                const audios = Array.from(document.querySelectorAll('audio'));
                if (audios.length) {
                    setTimeout(function() { playSequentially(audios, 0); }, 150);
                }
            });
        })();
        </script>
        """ : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            /* Base styles */
            * { box-sizing: border-box; }
            html, body { margin: 0; padding: 0; background: transparent; }
            body {
                font-family: -apple-system, system-ui, "Helvetica Neue", "Hiragino Sans", sans-serif;
                font-size: 18px;
                line-height: 1.6;
                padding: 20px;
                color: #1a1a2e;
                word-wrap: break-word;
                -webkit-text-size-adjust: 100%;
            }

            /* Anki card template wrapper */
            .card {
                background: transparent;
                color: inherit;
            }

            /* Light mode colors */
            .cloze { color: #007AFF; font-weight: 600; }
            .cloze-inactive { color: #6c757d; font-weight: 600; }

            /* Type comparison styles */
            .typeGood, .typeGood a { color: #34C759; }
            .typeBad, .typeBad a { color: #FF3B30; }
            .typeMissed, .typeMissed a { color: #FF9500; }

            /* Input field styling for type-in-answer */
            input[type="text"], textarea {
                font-family: inherit;
                font-size: 18px;
                padding: 8px 12px;
                border: 1px solid rgba(128,128,128,0.4);
                border-radius: 8px;
                background: rgba(255,255,255,0.8);
                color: inherit;
                width: 100%;
                max-width: 300px;
            }
            input[type="text"]:focus, textarea:focus {
                outline: none;
                border-color: #007AFF;
            }

            /* Media elements */
            img, video { max-width: 100%; height: auto; border-radius: 8px; display: block; margin: 8px auto; }
            hr { border: none; border-top: 1px solid rgba(0,0,0,0.15); margin: 16px 0; }
            audio { width: 100%; margin: 8px 0; }

            /* Tables */
            table { border-collapse: collapse; margin: 8px 0; width: 100%; }
            td, th { border: 1px solid rgba(128,128,128,0.3); padding: 6px 10px; text-align: left; }

            /* Code blocks */
            code, pre {
                font-family: ui-monospace, "SF Mono", Menlo, "Cascadia Code", monospace;
                background: rgba(128,128,128,0.12);
                padding: 2px 6px;
                border-radius: 4px;
                font-size: 0.9em;
            }
            pre { padding: 12px; overflow-x: auto; white-space: pre-wrap; word-break: break-word; }

            /* Links */
            a { color: #007AFF; text-decoration: none; }
            a:hover { text-decoration: underline; }

            /* Dark mode support */
            @media (prefers-color-scheme: dark) {
                body { color: #e8e8e8; }
                hr { border-top-color: rgba(255,255,255,0.2) !important; }
                .cloze { color: #5AC8FA; }
                .cloze-inactive { color: #8e8e93; }
                input[type="text"], textarea {
                    background: rgba(30,30,30,0.8);
                    border-color: rgba(255,255,255,0.2);
                    color: #e8e8e8;
                }
                input[type="text"]:focus, textarea:focus {
                    border-color: #5AC8FA;
                }
            }

            /* Legacy Anki night mode classes */
            .nightMode, .night_mode {
                color: #e8e8e8 !important;
            }
            .nightMode .cloze, .night_mode .cloze { color: #5AC8FA; }
            .nightMode .cloze-inactive, .night_mode .cloze-inactive { color: #8e8e93; }

            /* Blockquotes */
            blockquote {
                border-left: 4px solid rgba(128,128,128,0.3);
                margin: 8px 0;
                padding-left: 16px;
                color: inherit;
            }

            /* Lists */
            ul, ol { padding-left: 24px; }
            li { margin: 4px 0; }

            /* MathJax/LaTeX rendering */
            .math, .MathJax { font-size: 1em; }

            /* Highlight marker */
            mark { background: rgba(255, 214, 165, 0.5); padding: 1px 4px; border-radius: 3px; }

            /* Additional card template helpers */
            .hidden { display: none !important; }
            .center { text-align: center; }
            .left { text-align: left; }
            .right { text-align: right; }
        </style>
        </head>
        <body><div class="card">\(bodyHTML)</div></body>
        \(autoplayScript)
        </html>
        """
    }

    // MARK: - Media Parsing

    /// Extract audio file names from `[sound:...]` tags.
    static func extractAudioFiles(from html: String) -> [String] {
        let pattern = #"\[sound:([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[range])
        }
    }

    /// Rewrite relative media paths to use `ankimedia://` scheme so WKWebView can load them.
    static func rewriteMediaPaths(_ html: String) -> String {
        var result = html

        // Convert [sound:filename] into an <audio> element with our custom scheme.
        result = result.replacingOccurrences(
            of: #"\[sound:([^\]]+)\]"#,
            with: "<audio preload=\"auto\" src=\"ankimedia://$1\"></audio>",
            options: .regularExpression
        )

        // Rewrite <img src="relative"> (skip absolute/scheme URLs).
        result = result.replacingOccurrences(
            of: #"(<img\b[^>]*\bsrc\s*=\s*")(?!(?:ankimedia|https?|data|file):)([^"]+)(\")"#,
            with: "$1ankimedia://$2$3",
            options: .regularExpression
        )

        // Rewrite <source src="..."> inside <audio>/<video> blocks.
        result = result.replacingOccurrences(
            of: #"(<source\b[^>]*\bsrc\s*=\s*")(?!(?:ankimedia|https?|data|file):)([^"]+)(\")"#,
            with: "$1ankimedia://$2$3",
            options: .regularExpression
        )

        // Rewrite <audio|video src="...">.
        result = result.replacingOccurrences(
            of: #"(<(?:audio|video)\b[^>]*\bsrc\s*=\s*")(?!(?:ankimedia|https?|data|file):)([^"]+)(\")"#,
            with: "$1ankimedia://$2$3",
            options: .regularExpression
        )

        return result
    }

    // MARK: - Coordinator (native audio fallback)

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var player: AVAudioPlayer?
        private var queue: [URL] = []

        override init() {
            super.init()
            // Listen for undo notification to stop audio
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleStopAudio),
                name: .init("AnjiStopAudio"),
                object: nil
            )
        }

        @objc private func handleStopAudio() {
            stopAudio()
        }

        func playAudioSequence(_ filenames: [String]) {
            stopAudio()
            let media = MediaPaths.mediaDirectory
            queue = filenames.compactMap { name in
                let url = media.appendingPathComponent(name)
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
            playNext()
        }

        func stopAudio() {
            player?.stop()
            player = nil
            queue.removeAll()
        }

        fileprivate func playNext() {
            guard !queue.isEmpty else { return }
            let url = queue.removeFirst()
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                p.prepareToPlay()
                p.play()
                player = p
            } catch {
                playNext()
            }
        }
    }
}

extension CardWebView.Coordinator: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNext()
    }
}

// MARK: - URL Scheme Handler

/// Handles `ankimedia://` URLs by loading files from the collection media folder.
final class MediaURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(NSError(domain: "MediaError", code: 400))
            return
        }

        // Filename may appear as host (ankimedia://file.mp3) or path (ankimedia:///file.mp3).
        let filename = (url.host ?? "") + url.path
        let cleanName = filename.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !cleanName.isEmpty,
              let decoded = cleanName.removingPercentEncoding else {
            urlSchemeTask.didFailWithError(NSError(domain: "MediaError", code: 400))
            return
        }

        let fileURL = MediaPaths.mediaDirectory.appendingPathComponent(decoded)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(NSError(domain: "MediaError", code: 404))
            return
        }

        let response = URLResponse(
            url: url,
            mimeType: Self.mimeType(for: fileURL.pathExtension),
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        // Images
        case "jpg", "jpeg": return "image/jpeg"
        case "png":         return "image/png"
        case "gif":         return "image/gif"
        case "webp":        return "image/webp"
        case "svg":         return "image/svg+xml"
        case "bmp":         return "image/bmp"
        // Audio
        case "mp3":         return "audio/mpeg"
        case "m4a", "aac":  return "audio/mp4"
        case "ogg", "oga":  return "audio/ogg"
        case "opus":        return "audio/opus"
        case "wav":         return "audio/wav"
        case "flac":        return "audio/flac"
        // Video
        case "mp4", "m4v":  return "video/mp4"
        case "mov":         return "video/quicktime"
        case "webm":        return "video/webm"
        default:            return "application/octet-stream"
        }
    }
}

