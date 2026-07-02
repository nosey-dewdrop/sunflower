import SwiftUI

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @State private var page = 0

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingPage(
                    hero: "flower_yellow",
                    heroSize: 130,
                    decors: [
                        DecorSpot(name: "decor_butterfly_pink", size: 70, x: 0.18, y: 0.16, rotation: -12),
                        DecorSpot(name: "decor_sparkles", size: 60, x: 0.82, y: 0.20, rotation: 0),
                        DecorSpot(name: "decor_strawberry", size: 56, x: 0.14, y: 0.78, rotation: 8)
                    ],
                    title: "focus, and flowers grow",
                    text: "every session plants a flower in your garden. finish focusing and watch it bloom."
                )
                .tag(0)

                OnboardingPage(
                    hero: "sprout",
                    heroSize: 110,
                    decors: [
                        DecorSpot(name: "decor_cloud_1", size: 80, x: 0.20, y: 0.15, rotation: 0),
                        DecorSpot(name: "decor_cloud_2", size: 64, x: 0.80, y: 0.24, rotation: 0)
                    ],
                    title: "stay with your sprout",
                    text: "leave mid focus and your flower starts to wilt. come back in time and it recovers."
                )
                .tag(1)

                OnboardingPage(
                    hero: "decor_star",
                    heroSize: 120,
                    decors: [
                        DecorSpot(name: "decor_sparkles", size: 64, x: 0.16, y: 0.20, rotation: 0),
                        DecorSpot(name: "decor_butterfly_pastel", size: 74, x: 0.83, y: 0.72, rotation: 10)
                    ],
                    title: "come back tomorrow",
                    text: "your garden starts fresh each morning. your streak doesn't have to."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                HStack {
                    Spacer()
                    if page < 2 {
                        Button {
                            hasOnboarded = true
                        } label: {
                            Text("skip")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.brown.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                    }
                }
                Spacer()
                if page == 2 {
                    Button {
                        hasOnboarded = true
                    } label: {
                        Text("start growing")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.cream)
                            .padding(.horizontal, 44)
                            .padding(.vertical, 16)
                            .background(Color.darkGreen)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 70)
                    .transition(.scale(scale: 0.8, anchor: .bottom))
                }
            }
            .animation(.spring(duration: 0.4), value: page)
        }
    }
}

struct DecorSpot {
    let name: String
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
}

struct OnboardingPage: View {
    let hero: String
    let heroSize: CGFloat
    let decors: [DecorSpot]
    let title: String
    let text: String

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(decors, id: \.name) { decor in
                    Image(decor.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: decor.size)
                        .rotationEffect(.degrees(decor.rotation))
                        .position(x: decor.x * geo.size.width, y: decor.y * geo.size.height)
                }

                VStack(spacing: 24) {
                    Image(hero)
                        .resizable()
                        .scaledToFit()
                        .frame(width: heroSize, height: heroSize)

                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.darkGreen)
                        .multilineTextAlignment(.center)

                    Text(text)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.brown.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 44)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.45)
            }
        }
    }
}

#Preview {
    OnboardingView(hasOnboarded: .constant(false))
}
