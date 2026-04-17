import AnkiBackend
import AnkiProto
public import Dependencies
import DependenciesMacros
public import Foundation

@DependencyClient
public struct ImportExportService: Sendable {
    public var importPackage: @Sendable (_ path: String) throws -> String
    public var exportCollection: @Sendable (_ outPath: String, _ includeMedia: Bool) throws -> Void
}

extension ImportExportService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            importPackage: { path in
                var req = Anki_ImportExport_ImportAnkiPackageRequest()
                req.packagePath = path
                let response: Anki_ImportExport_ImportResponse = try backend.invoke(
                    service: AnkiBackend.Service.importExport,
                    method: AnkiBackend.ImportExportMethod.importAnkiPackage,
                    request: req
                )
                let log = response.log
                return "Imported: \(log.new.count) new, \(log.updated.count) updated, \(log.duplicate.count) duplicates"
            },
            exportCollection: { outPath, includeMedia in
                var req = Anki_ImportExport_ExportCollectionPackageRequest()
                req.outPath = outPath
                req.includeMedia = includeMedia
                req.legacy = false
                try backend.invokeVoid(
                    service: AnkiBackend.Service.importExport,
                    method: AnkiBackend.ImportExportMethod.exportCollectionPackage,
                    request: req
                )
            }
        )
    }()
}

extension ImportExportService: TestDependencyKey {
    public static let testValue = ImportExportService()
}

extension DependencyValues {
    public var importExportService: ImportExportService {
        get { self[ImportExportService.self] }
        set { self[ImportExportService.self] = newValue }
    }
}
