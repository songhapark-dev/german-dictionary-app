import Foundation
import Observation

@Observable
@MainActor
final class VocabularyViewModel {
    // Services
    private let databaseManager = DatabaseManager()
    private let apiService = APIService()
    
    // UI-Zustände (werden von SwiftUI automatisch beobachtet)
    var userInput: String = ""
    var searchResultText: String = ""
    var isLoading: Bool = false
    
    // Listen für die Tabs
    var pagedWords: [VocabularyModel] = []
    var top50Words: [VocabularyModel] = []
    
    // Pagination (50 Einträge pro Seite, wie gewünscht)
    var currentPage: Int = 1
    let itemsPerPage: Int = 50
    
    init() {
        refreshLists()
    }
    
    /// Führt die KI-Suche asynchron aus und speichert das Ergebnis
    func performSearch() {
        let cleanInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }
        
        searchResultText = "Gemini analysiert das Kernwort..."
        isLoading = true
        
        // Da performSearch synchron aufgerufen wird, starten wir einen asynchronen Task
        Task {
            do {
                // 1. API im Hintergrund abfragen
                let result = try await apiService.searchWordViaAI(userInput: cleanInput)
                
                // 2. In lokaler Datenbank speichern/updaten
                databaseManager.saveOrUpdateWord(word: result.word, meaning: result.meaning)
                
                // 3. UI-Zustand aktualisieren
                searchResultText = "Ergebnis: \(result.word) = \(result.meaning)"
                userInput = "" // Textfeld leeren
                refreshLists()  // Listen aktualisieren
                
            } catch {
                searchResultText = "Suche fehlgeschlagen. Überprüfe die API-Verbindung."
                print("Fehler bei der Suche: \(error)")
            }
            isLoading = false
        }
    }
    
    /// Blättert eine Seite weiter vor
    func nextPage() {
        currentPage += 1
        refreshLists()
    }
    
    /// Blättert eine Seite zurück
    func prevPage() {
        if currentPage > 1 {
            currentPage -= 1
            refreshLists()
        }
    }
    
    /// Löscht ein Wort aus der Datenbank
    func deleteWord(_ item: VocabularyModel) {
        databaseManager.deleteWord(item)
        refreshLists()
    }
    
    /// Synchronisiert die Daten aus der DB mit den Listen im UI
    func refreshLists() {
        // 1. Paginierte Wörter laden
        let fetchedWords = databaseManager.fetchWordsPaged(page: currentPage, limit: itemsPerPage)
        
        // Fallback: Wenn man "Weiter" klickt, aber die nächste Seite komplett leer ist
        if fetchedWords.isEmpty && currentPage > 1 {
            currentPage -= 1
            pagedWords = databaseManager.fetchWordsPaged(page: currentPage, limit: itemsPerPage)
        } else {
            pagedWords = fetchedWords
        }
        
        // 2. Top 50 häufig gesuchte Wörter laden
        top50Words = databaseManager.fetchTop50Words()
    }
    
    // Hilfseigenschaften für die Aktivierung der Pagination-Buttons im UI
    var hasPrevPage: Bool {
        currentPage > 1
    }
    
    var hasNextPage: Bool {
        pagedWords.count == itemsPerPage
    }
}
