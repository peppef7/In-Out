import SwiftUI
import SwiftData
import Charts

struct PanoramicaView: View {
    @Query(sort: \Movimento.data, order: .reverse) private var tutti: [Movimento]
    @State private var mese = Date().inizioMese
    @State private var mostraNuovo = false
    @State private var daModificare: Movimento?

    private var delMese: [Movimento] { tutti.delMese(mese) }

    private var speseGiornaliere: [(giorno: Date, totale: Double)] {
        let gruppi = Dictionary(grouping: delMese.filter { $0.tipo == .uscita }) { $0.data.inizioGiorno }
        return gruppi.map { ($0.key, $0.value.reduce(0) { $0 + $1.importo }) }.sorted { $0.giorno < $1.giorno }
    }

    private var mediaGiornaliera: Double {
        let cal = Calendar.current
        let giorniNelMese = cal.range(of: .day, in: .month, for: mese)?.count ?? 30
        let giorni = mese.stessoMese(di: .now) ? cal.component(.day, from: .now) : giorniNelMese
        return delMese.totaleUscite / Double(max(giorni, 1))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SelettoreMese(mese: $mese)

                    // Saldo del mese
                    VStack(spacing: 6) {
                        Text("Saldo del mese").font(.subheadline).foregroundStyle(.secondary)
                        Text(Formato.soldi(delMese.saldo))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(delMese.saldo >= 0 ? .green : .red)
                        Text("Media spesa giornaliera: \(Formato.soldi(mediaGiornaliera))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 12) {
                        CardTotale(titolo: "Entrate", valore: delMese.totaleEntrate, colore: .green, icona: "arrow.down.circle.fill")
                        CardTotale(titolo: "Uscite", valore: delMese.totaleUscite, colore: .red, icona: "arrow.up.circle.fill")
                    }

                    // Grafico spese giornaliere
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spese giorno per giorno").font(.headline)
                        if speseGiornaliere.isEmpty {
                            Text("Nessuna spesa in questo mese").foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            Chart(speseGiornaliere, id: \.giorno) { punto in
                                BarMark(x: .value("Giorno", punto.giorno, unit: .day),
                                        y: .value("Spesa", punto.totale))
                                    .foregroundStyle(.red.gradient)
                                    .cornerRadius(3)
                            }
                            .frame(height: 160)
                        }
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                    // Ultimi movimenti
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ultimi movimenti").font(.headline)
                        if delMese.isEmpty {
                            Text("Tocca + per aggiungere il primo movimento").foregroundStyle(.secondary)
                        }
                        ForEach(delMese.prefix(8)) { m in
                            Button { daModificare = m } label: { RigaMovimento(movimento: m) }
                                .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Panoramica")
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

struct CardTotale: View {
    let titolo: String
    let valore: Double
    let colore: Color
    let icona: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titolo, systemImage: icona).font(.subheadline).foregroundStyle(colore)
            Text(Formato.soldi(valore)).font(.title3.weight(.semibold).monospacedDigit())
                .minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
