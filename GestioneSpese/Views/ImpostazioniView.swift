import SwiftUI
import SwiftData

struct ImpostazioniView: View {
    @AppStorage("valuta") private var valuta = "EUR"
    @Query(sort: \Movimento.data) private var movimenti: [Movimento]

    private var csv: String {
        let formatoData = ISO8601DateFormatter()
        formatoData.formatOptions = [.withFullDate]
        var righe = ["data;tipo;categoria;importo;nota"]
        for m in movimenti {
            let nota = m.nota.replacingOccurrences(of: ";", with: ",")
            let importo = String(format: "%.2f", m.importo).replacingOccurrences(of: ".", with: ",")
            righe.append("\(formatoData.string(from: m.data));\(m.tipo.titolo);\(m.categoria?.nome ?? "");\(importo);\(nota)")
        }
        return righe.joined(separator: "\n")
    }

    private var fileCSV: URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Movimenti.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Categorie") {
                    NavigationLink("Categorie di spesa") { CategorieView(tipo: .uscita) }
                    NavigationLink("Categorie di entrata") { CategorieView(tipo: .entrata) }
                }

                Section("Preferenze") {
                    Picker("Valuta", selection: $valuta) {
                        ForEach(["EUR", "USD", "GBP", "CHF"], id: \.self) { Text($0) }
                    }
                }

                Section {
                    ShareLink(item: fileCSV) {
                        Label("Esporta movimenti (CSV)", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Dati")
                } footer: {
                    Text("\(movimenti.count) movimenti salvati sul dispositivo.")
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

struct CategorieView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Categoria.ordine) private var tutte: [Categoria]
    let tipo: TipoMovimento
    @State private var daModificare: Categoria?
    @State private var mostraNuova = false

    private var categorie: [Categoria] { tutte.filter { $0.tipo == tipo } }

    var body: some View {
        List {
            ForEach(categorie) { c in
                Button { daModificare = c } label: {
                    HStack {
                        IconaCategoria(categoria: c, dimensione: 32)
                        Text(c.nome)
                        Spacer()
                        Text("\(c.movimenti.count)").foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indici in
                for i in indici { context.delete(categorie[i]) }
            }
            .onMove { origine, destinazione in
                var lista = categorie
                lista.move(fromOffsets: origine, toOffset: destinazione)
                for (i, c) in lista.enumerated() { c.ordine = i }
            }
        }
        .navigationTitle(tipo == .uscita ? "Categorie di spesa" : "Categorie di entrata")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { mostraNuova = true } label: { Image(systemName: "plus") }
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(isPresented: $mostraNuova) { EditorCategoriaView(categoria: nil, tipo: tipo) }
        .sheet(item: $daModificare) { c in EditorCategoriaView(categoria: c, tipo: tipo) }
    }
}

struct EditorCategoriaView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let categoria: Categoria?
    let tipo: TipoMovimento

    @State private var nome = ""
    @State private var icona = "cart.fill"
    @State private var coloreHex = "#007AFF"

    private let icone = [
        "cart.fill", "fork.knife", "cup.and.saucer.fill", "car.fill", "fuelpump.fill", "bus.fill",
        "house.fill", "bolt.fill", "drop.fill", "wifi", "phone.fill", "cross.case.fill",
        "pills.fill", "gamecontroller.fill", "film.fill", "music.note", "book.fill", "graduationcap.fill",
        "bag.fill", "tshirt.fill", "gift.fill", "airplane", "pawprint.fill", "figure.run",
        "heart.fill", "creditcard.fill", "banknote.fill", "building.columns.fill", "briefcase.fill",
        "arrow.uturn.backward.circle.fill", "wrench.and.screwdriver.fill", "ellipsis.circle.fill",
    ]
    private let colori = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE", "#30B0C7",
        "#5AC8FA", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#A2845E", "#8E8E93",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Image(systemName: icona).font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Color(hex: coloreHex), in: Circle())
                        Spacer()
                    }
                    TextField("Nome categoria", text: $nome)
                }

                Section("Colore") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(colori, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color.primary, lineWidth: hex == coloreHex ? 3 : 0).padding(-3))
                                .onTapGesture { coloreHex = hex }
                        }
                    }
                }

                Section("Icona") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(icone, id: \.self) { nomeIcona in
                            Image(systemName: nomeIcona).font(.title3)
                                .frame(width: 40, height: 40)
                                .background(nomeIcona == icona ? Color(hex: coloreHex).opacity(0.25) : .clear, in: Circle())
                                .onTapGesture { icona = nomeIcona }
                        }
                    }
                }
            }
            .navigationTitle(categoria == nil ? "Nuova categoria" : "Modifica categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva).disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let c = categoria {
                    nome = c.nome; icona = c.icona; coloreHex = c.coloreHex
                }
            }
        }
    }

    private func salva() {
        let nomePulito = nome.trimmingCharacters(in: .whitespaces)
        if let c = categoria {
            c.nome = nomePulito; c.icona = icona; c.coloreHex = coloreHex
        } else {
            context.insert(Categoria(nome: nomePulito, icona: icona, coloreHex: coloreHex, tipo: tipo, ordine: 999))
        }
        try? context.save()
        dismiss()
    }
}
