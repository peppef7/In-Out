import SwiftUI
import SwiftData
import Charts

struct StatisticheView: View {
    @Query(sort: \Movimento.data) private var tutti: [Movimento]
    @State private var mese = Date().inizioMese
    @State private var tipo: TipoMovimento = .uscita

    private struct VoceCategoria: Identifiable {
        let id: String
        let nome: String
        let coloreHex: String
        let categoria: Categoria?
        let totale: Double
    }

    private struct VoceMese: Identifiable {
        let id = UUID()
        let mese: Date
        let tipo: String
        let totale: Double
    }

    private var perCategoria: [VoceCategoria] {
        let movimenti = tutti.delMese(mese).filter { $0.tipo == tipo }
        let gruppi = Dictionary(grouping: movimenti) { $0.categoria?.nome ?? "Senza categoria" }
        return gruppi.map { nome, lista in
            let c = lista.first?.categoria
            return VoceCategoria(id: nome, nome: nome, coloreHex: c?.coloreHex ?? "#8E8E93",
                                 categoria: c, totale: lista.reduce(0) { $0 + $1.importo })
        }
        .sorted { $0.totale > $1.totale }
    }

    private var ultimiSeiMesi: [VoceMese] {
        (0..<6).reversed().flatMap { offset -> [VoceMese] in
            let m = mese.aggiungiMesi(-offset)
            let lista = tutti.delMese(m)
            return [VoceMese(mese: m, tipo: "Entrate", totale: lista.totaleEntrate),
                    VoceMese(mese: m, tipo: "Uscite", totale: lista.totaleUscite)]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SelettoreMese(mese: $mese)

                    Picker("Tipo", selection: $tipo) {
                        Text("Uscite").tag(TipoMovimento.uscita)
                        Text("Entrate").tag(TipoMovimento.entrata)
                    }
                    .pickerStyle(.segmented)

                    // Torta per categoria
                    VStack(alignment: .leading) {
                        Text("Per categoria").font(.headline)
                        if perCategoria.isEmpty {
                            Text("Nessun dato per questo mese").foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 150)
                        } else {
                            let totale = perCategoria.reduce(0) { $0 + $1.totale }
                            Chart(perCategoria) { voce in
                                SectorMark(angle: .value("Totale", voce.totale),
                                           innerRadius: .ratio(0.62), angularInset: 1.5)
                                    .foregroundStyle(Color(hex: voce.coloreHex))
                                    .cornerRadius(4)
                            }
                            .frame(height: 220)
                            .chartBackground { _ in
                                VStack {
                                    Text("Totale").font(.caption).foregroundStyle(.secondary)
                                    Text(Formato.soldi(totale)).font(.headline)
                                }
                            }

                            ForEach(perCategoria) { voce in
                                HStack {
                                    IconaCategoria(categoria: voce.categoria, dimensione: 30)
                                    Text(voce.nome)
                                    Spacer()
                                    Text("\(Int((voce.totale / totale * 100).rounded()))%")
                                        .foregroundStyle(.secondary)
                                    Text(Formato.soldi(voce.totale)).monospacedDigit()
                                        .frame(minWidth: 90, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                    // Andamento ultimi 6 mesi
                    VStack(alignment: .leading) {
                        Text("Ultimi 6 mesi").font(.headline)
                        Chart(ultimiSeiMesi) { voce in
                            BarMark(x: .value("Mese", voce.mese, unit: .month),
                                    y: .value("Totale", voce.totale))
                                .foregroundStyle(by: .value("Tipo", voce.tipo))
                                .position(by: .value("Tipo", voce.tipo))
                        }
                        .chartForegroundStyleScale(["Entrate": Color.green, "Uscite": Color.red])
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Statistiche")
        }
    }
}
