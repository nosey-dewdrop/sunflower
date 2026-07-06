import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            // whimsy scatter
            GeometryReader { geo in
                Image("decor_sparkles")
                    .resizable().scaledToFit().frame(width: 56)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.08)
                Image("decor_butterfly_pink")
                    .resizable().scaledToFit().frame(width: 64)
                    .rotationEffect(.degrees(-10))
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.10)
                Image("decor_strawberry")
                    .resizable().scaledToFit().frame(width: 48)
                    .rotationEffect(.degrees(8))
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.90)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Image("flower_purple")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .padding(.top, 40)

                    Text("Sunflower Pro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.darkGreen)

                    Text("see your focus grow")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.brown.opacity(0.8))

                    VStack(alignment: .leading, spacing: 14) {
                        PaywallFeature(text: "block distracting apps while you focus")
                        PaywallFeature(text: "any focus length, 5 to 120 minutes")
                        PaywallFeature(text: "all future pro features, forever")
                    }
                    .padding(.vertical, 8)

                    if store.products.isEmpty {
                        ProgressView()
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.products, id: \.id) { product in
                                PaywallProductButton(product: product) {
                                    Task {
                                        await store.purchase(product)
                                        if store.isPro { dismiss() }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text("restore purchases")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.brown.opacity(0.7))
                    }
                    .padding(.top, 4)

                    Text("subscriptions renew automatically until cancelled in settings")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.brown.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                }
            }

            if store.isLoading {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView()
            }
        }
        .alert("oops", isPresented: Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )) {
            Button("ok", role: .cancel) { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
    }
}

struct PaywallFeature: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image("sprout")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.darkGreen)
        }
    }
}

struct PaywallProductButton: View {
    let product: Product
    let action: () -> Void

    private var isYearly: Bool {
        product.id == StoreManager.yearlyID
    }

    private var periodLabel: String {
        switch product.id {
        case StoreManager.monthlyID: return "per month"
        case StoreManager.yearlyID: return "per year"
        default: return "once, forever"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(periodLabel)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .opacity(0.7)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(isYearly ? .cream : .darkGreen)
            .padding(16)
            .background(isYearly ? Color.darkGreen : Color.darkGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topTrailing) {
                if isYearly {
                    Text("best value")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.darkGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.warmYellow)
                        .clipShape(Capsule())
                        .offset(x: -10, y: -8)
                }
            }
        }
    }
}
