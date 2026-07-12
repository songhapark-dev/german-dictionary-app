import Foundation
import SwiftData

@MainActor
final class DatabaseManager {
    // Der Container verwaltet den persistenten Speicher auf dem Gerät
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() {
        do {
            // Initialisiert den Speicher für unser VocabularyModel
            self.modelContainer = try ModelContainer(for: VocabularyModel.self)
            self.modelContext = modelContainer.mainContext
        } catch {
            fatalError("Fehler beim Initialisieren von SwiftData: \(error.localizedDescription)")
        }
    }
    
    /// Speichert ein Wort oder erhöht den Suchzähler, falls es schon existiert (UPSERT)
    func saveOrUpdateWord(word: String, meaning: String) {
        let cleanWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prüfen, ob das Wort bereits existiert
        let descriptor = FetchDescriptor<VocabularyModel>(
            predicate: #Predicate { $0.word == cleanWord }
        )
        
        do {
            if let existingModel = try modelContext.fetch(descriptor).first {
                // Wort existiert -> Zähler hochzählen
                existingModel.searchCount += 1
            } else {
                // Neues Wort -> Einfügen
                let newModel = VocabularyModel(word: cleanWord, meaning: meaning)
                modelContext.insert(newModel)
            }
            try modelContext.save()
        } catch {
            print("Datenbankfehler beim Speichern/Updaten: \(error)")
        }
    }
    
    /// Holt Wörter seitenweise ab (Pagination: 50 Einträge pro Seite)
    func fetchWordsPaged(page: Int, limit: Int = 50) -> [VocabularyModel] {
        var descriptor = FetchDescriptor<VocabularyModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        // Berechne das SQL-Offset nativ in Swift
        descriptor.fetchOffset = (page - 1) * limit
        descriptor.fetchLimit = limit
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Datenbankfehler beim Paged-Fetch: \(error)")
            return []
        }
    }
    
    /// Holt die 50 am häufigsten gesuchten Wörter
    func fetchTop50Words() -> [VocabularyModel] {
        var descriptor = FetchDescriptor<VocabularyModel>(
            sortBy: [SortDescriptor(\.searchCount, order: .reverse)]
        )
        descriptor.fetchLimit = 50
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Datenbankfehler beim Top-50-Fetch: \(error)")
            return []
        }
    }
    
    /// Löscht ein Wort aus der Datenbank
    func deleteWord(_ item: VocabularyModel) {
        modelContext.delete(item)
        do {
            try modelContext.save()
        } catch {
            print("Datenbankfehler beim Löschen: \(error)")
        }
    }
}
