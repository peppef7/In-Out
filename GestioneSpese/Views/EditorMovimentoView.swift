import SwiftUI
import SwiftData

/// Crea un nuovo movimento (movimento == nil) o modifica uno esistente.
struct EditorMovimentoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Categoria.ordine) private var categorie: [Categoria]

    let movimento: Movimento?

    @State private var tipo: TipoMovimento = .uscita
    @State private var importoTesto = ""
    @State private var categoria: Categoria?
    @State private var data = Date()
    @State private var nota = ""
    @FocusState private var importoAttivo: Bool

    private var categorieDelTipo: [Categoria] { categorie.filter { $0.tipo == tipo } }

    private var importo: Double? {
        Double(importoTesto.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(TipoMovimento.allCases) { Text($0.titolo).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(tipo == .uscita ? "−" : "+").font(.largeTitle.bold())
                            .foregroundStyle(tipo == .uscita ? .red : .green)
                        TextField("0,00", text: $importoTesto)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .focused($importoAttivo)
                        Text(Formato.valuta).foregroundStyle(.secondary)
                    }
                }

                Section("Categoria") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(categorieDelTipo) { c in
                            VStack(spacing: 4) {
                                IconaCategoria(categoria: c, dimensione: 46)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: categoria == c ? 3 : 0).padding(-3))
                                Text(c.nome).font(.caption2).lineLimit(1)
                            }
                            .onTapGesture { categoria = c }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    DatePicker("Data", selection: $data, displayedComponents: [.date, .hourAndMinute])
                    TextField("Nota (facoltativa)", text: $nota)
                }

                if let movimento {
                    Section {
                        Button("Elimina movimento", role: .destructive) {
                            context.delete(movimento)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(movimento == nil ? "Nuovo movimento" : "Modifica")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva).bold().disabled(importo == nil)
                }
            }
            .onAppear(perform: carica)
            .onChange(of: tipo) { _, nuovo in
                if categoria?.tipo != nuovo { categoria = categorieDelTipo.first }
            }
        }
    }

    private func carica() {
        if let m = movimento {
            tipo = m.tipo
            importoTesto = String(format: "%.2f", m.importo).replacingOccurrences(of: ".", with: ",")
            categoria = m.categoria
            data = m.data
            nota = m.nota
        } else {
            categoria = categorieDelTipo.first
            importoAttivo = true
        }
    }

    private func salva() {
        guard let importo else { return }
        if let m = movimento {
            m.importo = importo
            m.tipo = tipo
            m.categoria = categoria
            m.data = data
            m.nota = nota
        } else {
            context.insert(Movimento(importo: importo, data: data, nota: nota, tipo: tipo, categoria: categoria))
        }
        try? context.save()
        dismiss()
    }
}
