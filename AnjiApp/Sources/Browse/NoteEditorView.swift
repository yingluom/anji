import SwiftUI
import AnkiKit
import AnkiClients
import AnkiServices
import Dependencies

/// Field category for grouping in editor
enum FieldCategory: String, CaseIterable {
    case basic = "basic"
    case vocab = "vocab"
    case sentence = "sentence"
    case audio = "audio"
    case media = "media"
    case meta = "meta"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .basic: return String(localized: "editor.category.basic")
        case .vocab: return String(localized: "editor.category.vocab")
        case .sentence: return String(localized: "editor.category.sentence")
        case .audio: return String(localized: "editor.category.audio")
        case .media: return String(localized: "editor.category.media")
        case .meta: return String(localized: "editor.category.meta")
        case .other: return String(localized: "editor.category.other")
        }
    }
    
    var icon: String {
        switch self {
        case .basic: return "doc.text"
        case .vocab: return "character.book.closed"
        case .sentence: return "text.quote"
        case .audio: return "waveform"
        case .media: return "photo"
        case .meta: return "tag"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .basic: return .blue
        case .vocab: return .purple
        case .sentence: return .green
        case .audio: return .orange
        case .media: return .pink
        case .meta: return .gray
        case .other: return .secondary
        }
    }
}

struct NoteEditorView: View {
    let noteId: Int64

    @Dependency(\.noteClient) var noteClient
    @Dependency(\.notetypesService) var notetypes
    @State private var note: NoteRecord?
    @State private var fieldNames: [String] = []
    @State private var fieldValues: [String] = []
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var isSaving = false
    @State private var selectedFieldIndex: Int?
    @State private var showTagPicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let note {
                editorContent
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "editor.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "common.cancel")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "common.save")) { Task { await save() } }
                    .disabled(note == nil || isSaving)
            }
        }
        .task { await loadNote() }
    }
    
    private var editorContent: some View {
        Form {
            // Toolbar Section
            toolbarSection
            
            // Tags Section
            tagsSection
            
            // Grouped Fields
            ForEach(groupedFields, id: \.key) { category, fields in
                Section {
                    ForEach(fields, id: \.index) { field in
                        fieldEditor(field: field)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                        Text(category.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(category.color)
                    }
                }
            }
        }
    }
    
    private var toolbarSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ToolbarButton(icon: "bold", action: { insertFormatting("<b>", "</b>") })
                    ToolbarButton(icon: "italic", action: { insertFormatting("<i>", "</i>") })
                    ToolbarButton(icon: "underline", action: { insertFormatting("<u>", "</u>") })
                    ToolbarButton(icon: "strikethrough", action: { insertFormatting("<del>", "</del>") })
                    Divider().frame(height: 24)
                    ToolbarButton(icon: "eye", action: { insertFormatting("{{c1::", "}}") })
                    ToolbarButton(icon: "speaker.wave.2", action: { insertFormatting("[sound:", "]") })
                    ToolbarButton(icon: "photo", action: { insertFormatting("<img src=\"", "\">") })
                    Divider().frame(height: 24)
                    ToolbarButton(icon: "link", action: { insertFormatting("<a href=\"\">", "</a>") })
                    ToolbarButton(icon: "textformat.superscript", action: { insertFormatting("<sup>", "</sup>") })
                    ToolbarButton(icon: "textformat.subscript", action: { insertFormatting("<sub>", "</sub>") })
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text(String(localized: "editor.toolbar"))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private var tagsSection: some View {
        Section {
            // Current tags display
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(tag: tag) {
                        removeTag(tag)
                    }
                }
            }
            
            // Add new tag
            HStack {
                TextField(String(localized: "editor.tag.placeholder"), text: $newTag)
                    .textFieldStyle(.roundedBorder)
                Button {
                    addTag()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.anjiAccent)
                }
                .disabled(newTag.isEmpty)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .foregroundStyle(.orange)
                Text(String(localized: "editor.tags"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    private func fieldEditor(field: FieldInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field name with localized display
            Text(localizedFieldName(field.name))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.anjiSecondary)
            
            // Text editor with auto-expanding height
            AutoExpandingTextEditor(
                text: $fieldValues[field.index],
                placeholder: String(localized: "editor.field.placeholder")
            )
            .frame(minHeight: 40)
            
            // Field type indicator
            HStack {
                Spacer()
                Text(fieldTypeIndicator(field.name))
                    .font(.caption2)
                    .foregroundStyle(Color.anjiTertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.anjiSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.anjiTertiary.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .foregroundStyle(Color.anjiPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Types
    
    struct FieldInfo: Identifiable {
        let id = UUID()
        let index: Int
        let name: String
        let category: FieldCategory
    }
    
    // MARK: - Computed Properties
    
    private var groupedFields: [(key: FieldCategory, value: [FieldInfo])] {
        let fields = fieldNames.enumerated().map { index, name in
            FieldInfo(index: index, name: name, category: categorizeField(name))
        }
        
        let grouped = Dictionary(grouping: fields) { $0.category }
        let sorted = grouped.sorted { cat1, cat2 in
            let order: [FieldCategory] = [.basic, .vocab, .sentence, .audio, .media, .meta, .other]
            guard let i1 = order.firstIndex(of: cat1.key),
                  let i2 = order.firstIndex(of: cat2.key) else { return false }
            return i1 < i2
        }
        return sorted
    }
    
    // MARK: - Methods
    
    private func categorizeField(_ name: String) -> FieldCategory {
        let lower = name.lowercased()
        
        // Vocabulary related
        if lower.contains("vocab") || lower.contains("word") || lower.contains("kanji") || 
           lower.contains("furigana") || lower.contains("pitch") || lower.contains("def") {
            return .vocab
        }
        
        // Sentence related
        if lower.contains("sent") || lower.contains("example") || lower.contains("context") {
            return .sentence
        }
        
        // Audio related
        if lower.contains("audio") || lower.contains("sound") || lower.contains("tts") {
            return .audio
        }
        
        // Media related
        if lower.contains("img") || lower.contains("pic") || lower.contains("image") || 
           lower.contains("media") || lower.contains("video") {
            return .media
        }
        
        // Meta/ID related
        if lower.contains("id") || lower.contains("note") || lower.contains("ord") || 
           lower.contains("order") || lower.contains("alt") || lower.contains("tag") {
            return .meta
        }
        
        // Basic fields
        if lower.contains("front") || lower.contains("back") || lower.contains("question") || 
           lower.contains("answer") || lower.contains("text") || lower.contains("content") {
            return .basic
        }
        
        return .other
    }
    
    private func localizedFieldName(_ name: String) -> String {
        // Try to find localization key for common field names
        let key = "editor.field.\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let localized = String(localized: LocalizedStringKey(key))
        
        // If not found (returns the key itself), use original name
        if localized == key {
            return name
        }
        return localized
    }
    
    private func fieldTypeIndicator(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("audio") || lower.contains("sound") {
            return String(localized: "editor.type.audio")
        } else if lower.contains("img") || lower.contains("image") {
            return String(localized: "editor.type.image")
        } else if lower.contains("kanji") || lower.contains("furigana") {
            return String(localized: "editor.type.japanese")
        }
        return String(localized: "editor.type.text")
    }
    
    private func insertFormatting(_ prefix: String, _ suffix: String) {
        guard let selected = selectedFieldIndex else { return }
        // This would need actual text selection handling
        // For now, append at end
        fieldValues[selected] += prefix + suffix
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func loadNote() async {
        guard let loaded = try? noteClient.fetch(noteId) else { return }
        note = loaded
        fieldValues = loaded.fieldList
        tags = loaded.tags
        
        if let nt = try? notetypes.getNotetype(loaded.notetypeId) {
            fieldNames = nt.fieldNames
        }
    }
    
    private func save() async {
        guard var n = note else { return }
        isSaving = true
        n.fields = fieldValues.joined(separator: "\u{1f}")
        n.tags = tags
        try? noteClient.save(n)
        isSaving = false
        dismiss()
    }
}

// MARK: - Supporting Views

struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.anjiSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.anjiTertiary.opacity(0.3), lineWidth: 0.5)
                        )
                )
                .foregroundStyle(Color.anjiPrimary)
        }
        .buttonStyle(.plain)
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 12, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.anjiAccent.opacity(0.15))
        )
        .foregroundStyle(Color.anjiAccent)
    }
}

struct AutoExpandingTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(Color.anjiTertiary)
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }
            
            TextEditor(text: $text)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
