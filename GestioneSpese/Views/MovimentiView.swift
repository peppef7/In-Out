import SwiftUI
import SwiftData

struct MovimentiView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Movimento.data, order: .reverse) private var tutti: [Movimento]
    @State private var mese = Date().inizioMese
    @State private var ricerca = ""
    @State private var filtroTipo: TipoMovimento?
    @State private var mostraNuovo = false
    @State private var daModificare: Movimento?

    private var filtrati: [Movimento] {
        tutti.delMese(mese).filter { m in
            (filtroTipo == nil || m.tipo == filtroTipo) &&
            (ricerca.isEmpty
             || m.nota.localizedCaseInsensitiveContains(ricerca)
             || (m.categoria?.nome.localizedCaseInsensitiveContains(ricerca) ?? false))
        }
    }

    private var perGiorno: [(giorno: Date, movimenti: [Movimento])] {
        Dictionary(grouping: filtrati) { $0.data.inizioGiorno }
            .map { ($0.key, $0.value) }
            .sorted { $0.giorno > $1.giorno }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SelettoreMese(mese: $mese).listRowBackground(Color.clear)
                    Picker("Tipo", selection: $filtroTipo) {
                        Text("Tutti").tag(TipoMovimento?.none)
                        Text("Uscite").tag(TipoMovimento?.some(.uscita))
                        Text("Entrate").tag(TipoMovimento?.some(.entrata))
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                ForEach(perGiorno, id: \.giorno) { gruppo in
                    Section {
                        ForEach(gruppo.movimenti) { m in
                            Button { daModificare = m } label: { RigaMovimento(movimento: m) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { indici in
                            for i in indici { context.delete(gruppo.movimenti[i]) }
                        }
                    } header: {
                        HStack {
                            Text(Formato.giorno(gruppo.giorno))
                            Spacer()
                            Text(Formato.soldi(gruppo.movimenti.saldo)).monospacedDigit()
                        }
                    }
                }

                if perGiorno.isEmpty {
                    ContentUnavailableView("Nessun movimento", systemImage: "tray",
                                           description: Text("Non ci sono movimenti per questo mese."))
                }
            }
            .searchable(text: $ricerca, prompt: "Cerca per nota o categoria")
            .navigationTitle("Movimenti")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { mostraNuovo = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                }
            }
            .sheet(isPresented: $mostraNuovo) { EditorMovimentoView(movimento: nil) }
            .sheet(item: $daModificare) { m in EditorMovimentoView(movimento: m) }
        }
    }
}
