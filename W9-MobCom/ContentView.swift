import SwiftUI

struct MTGCardView: View {
    var card: MTGCard
    var allCards: [MTGCard]

    var body: some View {
        
            VStack {
                ScrollView {
                    // Your existing content here...
                    // Display card image, name, type, oracle text, and legalities
                    AsyncImage(url: URL(string: card.image_uris?.large ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10) // Optional: Add corner radius
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.red)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .padding() // Add padding here
                    
                    // Display card name
                    Text(card.name)
                        .font(.title)
                        .padding()
                    
                    // Display card type, oracle text, and legalities
                    VStack(alignment: .leading) {
                        Text("\(card.type_line)")
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()// Allow vertical wrapping
                        
                        Text("\(card.oracle_text)")
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()// Allow vertical wrapping
                        
                        // Display legalities if available
                        if let legalities = card.legalities {
                            Text("\n Legalities:")
                                .bold()
                                .foregroundStyle(.red)
                                .padding()
                            
                            LazyVGrid(columns: [GridItem(), GridItem()]) {
                                ForEach(Array(Mirror(reflecting: legalities).children), id: \.label) { child in
                                    if let format = child.label, let legality = child.value as? String {
                                        Text("\(legality.capitalized) : \(format.capitalized)")
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                Group {
                                                    if legality.lowercased() == "legal" {
                                                        Color.green
                                                    } else if legality.lowercased() == "not_legal" {
                                                        Color.gray
                                                    } else {
                                                        Color.clear
                                                    }
                                                }
                                                .cornerRadius(10)
                                            )
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                }
            }
            
                }
        }
    


struct ContentView: View {
    @State private var mtgCards: [MTGCard] = []
    @State private var searchText = ""
    @State private var isAscending = true

    let cardMaxWidth: CGFloat = 200 // Set the maximum width for the card

    var filteredCards: [MTGCard] {
        var filtered = mtgCards

        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }

        // Sorting
        filtered.sort { card1, card2 in
            if isAscending {
                return card1.name < card2.name
            } else {
                return card1.name > card2.name
            }
        }

        return filtered
    }

    var body: some View {
        TabView{
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 16) {
                        ForEach(filteredCards) { card in
                            NavigationLink(destination: MTGCardView(card: card, allCards: filteredCards)) {
                                VStack {
                                    // Display card image
                                    AsyncImage(url: URL(string: card.image_uris?.small ?? "")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(5) // Optional: Add corner radius
                                        case .failure:
                                            Image(systemName: "exclamationmark.triangle")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .foregroundColor(.red)
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            ProgressView()
                                        }
                                    }
                                    .frame(maxWidth: cardMaxWidth) // Set the maximum width for the image view
                                    .cornerRadius(5)
                                    .padding() // Add padding here
                                    
                                    // Display card name
                                    VStack {
                                        Text(card.name)
                                            .font(.caption)
                                            .lineLimit(2)
                                            .fixedSize(horizontal: false, vertical: true) // Allow vertical wrapping
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        // Load data from JSON file
                        if let data = loadJSON() {
                            do {
                                let decoder = JSONDecoder()
                                let cards = try decoder.decode(MTGCardList.self, from: data)
                                mtgCards = cards.data
                            } catch {
                                print("Error decoding JSON: \(error)")
                            }
                        }
                    }
                }
                .navigationBarTitle("MTG Cards")
                .navigationBarItems(trailing:
                                        HStack {
                    TextField("Search", text: $searchText)
                        .padding(.horizontal, 8)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        isAscending.toggle()
                    }) {
                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                    }
                })
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }

            // Search Tab
            Text("Search")
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }

            // Collection Tab
            Text("Collection")
                .tabItem {
                    Image(systemName: "folder")
                    Text("Collection")
                }

            // Decks Tab
            Text("Decks")
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Decks")
                }

            // Scan Tab
            Text("Scan")
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }
        }
    }

    // Function to load data from JSON file
    func loadJSON() -> Data? {
        if let path = Bundle.main.path(forResource: "WOT-Scryfall", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                return data
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
