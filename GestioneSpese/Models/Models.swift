import Foundation
import SwiftData

enum TipoMovimento: String, Codable, CaseIterable, Identifiable {
    case uscita
    case entrata

    var id: String { rawValue }
    var titolo: String { self == .uscita ? "Uscita" : "Entrata" }
}

@Model
final class Categoria {
    var nome: String
    var icona: String          // nome SF Symbol
    var coloreHex: String
    var tipoRaw: String
    var budgetMensile: Double? // solo per le uscite
    var ordine: Int

    @Relationship(deleteRule: .nullify, inverse: \Movimento.categoria)
    var movimenti: [Movimento] = []

    var tipo: TipoMovimento {
        get { TipoMovimento(rawValue: tipoRaw) ?? .uscita }
        set { tipoRaw = newValue.rawValue }
    }

    init(nome: String, icona: String, coloreHex: String, tipo: TipoMovimento, budgetMensile: Double? = nil, ordine: Int = 0) {
        self.nome = nome
        self.icona = icona
        self.coloreHex = coloreHex
        self.tipoRaw = tipo.rawValue
        self.budgetMensile = budgetMensile
        self.ordine = ordine
    }
}

@Model
final class Movimento {
    var importo: Double        // sempre positivo; il segno dipende dal tipo
    var data: Date
    var nota: String
    var tipoRaw: String
    var categoria: Categoria?

    var tipo: TipoMovimento {
        get { TipoMovimento(rawValue: tipoRaw) ?? .uscita }
        set { tipoRaw = newValue.rawValue }
    }

    /// Importo con segno: negativo per le uscite.
    var importoConSegno: Double { tipo == .uscita ? -importo : importo }

    init(importo: Double, data: Date = .now, nota: String = "", tipo: TipoMovimento, categoria: Categoria?) {
        self.importo = importo
        self.data = data
        self.nota = nota
        self.tipoRaw = tipo.rawValue
        self.categoria = categoria
    }
}

enum DatiIniziali {
    static func inserisciCategorieSeVuoto(_ context: ModelContext) {
        let conteggio = (try? context.fetchCount(FetchDescriptor<Categoria>())) ?? 0
        guard conteggio == 0 else { return }

        let uscite: [(String, String, String)] = [
            ("Spesa", "cart.fill", "#34C759"),
            ("Ristoranti", "fork.knife", "#FF9500"),
            ("Trasporti", "car.fill", "#007AFF"),
            ("Casa", "house.fill", "#AF52DE"),
            ("Bollette", "bolt.fill", "#FFCC00"),
            ("Salute", "cross.case.fill", "#FF3B30"),
            ("Svago", "gamecontroller.fill", "#5856D6"),
            ("Shopping", "bag.fill", "#FF2D55"),
            ("Viaggi", "airplane", "#5AC8FA"),
            ("Altro", "ellipsis.circle.fill", "#8E8E93"),
        ]
        let entrate: [(String, String, String)] = [
            ("Stipendio", "banknote.fill", "#30B0C7"),
            ("Extra", "gift.fill", "#A2845E"),
            ("Rimborsi", "arrow.uturn.backward.circle.fill", "#00C7BE"),
        ]
        for (i, c) in uscite.enumerated() {
            context.insert(Categoria(nome: c.0, icona: c.1, coloreHex: c.2, tipo: .uscita, ordine: i))
        }
        for (i, c) in entrate.enumerated() {
            context.insert(Categoria(nome: c.0, icona: c.1, coloreHex: c.2, tipo: .entrata, ordine: i))
        }
        try? context.save()
    }
}
