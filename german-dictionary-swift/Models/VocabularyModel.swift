import Foundation
import SwiftData

@Model
final class VocabularyModel {
    @Attribute(.unique) var word: String
    var meaning: String
    var searchCount: Int
    var createdAt: Date
    
    init(word: String, meaning: String, searchCount: Int = 1) {
        self.word = word
        self.meaning = meaning
        self.searchCount = searchCount
        self.createdAt = Date()
    }
}
