# 🔍 Wortschatz-App (German-Dictionary-App)

Eine moderne, native iOS-App zum Lernen von deutschem Vokabular. Die App nutzt die **Gemini 2.5 Flash API**, um eingegebene Wörter oder ganze Sätze intelligent zu analysieren, Tippfehler oder falsche Groß-/Kleinschreibung zu korrigieren, das Kernwort zu extrahieren und eine prägnante koreanische Übersetzung zu liefern. Alle Daten werden lokal auf dem Gerät gespeichert.

##  Features

*   ** Intelligente Suche:** Eingabe von Wörtern, Phrasen oder Sätzen. Die KI extrahiert das grammatikalisch korrekte deutsche Kernwort.
*   ** Lokales Wörterbuch (Mein Buch):** Speicherung aller gesuchten Wörter mittels **SwiftData**. Unterstützt eine flüssige Benutzeroberfläche durch **Pagination (50 Einträge pro Seite)**.
*   ** Top 50 Trends:** Eine dynamische Liste, die die am häufigsten nachgeschlagenen Wörter basierend auf einem lokalen Suchzähler (`search_count`) anzeigt.
*   ** Wischgeste zum Löschen:** Einträge können ganz einfach über die native iOS-Geste (*Swipe-to-Delete*) als "gelernt" markiert und entfernt werden.
*   ** Datensicherheit:** Der private Gemini API-Key wird strikt vom Quellcode getrennt und zur Laufzeit sicher aus einer Konfigurationsdatei ausgelesen.

##  Architektur & Technologien

Die App ist nach dem modernen **MVVM-Muster (Model-View-ViewModel)** strukturiert und nutzt die neuesten iOS-Frameworks:

*   **SwiftUI:** Für eine deklarative, native und reaktive Benutzeroberfläche.
*   **SwiftData (`@Model`):** Apples moderner Nachfolger von Core Data zur persistenten, lokalen Speicherung in einer SQLite-Datenbank.
*   **Observation Framework (`@Observable`):** Für performante und automatische UI-Updates bei Datenänderungen (ab iOS 17).
*   **URLSession (`async/await`):** Für asynchrone Netzwerkaufrufe im Hintergrund, ohne die UI einzufrieren.
*   **Gemini Structured Outputs:** Erzwingt über ein JSON-Schema (`responseSchema`) eine strikt typisierte, fehlerfreie Antwort der KI.

##  Projektstruktur

```text
german-dictionary-swift/
├── Models/
│   └── VocabularyModel.swift       # Das SwiftData-Schema für ein Wort
├── Services/
│   ├── DatabaseManager.swift       # CRUD-Operationen & Pagination-Logik
│   └── APIService.swift            # Asynchroner Gemini API-Client
├── ViewModels/
│   └── VocabularyViewModel.swift   # Steuert den App-Zustand & Business-Logik
├── Views/
│   └── ContentView.swift           # UI mit TabView (Suchen, Buch, Top 50)
├── Secrets.plist                   # Lokal (API-Key, nicht im Git!)
└── .gitignore                      # Schützt sensible Dateien
