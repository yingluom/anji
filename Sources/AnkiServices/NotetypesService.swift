import AnkiBackend
import AnkiProto
public import AnkiKit
public import Dependencies
import DependenciesMacros

@DependencyClient
public struct NotetypesService: Sendable {
    public var getNotetype: @Sendable (_ id: Int64) throws -> NotetypeInfo
    public var listNotetypes: @Sendable () throws -> [NotetypeInfo]
}

extension NotetypesService: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.ankiBackend) var backend
        return Self(
            getNotetype: { ntid in
                var req = Anki_Notetypes_NotetypeId()
                req.ntid = ntid
                let nt: Anki_Notetypes_Notetype = try backend.invoke(
                    service: AnkiBackend.Service.notetypes,
                    method: AnkiBackend.NotetypesMethod.getNotetype,
                    request: req
                )
                return NotetypeInfo(
                    id: nt.id,
                    name: nt.name,
                    fieldNames: nt.fields.map(\.name)
                )
            },
            listNotetypes: {
                let resp: Anki_Notetypes_NotetypeNames = try backend.invoke(
                    service: AnkiBackend.Service.notetypes,
                    method: AnkiBackend.NotetypesMethod.getNotetypeNames,
                    request: Anki_Generic_Empty()
                )
                return resp.entries.map { NotetypeInfo(id: $0.id, name: $0.name) }
            }
        )
    }()
}

extension NotetypesService: TestDependencyKey {
    public static let testValue = NotetypesService()
}

extension DependencyValues {
    public var notetypesService: NotetypesService {
        get { self[NotetypesService.self] }
        set { self[NotetypesService.self] = newValue }
    }
}
