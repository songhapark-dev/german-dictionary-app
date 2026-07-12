import SwiftUI

struct ContentView: View {
    // Wir initialisieren das ViewModel als State, damit es den Lebenszyklus der View überdauert
    @State private var viewModel = VocabularyViewModel()
    
    var body: some View {
        TabView {
            // --- 1. TAB: SUCHEN ---
            searchTab
                .tabItem {
                    Label("Suchen", systemImage: "magnifyingglass")
                }
            
            // --- 2. TAB: MEIN BUCH ---
            myBookTab
                .tabItem {
                    Label("Mein Buch", systemImage: "book")
                }
            
            // --- 3. TAB: TOP 50 ---
            top50Tab
                .tabItem {
                    Label("Top 50", systemImage: "flame.fill")
                }
        }
    }
    
    // MARK: - 1. Suchen View
    private var searchTab: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Deutsches Wort oder Satz eingeben:")
                    .font(.headline)
                    .padding(.top, 40)
                
                // Stilisiertes natives Eingabefeld mit "Enter/Return"-Unterstützung
                TextField("Wort eingeben...", text: $viewModel.userInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .padding(.horizontal, 30)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        viewModel.performSearch()
                    }
                
                Button(action: {
                    viewModel.performSearch()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView() // Animierter nativer Lade-Indikator
                                .tint(.white)
                                .padding(.trailing, 5)
                        }
                        Text("Suchen & Speichern")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .disabled(viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                
                // Ergebnisanzeige
                Text(viewModel.searchResultText)
                    .font(.body)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("🔍 Wortschatz-App")
        }
    }
    
    // MARK: - 2. Mein Buch View (mit Pagination: 50 pro Seite)
    private var myBookTab: some View {
        NavigationStack {
            VStack {
                if viewModel.pagedWords.isEmpty {
                    ContentUnavailableView("Keine Wörter gefunden", systemImage: "book.closed", description: Text("Suche zuerst nach einem Wort, um dein Buch zu füllen."))
                } else {
                    List {
                        ForEach(viewModel.pagedWords) { item in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("🇩🇪 \(item.word)")
                                    .font(.headline)
                                Text(item.meaning)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            // Native iOS Wischgeste zum Löschen (Swipe-to-Delete)
                            if let index = indexSet.first {
                                let itemToDelete = viewModel.pagedWords[index]
                                viewModel.deleteWord(itemToDelete)
                            }
                        }
                    }
                    .listStyle(.plain)
                    
                    // Native Pagination-Steuerung
                    HStack(spacing: 20) {
                        Button(action: { viewModel.prevPage() }) {
                            Label("Zurück", systemImage: "arrow.left")
                        }
                        .disabled(!viewModel.hasPrevPage)
                        
                        Text("Seite \(viewModel.currentPage)")
                            .font(.headline)
                            .frame(minWidth: 80)
                        
                        Button(action: { viewModel.nextPage() }) {
                            Text("Weiter ") + Text(Image(systemName: "arrow.right"))
                        }
                        .disabled(!viewModel.hasNextPage)
                    }
                    .padding(.bottom, 15)
                }
            }
            .navigationTitle("📖 Mein Buch")
            .toolbar {
                EditButton() // Erlaubt auch das Löschen über einen "Bearbeiten"-Button oben rechts
            }
        }
    }
    
    // MARK: - 3. Top 50 View
    private var top50Tab: some View {
        NavigationStack {
            VStack {
                if viewModel.top50Words.isEmpty {
                    ContentUnavailableView("Noch keine Trends", systemImage: "chart.bar", description: Text("Häufig gesuchte Wörter erscheinen hier."))
                } else {
                    List {
                        ForEach(viewModel.top50Words) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.word)
                                        .font(.headline)
                                    Text(item.meaning)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // Kleines Badge für die Anzahl der Suchanfragen
                                Text("\(item.searchCount)-mal")
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                let itemToDelete = viewModel.top50Words[index]
                                viewModel.deleteWord(itemToDelete)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("🔥 Top 50")
        }
    }
}

#Preview {
    ContentView()
}
