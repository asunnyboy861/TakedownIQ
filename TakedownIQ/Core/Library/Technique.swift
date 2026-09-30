import Foundation

struct Technique: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let position: String
    let summary: String
    let steps: [String]
    let keyPoints: [String]
    let commonMistakes: [String]
    let tags: [String]
}

enum TechniqueLibrary {
    static let all: [Technique] = {
        guard let url = Bundle.main.url(forResource: "Techniques", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let techniques = try? JSONDecoder().decode([Technique].self, from: data) else {
            return []
        }
        return techniques
    }()

    static func search(_ query: String) -> [Technique] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.title.lowercased().contains(q)
                || $0.position.lowercased().contains(q)
                || $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    static func technique(forID id: String) -> Technique? {
        all.first { $0.id == id }
    }
}
