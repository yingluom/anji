import Foundation
import CryptoKit
import AnkiKit

/// Manages media file synchronization with integrity checking.
public actor MediaSyncManager {
    private let mediaDirectory: URL
    private let fileManager = FileManager.default
    
    public init(mediaDirectory: URL) {
        self.mediaDirectory = mediaDirectory
    }
    
    /// Calculate MD5 hash of a file for integrity verification.
    public func calculateMD5(for fileURL: URL) -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL),
              let data = try? fileHandle.readToEnd() else {
            return nil
        }
        
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Verify file integrity by comparing MD5 hash.
    public func verifyFileIntegrity(filename: String, expectedMD5: String) -> Bool {
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        guard let actualMD5 = calculateMD5(for: fileURL) else {
            return false
        }
        
        return actualMD5.lowercased() == expectedMD5.lowercased()
    }
    
    /// Check if a file needs to be downloaded.
    public func shouldDownloadFile(filename: String, serverSize: Int64, serverMD5: String?) -> Bool {
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        
        // File doesn't exist locally
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return true
        }
        
        // Check file size
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let localSize = attributes[.size] as? Int64 ?? 0
            
            if localSize != serverSize {
                return true
            }
            
            // If MD5 is provided, verify integrity
            if let md5 = serverMD5 {
                return !verifyFileIntegrity(filename: filename, expectedMD5: md5)
            }
            
            return false
        } catch {
            return true
        }
    }
    
    /// Get list of local files that need to be uploaded.
    public func getLocalFilesToUpload() -> [MediaFileInfo] {
        guard let contents = try? fileManager.contentsOfDirectory(at: mediaDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return contents.compactMap { url in
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else {
                return nil
            }
            
            let filename = url.lastPathComponent
            let md5 = calculateMD5(for: url)
            
            return MediaFileInfo(filename: filename, size: size, md5: md5)
        }
    }
    
    /// Save downloaded file with integrity check.
    public func saveDownloadedFile(data: Data, filename: String, expectedMD5: String?) throws {
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        
        // Ensure directory exists
        try fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        
        // Verify integrity if MD5 is provided
        if let md5 = expectedMD5 {
            let actualMD5 = data.map { String(format: "%02hhx", $0) }.joined()
            guard actualMD5.lowercased() == md5.lowercased() else {
                throw MediaSyncError.integrityCheckFailed(filename: filename)
            }
        }
        
        // Write file
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Delete a file from local media directory.
    public func deleteFile(filename: String) throws {
        let fileURL = mediaDirectory.appendingPathComponent(filename)
        try fileManager.removeItem(at: fileURL)
    }
}

public enum MediaSyncError: Error {
    case integrityCheckFailed(filename: String)
    case downloadFailed(filename: String, reason: String)
    case uploadFailed(filename: String, reason: String)
}
