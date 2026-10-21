import SwiftUI
import SwiftData

struct BudgetView: View {
    @Query(sort: \Categoria.ordine) private var categorie: [Categoria]
    @Query private var tutti: [Movimento]
    @State private var mese = Date().inizioMese
    @State private var daModificare: Categoria?

    private var categorieUscita: [Categoria] { categorie.filter { $0.tipo == .uscita } }

    private func speso(_ c: Categoria) -> Double {
        tutti.delMese(mese).filter { $0.tipo == .uscita && $0.categoria == c }.reduce(0) { $0 + $1.importo }
    }

    private var budgetTotale: Double { categorieUscita.compactMap(\.budgetMensile).reduce(0, +) }
    private var spesoConBudget: Double {
        categorieUscita.filter { $0.budgetMensile != nil }.reduce(0) { $0 + speso($1) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section { SelettoreMese(mese: $mese).listRowBackground(Color.clear) }

                if budgetTotale > 0 {
                    Section("Totale") {
                        BarraBudget(speso: spesoConBudget, budget: budgetTotale)
                    }
                }

                Section {
                    ForEach(categorieUscita) { c in
                        Button { daModificare = c } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    IconaCategoria(categoria: c, dimensione: 30)
                                    Text(c.nome)
                                    Spacer()
                                    if c.budgetMensile == nil {
                                        Text("Imposta budget").font(.caption).foregroundStyle(.tint)
                                    }
                                }
                                if let budget = c.budgetMensile {
                                    BarraBudget(speso: speso(c), budget: budget)
                                } else {
                                    Text("Speso: \(Formato.soldi(speso(c)))").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Per categoria")
                } footer: {
                    Text("Tocca una categoria per impostare o modificare il budget mensile.")
                }
            }
            .navigationTitle("Budget")
            .sheet(item: $daModificare) { c in ImpostaBudgetView(categoria: c) }
        }
    }
}

struct BarraBudget: View {
    let speso: Double
    let budget: Double

    private var rapporto: Double { budget > 0 ? speso / budget : 0 }
    private var colore: Color { rapporto >= 1 ? .red : (rapporto >= 0.8 ? .orange : .green) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(rapporto, 1)).tint(colore)
            HStack {
                Text("\(Formato.soldi(speso)) di \(Formato.soldi(budget))")
                Spacer()
                let residuo = budget - speso
                Text(residuo >= 0 ? "Restano \(Formato.soldi(residuo))" : "Sforato di \(Formato.soldi(-residuo))")
                    .foregroundStyle(residuo >= 0 ? Color.secondary : Color.red)
            }
            .font(.caption.monospacedDigit())
        }
    }
}

struct ImpostaBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var categoria: Categoria
    @State private var testo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        IconaCategoria(categoria: categoria)
                        Text(categoria.nome).font(.headline)
                    }
                    TextField("Budget mensile", text: $testo).keyboardType(.decimalPad)
                } footer: {
                    Text("Lascia vuoto per non avere un budget su questa categoria.")
                }
            }
            .navigationTitle("Budget mensile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let valore = Double(testo.replacingOccurrences(of: ",", with: "."))
                        categoria.budgetMensile = (valore ?? 0) > 0 ? valore : nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let b = categoria.budgetMensile {
                    testo = String(format: "%.2f", b).replacingOccurrences(of: ".", with: ",")
                }
            }
        }
        .presentationDetents([.medium])
    }
}
