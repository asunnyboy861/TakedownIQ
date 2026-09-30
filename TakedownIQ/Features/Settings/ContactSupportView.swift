import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSending = false
    @State private var success = false
    @State private var errorText: String?

    private let subjects: [(String, String)] = [
        ("General", "bubble.left.fill"),
        ("Feature Suggestion", "lightbulb.fill"),
        ("Bug Report", "ant.fill"),
        ("Usage Question", "questionmark.circle.fill"),
        ("Performance Issue", "gauge.with.dots.needle.67percent"),
        ("UI Improvement", "paintpalette.fill"),
        ("Other", "ellipsis.circle.fill")
    ]

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailValid
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && (subject != "Other" || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        ZStack {
            Color.matBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    subjectGrid
                    if subject == "Other" {
                        TextField("Tell us the topic...", text: $customSubject)
                            .padding(12)
                            .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    TextField("Your name", text: $name)
                        .padding(12)
                        .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 12))
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 12))
                    if !email.isEmpty && !emailValid {
                        Text("Enter a valid email so we can reply.")
                            .font(.caption2)
                            .foregroundStyle(Color.matChance)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                        if message.isEmpty {
                            Text("Tell us what's on your mind...")
                                .foregroundStyle(.secondary)
                                .padding(16)
                        }
                    }
                    .background(Color.matSurface, in: RoundedRectangle(cornerRadius: 12))
                    HStack {
                        Spacer()
                        Text("\(message.count) / 1000")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        submit()
                    } label: {
                        if isSending {
                            ProgressView().tint(.black)
                        } else {
                            Text("SUBMIT")
                        }
                    }
                    .buttonStyle(VoltButtonStyle())
                    .disabled(!canSubmit || isSending)
                    Text("We only use your email to respond to this feedback.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if success {
                        Label("Thank you! Your feedback has been sent.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.matSuccess)
                    }
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.matChance)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's this about?")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(subjects, id: \.0) { option in
                    subjectTile(title: option.0, icon: option.1)
                }
            }
        }
    }

    private func subjectTile(title: String, icon: String) -> some View {
        let isSelected = subject == title
        return Button {
            subject = title
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.black : Color.volt)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.black)
                            .offset(x: 14, y: -8)
                    }
                }
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isSelected ? Color.black : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 74)
            .padding(6)
            .background(isSelected ? Color.volt : Color.matSurface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.volt : Color.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Subject: \(title)\(isSelected ? ", selected" : "")")
    }

    private func submit() {
        isSending = true
        success = false
        errorText = nil
        let finalSubject = subject == "Other" ? customSubject : subject
        let payload: [String: String] = [
            "name": name.trimmingCharacters(in: .whitespaces),
            "email": email.trimmingCharacters(in: .whitespaces),
            "subject": finalSubject,
            "message": message.trimmingCharacters(in: .whitespaces),
            "app_name": "Takedown IQ"
        ]
        var request = URLRequest(url: AppState.feedbackBackendURL.appending(path: "api/feedback"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    isSending = false
                    if statusCode == 200 {
                        success = true
                        message = ""
                        customSubject = ""
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if let serverError = try? JSONDecoder().decode(ServerError.self, from: data) {
                        errorText = serverError.error
                    } else {
                        errorText = "Something went wrong. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorText = "Network issue — check your connection and try again."
                }
            }
        }
    }
}

private struct ServerError: Decodable {
    let error: String
}
