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
    let templateCSS: String
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

        // Configure audio to use media volume (not ringer) and respect silent switch.
        // Ambient mode allows audio to mix with other apps and uses media volume buttons.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let audioFiles = Self.extractAudioFiles(from: html)
        let processedHTML = Self.rewriteMediaPaths(html)

        // Build document with template CSS injected after base CSS so it can override
        let wrapper = Self.buildDocument(
            bodyHTML: processedHTML,
            templateCSS: templateCSS,
            autoplayAudio: false
        )
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

    private static func buildDocument(bodyHTML: String, templateCSS: String, autoplayAudio: Bool) -> String {
        // Prepare template CSS injection - placed after our base CSS so it takes precedence
        let templateCSSInjection = templateCSS.isEmpty ? "" : "<style>\(templateCSS)</style>"
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
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            /* Base reset */
            html { -webkit-text-size-adjust: 100%; }
            * { box-sizing: border-box; }
            html, body { margin: 0; padding: 0; background: transparent; }

            /*
             * Font stack that allows card template CSS to override.
             * Card templates often use custom fonts via @font-face or system fonts.
             * We provide a comprehensive fallback stack for CJK and other scripts.
             */
            body {
                /* Default iOS system fonts, but card CSS can override via .card class */
                font-family: -apple-system, BlinkMacSystemFont, "SF Pro", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                font-size: 18px;
                line-height: 1.6;
                padding: 16px;
                color: #1a1a2e;
                word-wrap: break-word;
                -webkit-text-size-adjust: 100%;
                /* Allow font smoothing like desktop */
                -webkit-font-smoothing: antialiased;
                -moz-osx-font-smoothing: grayscale;
            }

            /*
             * The .card class is what Anki templates use.
             * We set a more comprehensive font stack here that includes CJK fonts.
             * Card template CSS can still override this.
             */
            .card {
                background: transparent;
                color: inherit;
                /* Comprehensive font stack matching Anki desktop behavior */
                font-family: inherit;
            }

            /* Support for card templates that explicitly set font-family */
            .card[style*="font-family"] {
                /* Keep the inline style font */
            }

            /* CJK Font Support - Common fonts used in Anki templates */
            :lang(zh), :lang(zh-CN), :lang(zh-TW), :lang(zh-HK), .chinese {
                font-family: "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "WenQuanYi Micro Hei", "Noto Sans CJK SC", sans-serif;
            }
            :lang(ja), :lang(jp), .japanese {
                font-family: "Hiragino Sans", "Hiragino Kaku Gothic ProN", "Noto Sans JP", "Yu Gothic", "Meiryo", sans-serif;
            }
            :lang(ko), :lang(kr), .korean {
                font-family: "Apple SD Gothic Neo", "Noto Sans KR", "Malgun Gothic", "Nanum Gothic", sans-serif;
            }

            /* Allow @font-face from card template CSS to work */
            @font-face {
                font-display: swap;
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
            audio {
                width: 100%;
                margin: 12px 0;
                min-height: 44px;
                display: block;
            }
            /* Ensure audio controls are visible */
            audio::-webkit-media-controls {
                display: flex !important;
            }
            audio::-webkit-media-controls-panel {
                background: rgba(128,128,128,0.1);
                border-radius: 8px;
            }

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

            /* Fix for iOS audio player not showing */
            audio:not([src]) { display: none; }
            audio[src=""] { display: none; }

            /* Ensure all content is visible */
            .card * { max-width: 100%; }

            /* Anki's standard template classes */
            #qa { font-size: 1.2em; line-height: 1.6; }
            .qacontainer { width: 100%; }

            /* Common Anki card template layout classes */
            .extra, .info, .tags { margin-top: 12px; padding-top: 12px; border-top: 1px solid rgba(128,128,128,0.2); }
            .card .extra, .card .info { display: block; }
            .deck, .subdeck { font-size: 0.9em; color: rgba(128,128,128,0.7); margin-bottom: 8px; }
            .answer { font-weight: 600; }

            /* Two-column layouts common in card templates */
            .container, .row { display: flex; flex-wrap: wrap; gap: 12px; width: 100%; }
            .col, .col-left, .col-right { flex: 1 1 45%; min-width: 140px; }
            .col-left { text-align: left; }
            .col-right { text-align: right; }

            /* Ensure floated elements don't get clipped */
            .clearfix::after { content: ""; display: table; clear: both; }
            .float-left { float: left; }
            .float-right { float: right; }

            /* Mobile-specific fixes */
            @supports (-webkit-touch-callout: none) {
                /* iOS specific */
                audio { min-height: 44px; }
            }

            /* Prevent horizontal overflow */
            .card { overflow-x: hidden; word-break: break-word; }
        </style>
        \(templateCSSInjection)
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

