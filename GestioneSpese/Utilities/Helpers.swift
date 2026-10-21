import SwiftUI

extension Color {
    init(hex: String) {
        let pulito = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var valore: UInt64 = 0
        Scanner(string: pulito).scanHexInt64(&valore)
        let r = Double((valore >> 16) & 0xFF) / 255
        let g = Double((valore >> 8) & 0xFF) / 255
        let b = Double(valore & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Formato {
    static var valuta: String {
        UserDefaults.standard.string(forKey: "valuta") ?? "EUR"
    }

    static func soldi(_ valore: Double) -> String {
        valore.formatted(.currency(code: valuta).locale(Locale(identifier: "it_IT")))
    }

    static func mese(_ data: Date) -> String {
        data.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))).capitalized
    }

    static func giorno(_ data: Date) -> String {
        data.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))).capitalized
    }
}

extension Date {
    var inizioMese: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }

    var inizioGiorno: Date { Calendar.current.startOfDay(for: self) }

    func aggiungiMesi(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: n, to: self) ?? self
    }

    func stessoMese(di altra: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: altra, toGranularity: .month)
    }
}

extension Array where Element == Movimento {
    func delMese(_ mese: Date) -> [Movimento] { filter { $0.data.stessoMese(di: mese) } }
    var totaleEntrate: Double { filter { $0.tipo == .entrata }.reduce(0) { $0 + $1.importo } }
    var totaleUscite: Double { filter { $0.tipo == .uscita }.reduce(0) { $0 + $1.importo } }
    var saldo: Double { totaleEntrate - totaleUscite }
}

/// Selettore del mese con frecce, usato in più schermate.
struct SelettoreMese: View {
    @Binding var mese: Date

    var body: some View {
        HStack {
            Button { mese = mese.aggiungiMesi(-1) } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title2)
            }
            Spacer()
            Text(Formato.mese(mese)).font(.headline)
            Spacer()
            Button { mese = mese.aggiungiMesi(1) } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title2)
            }
        }
        .padding(.horizontal)
    }
}

struct IconaCategoria: View {
    let categoria: Categoria?
    var dimensione: CGFloat = 36

    var body: some View {
        let colore = Color(hex: categoria?.coloreHex ?? "#8E8E93")
        Image(systemName: categoria?.icona ?? "questionmark")
            .font(.system(size: dimensione * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: dimensione, height: dimensione)
            .background(colore, in: Circle())
    }
}

struct RigaMovimento: View {
    let movimento: Movimento

    var body: some View {
        HStack(spacing: 12) {
            IconaCategoria(categoria: movimento.categoria)
            VStack(alignment: .leading, spacing: 2) {
                Text(movimento.categoria?.nome ?? "Senza categoria").font(.body)
                if !movimento.nota.isEmpty {
                    Text(movimento.nota).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Text(Formato.soldi(movimento.importoConSegno))
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(movimento.tipo == .entrata ? .green : .primary)
        }
        .padding(.vertical, 2)
    }
}
