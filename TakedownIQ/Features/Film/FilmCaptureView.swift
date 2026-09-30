import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct FilmCaptureView: View {
    @EnvironmentObject private var filmVM: FilmViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @StateObject private var purchaseManager = PurchaseManager.shared

    @State private var pickedItem: PhotosPickerItem?
    @State private var identity: String = ""
    @State private var showCamera = false
    @State private var cameraError: String?

    let identities = ["Close-up (near camera)", "I'm in red", "I'm in blue", "Solo drill on mirror"]

    init() {
        _filmVM = EnvironmentObject()
        _modelContext = Environment(\.modelContext)
        _dismiss = Environment(\.dismiss)
        _profiles = Query()
        _purchaseManager = StateObject(wrappedValue: PurchaseManager.shared)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                VStack(spacing: 16) {
                    if filmVM.isProcessing {
                        processingCard
                    } else {
                        pickerSection
                        identitySection
                        coachingBanner
                    }
                    if let error = filmVM.errorText {
                        errorCard(error)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Film It")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .photosPicker(isPresented: $showPicker, selection: $pickedItem, matching: .videos)
            .onChange(of: pickedItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let url = try? await newItem.loadTransferable(type: URL.self) {
                        handleVideo(url: url)
                    } else if let data = try? await newItem.loadTransferable(type: Data.self) {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("picked-\(UUID().uuidString).mov")
                        try? data.write(to: url)
                        handleVideo(url: url)
                    }
                }
                pickedItem = nil
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { url in
                    showCamera = false
                    if let url { handleVideo(url: url) }
                }
                .ignoresSafeArea()
            }
        }
    }

    @State private var showPicker = false

    private var pickerSection: some View {
        VStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                Label("FILM A MATCH", systemImage: "camera.fill")
            }
            .buttonStyle(VoltButtonStyle())
            .accessibilityHint("Opens the camera. Phone low, landscape, whole body in frame.")

            PhotosPicker(selection: $pickedItem, matching: .videos) {
                Label("CHOOSE FROM LIBRARY", systemImage: "photo.stack.fill")
                    .font(.system(.headline, weight: .heavy).uppercaseSmallCaps())
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 20))
            }
            .foregroundStyle(Color.volt)
        }
    }

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where are you in the frame? (optional)")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(identities, id: \.self) { option in
                    Button {
                        identity = (identity == option) ? "" : option
                    } label: {
                        Text(option)
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(identity == option ? Color.volt.opacity(0.15) : Color.matSurface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(identity == option ? Color.volt : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var coachingBanner: some View {
        Label("Phone low (hip height) · landscape · whole body in frame", systemImage: "camera.badge.ellipsis")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.matSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    private var processingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.volt)
                .scaleEffect(1.6)
            Text(filmVM.progressStage)
                .font(.headline)
            Text(filmVM.memeLine)
                .font(.subheadline)
                .foregroundStyle(Color.volt)
                .italic()
            Button("Cancel") { filmVM.cancel() }
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .matCard()
    }

    private func errorCard(_ text: String) -> some View {
        VStack(spacing: 8) {
            if text == "quota" {
                Text("That's your free breakdown for today.")
                    .font(.headline)
                Text("Come back tomorrow or go Pro for unlimited film study.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("GO PRO") { dismiss() }
                    .buttonStyle(VoltButtonStyle())
            } else {
                Label(text, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.matChance)
                    .multilineTextAlignment(.leading)
            }
        }
        .matCard()
    }

    private func handleVideo(url: URL) {
        guard let profile = profiles.first else { return }
        filmVM.processVideo(
            url: url,
            identityContext: identity,
            modelContext: modelContext,
            profile: profile,
            isPro: purchaseManager.isPro
        ) { result in
            if let result {
                dismiss()
                filmVM.activeResult = result
            }
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    let onFinish: (URL?) -> Void

    func makeUIViewController(context: Context) -> CameraCaptureViewController {
        let vc = CameraCaptureViewController()
        vc.onFinish = onFinish
        return vc
    }

    func updateUIViewController(_ uiViewController: CameraCaptureViewController, context: Context) {}
}

final class CameraCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var onFinish: (URL?) -> Void
    private let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    init(onFinish: @escaping (URL?) -> Void = { _ in }) {
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.onFinish = { _ in }
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        addUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            onFinish(nil)
            return
        }
        session.addInput(input)
        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }
        guard session.canAddOutput(output) else {
            onFinish(nil)
            return
        }
        session.addOutput(output)
        session.commitConfiguration()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }

    private func addUI() {
        let recordButton = UIButton(type: .system)
        recordButton.setTitle("  REC", for: .normal)
        recordButton.setTitleColor(.red, for: .normal)
        recordButton.titleLabel?.font = .boldSystemFont(ofSize: 22)
        recordButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        recordButton.layer.cornerRadius = 36
        recordButton.accessibilityLabel = "Record match video"
        recordButton.addAction(UIAction { [weak self] _ in self?.toggleRecording(recordButton) }, for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            recordButton.widthAnchor.constraint(equalToConstant: 72),
            recordButton.heightAnchor.constraint(equalToConstant: 72)
        ])

        let banner = UILabel()
        banner.text = "Phone low (hip height) · landscape · whole body in frame"
        banner.textColor = .white
        banner.font = .systemFont(ofSize: 13, weight: .medium)
        banner.textAlignment = .center
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func toggleRecording(_ button: UIButton) {
        if output.isRecording {
            output.stopRecording()
        } else {
            output.maxRecordedDuration = CMTime(seconds: 180, preferredTimescale: 600)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("capture-\(UUID().uuidString).mov")
            output.startRecording(to: url, recordingDelegate: self)
            button.setTitle("  STOP", for: .normal)
            button.setTitleColor(.white, for: .normal)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        onFinish(error == nil ? outputFileURL : nil)
    }
}
