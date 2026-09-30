import AVFoundation
import UIKit

enum VideoError: Error {
    case badAsset, exportFailed, tooShort
}

enum FrameExtractor {
    static func compress(url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoError.badAsset
        }
        let size = try await track.load(.naturalSize)
        let scale = min(1, 720 / max(size.width, size.height))
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tdiq-\(UUID().uuidString).mp4")
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
            throw VideoError.exportFailed
        }
        export.outputURL = outputURL
        export.outputFileType = .mp4
        await export.export()
        guard export.status == .completed else { throw VideoError.exportFailed }
        _ = scale
        return outputURL
    }

    static func extract(url: URL, maxFrames: Int = 36) async throws -> [FrameShot] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else { throw VideoError.badAsset }

        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 640, height: 640)
        gen.requestedTimeToleranceBefore = .zero
        gen.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        let step = max(duration / Double(maxFrames), 0.5)
        var times: [Double] = stride(from: 0.0, to: duration, by: step).map { $0 }
        let sceneChanges = await sceneChangeTimes(asset: asset, duration: duration)
        times.append(contentsOf: sceneChanges)
        var unique = Array(Set(times.map { ($0 * 10).rounded() / 10 })).sorted()
        if unique.count > maxFrames {
            let strideCount = Double(unique.count) / Double(maxFrames)
            unique = (0..<maxFrames).map { unique[min(Int(Double($0) * strideCount), unique.count - 1)] }
        }

        var shots: [FrameShot] = []
        for t in unique {
            if Task.isCancelled { break }
            let cmTime = CMTime(seconds: t, preferredTimescale: 600)
            if let cg = try? await gen.image(at: cmTime).image {
                let ui = UIImage(cgImage: cg)
                if let data = ui.jpegData(compressionQuality: 0.72) {
                    shots.append(FrameShot(id: UUID(), t: t, jpegData: data))
                }
            }
        }
        return shots
    }

    static func probe(url: URL) async throws -> Int {
        let shots = try await extract(url: url, maxFrames: 6)
        return shots.count
    }

    private static func sceneChangeTimes(asset: AVURLAsset, duration: Double) async -> [Double] {
        guard duration <= 300 else { return [] }
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else { return [] }
        let fps = (try? await track.load(.nominalFrameRate)).flatMap { $0 } ?? 30
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            return []
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        reader.add(output)
        reader.startReading()
        let stride = max(Int(fps / 4), 1)
        var hits: [Double] = []
        var previous: [UInt8]?
        var index = 0
        while let buffer = output.copyNextSampleBuffer(), hits.count < 12 {
            index += 1
            guard index % stride == 0, let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { continue }
            let luma = lumaGrid(pixelBuffer)
            if let prev = previous {
                let diff = zip(luma, prev).reduce(0.0) { $0 + abs(Double($1.0) - Double($1.1)) } / Double(luma.count)
                if diff > 0.16 {
                    hits.append(CMSampleBufferGetPresentationTimeStamp(buffer).seconds)
                }
            }
            previous = luma
        }
        return hits.filter { $0.isFinite && $0 >= 0 && $0 < duration }
    }

    private static func lumaGrid(_ pixelBuffer: CVPixelBuffer) -> [UInt8] {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return [] }
        let grid = 16
        var result = [UInt8](repeating: 0, count: grid * grid)
        for gy in 0..<grid {
            for gx in 0..<grid {
                let x = min(gx * width / grid, width - 1)
                let y = min(gy * height / grid, height - 1)
                let offset = y * bytesPerRow + x * 4
                let bytes = base.assumingMemoryBound(to: UInt8.self)
                let b = Int(bytes[offset])
                let g = Int(bytes[offset + 1])
                let r = Int(bytes[offset + 2])
                result[gy * grid + gx] = UInt8(min((r * 299 + g * 587 + b * 114) / 1000, 255))
            }
        }
        return result
    }
}

enum FrameStore {
    static func save(frame: FrameShot) -> String? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thumbs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let name = frame.id.uuidString + ".jpg"
        let url = dir.appendingPathComponent(name)
        guard (try? frame.jpegData.write(to: url)) != nil else { return nil }
        return "thumbs/" + name
    }

    static func url(for path: String) -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func remove(path: String) {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(path))
    }
}
