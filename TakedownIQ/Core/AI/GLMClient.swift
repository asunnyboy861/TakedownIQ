import Foundation

struct FrameShot: Identifiable, Sendable {
    let id: UUID
    let t: Double
    let jpegData: Data
}

struct EventObservationDraft: Sendable {
    var t: Double
    var kind: EventKind
    var title: String
    var whereText: String
    var whyText: String
    var drillID: String
    var confidence: Double
    var unclear: Bool
}

struct BreakdownAggregate: Sendable {
    var observations: [EventObservationDraft]
    var summary: String
    var topDrills: [String]
}

enum AIError: Error {
    case upstream, empty, invalidResponse
}

enum GLMConfig {
    static let primaryURL = URL(string: "https://cramjam-api.calcs.top")!
    static let fallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    static let model = "glm-5.3-flash"
    static let appId = "takedown-iq"
    // 测试期 devKey；生产上架前改为传 appTransaction（StoreKit 2 JWS）
    static let devKey = "cramjam-dev-2026"
}

actor GLMClient {
    static let shared = GLMClient()
    private var activeURL: URL = GLMConfig.primaryURL

    func runBreakdown(frames: [FrameShot], profile: UserProfile, identityContext: String) async throws -> BreakdownAggregate {
        var all: [EventObservationDraft] = []
        let batches = stride(from: 0, to: frames.count, by: 6).map { Array(frames[$0..<min($0 + 6, frames.count)]) }
        for batch in batches {
            let observations = try await analyze(batch: batch, profile: profile, identityContext: identityContext)
            all.append(contentsOf: observations)
        }
        let summary = try await aggregate(observations: all, frames: frames, profile: profile)
        let topDrills = Dictionary(grouping: all, by: { $0.drillID })
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map(\.key)
        return BreakdownAggregate(observations: all, summary: summary, topDrills: topDrills)
    }

    private func send(payload: [String: Any]) async throws -> Data {
        let body: [String: Any] = [
            "appId": GLMConfig.appId,
            "userId": AppState.deviceID,
            "devKey": GLMConfig.devKey,
            "payload": payload
        ]
        var request = URLRequest(url: activeURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AIError.upstream
        }
        return data
    }

    private func complete(messages: [[String: Any]], maxTokens: Int) async throws -> String {
        let payload: [String: Any] = [
            "model": GLMConfig.model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": maxTokens,
            "response_format": ["type": "json_object"]
        ]
        do {
            return try await extractContent(from: try await send(payload: payload))
        } catch {
            activeURL = (activeURL == GLMConfig.primaryURL) ? GLMConfig.fallbackURL : GLMConfig.primaryURL
            return try await extractContent(from: try await send(payload: payload))
        }
    }

    private func extractContent(from data: Data) throws -> String {
        struct Wrap: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable { let content: String? }
                let message: Msg
            }
            let choices: [Choice]
        }
        let wrap = try JSONDecoder().decode(Wrap.self, from: data)
        guard let content = wrap.choices.first?.message.content, !content.isEmpty else {
            throw AIError.empty
        }
        return content
    }

    private func analyze(batch: [FrameShot], profile: UserProfile, identityContext: String) async throws -> [EventObservationDraft] {
        let frameTimes = batch.enumerated()
            .map { "frame#\($0.offset) t=\(String(format: "%.1f", $0.element.t))s" }
            .joined(separator: ", ")
        let system = Self.analysisPrompt(profile: profile, frameTimes: frameTimes, identityContext: identityContext)
        var content: [[String: Any]] = [["type": "text", "text": "Analyze these wrestling frames in order and output the strict JSON."]]
        for frame in batch {
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(frame.jpegData.base64EncodedString())"]
            ])
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": content]
        ]
        let raw = try await complete(messages: messages, maxTokens: 8192)
        return ResponseValidator.validate(raw: raw, frames: batch)
    }

    private func aggregate(observations: [EventObservationDraft], frames: [FrameShot], profile: UserProfile) async throws -> String {
        let listing = observations.map { obs in
            "t=\(String(format: "%.1f", obs.t)) [\(obs.kind.rawValue)] \(obs.title): where \(obs.whereText); why \(obs.whyText)"
        }.joined(separator: "\n")
        let system = """
        You are Coach TD, an elite American wrestling coach. You are given timestamped observations from one wrestler's match film. Write the match summary: 2 sentences max (<=30 words each), direct and specific, folkstyle terms only. Then name the single biggest fix. Never mention weight cutting. Output strict JSON: {"summary":"...","biggest_fix":"..."}
        """
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": "Wrestler: \(profile.levelRaw), focus \(profile.positionRaw).\nObservations:\n\(listing.isEmpty ? "No technique-relevant observations — frames were unclear." : listing)"]
        ]
        let raw = try await complete(messages: messages, maxTokens: 4096)
        struct Agg: Decodable { let summary: String }
        if let data = raw.data(using: .utf8),
           let agg = try? JSONDecoder().decode(Agg.self, from: data) {
            return agg.summary
        }
        return raw
    }

    private static func analysisPrompt(profile: UserProfile, frameTimes: String, identityContext: String) -> String {
        """
        You are Coach TD, an elite American wrestling coach analyzing film for a \(profile.levelRaw) wrestler (focus: \(profile.positionRaw), folkstyle). \(identityContext.isEmpty ? "" : "The wrestler says: \(identityContext).")
        Frames provided IN ORDER: \(frameTimes).
        For EVERY frame decide: is there a technique-relevant observation?
        Output STRICT JSON only, no other text:
        {"observations":[{"frame_index":1,"t":12.4,"kind":"mistake|good|chance","title":"<=8 words","where":"<=12 words body part or position","why":"<=20 words cause","drill_id":"one of: stance-motion, penetration-step, level-change, sprawl, front-headlock, stand-up, sit-out, hip-heist, half-defense, tilt, cradle, arm-bar, ankle-hold, escape-roll, re-attack, hand-fighting, pummeling, close-distance, off-balance, snap-down, fake-shot, high-crotch, double-leg, single-leg, fireman, knee-tap, chain-wrestling, mat-return, breakdown, ride-legs, tilt-turn, pin-combo, conditioning, footwork, posture","confidence":0.0,"unclear":false}],"summary":"<=30 words","top_drills":["drill_id","drill_id","drill_id"]}
        Rules: every t must exactly equal one of the given frame times. If a frame is ambiguous (facing away, cut off, motion blur) set unclear=true and confidence<=0.5. Never invent takedowns you cannot see. Wrestling terms only (setups, level change, penetration step, sprawl, stand-up, sit-out, tilt, cradle). Never give weight cutting, dehydration, or sauna advice.
        """
    }
}

enum ResponseValidator {
    static func validate(raw: String, frames: [FrameShot]) -> [EventObservationDraft] {
        struct Obs: Decodable {
            let frame_index: Int?
            let t: Double?
            let kind: String?
            let title: String?
            let where_: String?
            let why: String?
            let drill_id: String?
            let confidence: Double?
            let unclear: Bool?
            enum CodingKeys: String, CodingKey {
                case frame_index, t, kind, title
                case where_ = "where"
                case why, drill_id, confidence, unclear
            }
        }
        struct Root: Decodable { let observations: [Obs]? }
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else { return [] }
        let jsonText = String(raw[start...end])
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONDecoder().decode(Root.self, from: data) else { return [] }
        let validTimes = Set(frames.map { ($0.t * 10).rounded() })
        return (root.observations ?? []).compactMap { o in
            guard let t = o.t, validTimes.contains((t * 10).rounded()) else { return nil }
            guard let kindRaw = o.kind, let kind = EventKind(rawValue: kindRaw) else { return nil }
            let title = o.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return nil }
            return EventObservationDraft(
                t: t,
                kind: kind,
                title: title,
                whereText: o.where_ ?? "",
                whyText: o.why ?? "",
                drillID: o.drill_id ?? "stance-motion",
                confidence: min(max(o.confidence ?? 0, 0), 1),
                unclear: o.unclear ?? false
            )
        }
    }
}
