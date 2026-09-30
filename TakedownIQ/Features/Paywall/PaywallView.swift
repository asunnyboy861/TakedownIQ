import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var purchasing = false
    @State private var showManage = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.matBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        valueGrid
                        priceTable
                        legalLinks
                        disclosure
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showManage) { manageSheet }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.volt)
            Text("Takedown IQ Pro")
                .font(.largeTitle.weight(.heavy))
            Text("Unlimited film breakdowns. Full Safe Cut engine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var valueGrid: some View {
        VStack(spacing: 12) {
            valueRow(icon: "film.stack.fill", title: "Unlimited Breakdowns", detail: "Every match, every practice — not 1 per day")
            valueRow(icon: "scalemass.fill", title: "Full Safe Cut Engine", detail: "Auto-adjust plans + parent weekly reports")
            valueRow(icon: "bubble.left.and.bubble.right.fill", title: "Unlimited Coach Chat", detail: "Ask Coach TD anything, any time")
        }
    }

    private func valueRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.volt)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .matCard()
    }

    private var priceTable: some View {
        VStack(spacing: 12) {
            if purchaseManager.products.isEmpty {
                ProgressView()
                    .tint(.volt)
                    .frame(maxWidth: .infinity, minHeight: 120)
                Text(purchaseManager.loadError ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                if let yearly = purchaseManager.yearlyProduct {
                    priceCard(product: yearly, badge: "7-DAY FREE TRIAL · MOST WRESTLERS PICK THIS", highlight: true)
                }
                if let monthly = purchaseManager.monthlyProduct {
                    priceCard(product: monthly, badge: "FLEXIBLE", highlight: false)
                }
                if let season = purchaseManager.seasonProduct {
                    priceCard(product: season, badge: "ONE 90-DAY SEASON · NO RENEWAL", highlight: false)
                }
            }
            Button {
                Task {
                    purchasing = true
                    if let target = purchaseManager.yearlyProduct ?? purchaseManager.products.first {
                        _ = await purchaseManager.purchase(target)
                    }
                    purchasing = false
                }
            } label: {
                if purchasing { ProgressView().tint(.black) } else { Text("START FREE TRIAL") }
            }
            .buttonStyle(VoltButtonStyle())
            .disabled(purchasing || purchaseManager.products.isEmpty)

            Button("Restore Purchases") {
                Task { await purchaseManager.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(Color.volt)

            Button("Manage Subscription (2 taps)") { showManage = true }
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func priceCard(product: Product, badge: String, highlight: Bool) -> some View {
        Button {
            Task {
                purchasing = true
                _ = await purchaseManager.purchase(product)
                purchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName).font(.headline)
                    Text(badge).font(.caption2.bold()).foregroundStyle(highlight ? Color.volt : .secondary)
                }
                Spacer()
                Text(product.displayPrice).font(.title3.weight(.heavy))
            }
            .padding(16)
            .background(highlight ? Color.volt.opacity(0.12) : Color.matSurface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(highlight ? Color.volt : Color.white.opacity(0.08), lineWidth: highlight ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: AppState.policyBaseURL.appending(path: "privacy.html"))
            Link("Terms of Use", destination: AppState.policyBaseURL.appending(path: "terms.html"))
            Link("Support", destination: AppState.policyBaseURL.appending(path: "support.html"))
        }
        .font(.caption2)
        .tint(.volt)
    }

    private var disclosure: some View {
        Text("Payment is charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. The 7-day free trial converts to the annual subscription unless canceled. Season Pass is a one-time 90-day purchase that does not renew. Manage or cancel anytime in Settings.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private var manageSheet: some View {
        ManageSubscriptionsSheet()
    }
}

struct ManageSubscriptionsSheet: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        Task { @MainActor in
            guard let scene = vc.view.window?.windowScene ??
                UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else { return }
            try? await AppStore.showManageSubscriptions(in: scene)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
