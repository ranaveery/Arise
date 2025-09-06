import SwiftUI

struct RankPopupView: View {
    let ranks: [Rank]
    let currentRankId: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                
                Text("All Ranks")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top)
                
                ForEach(ranks) { rank in
                    HStack(spacing: 12) {
                        // Placeholder emblem
                        Image(rank.emblemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .opacity(rank.id == currentRankId ? 1 : 0.6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rank.name.uppercased())
                                .font(.headline)
                                .foregroundColor(rank.id == currentRankId ? .white : .white.opacity(0.8))
                            
                            Text("Requires \(Int(rank.requiredXP)) XP")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        if rank.id == currentRankId {
                            Text("You are here")
                                .font(.caption2.bold())
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 153/255, green: 0/255, blue: 0/255),
                                            Color(red: 255/255, green: 85/255, blue: 0/255)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(rank.id == currentRankId ? 0.15 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Spacer(minLength: 40)
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
