import SwiftUI
import SwiftData

@main
struct GestioneSpeseApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: Categoria.self, Movimento.self)
        } catch {
            fatalError("Impossibile creare il database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { DatiIniziali.inserisciCategorieSeVuoto(container.mainContext) }
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            PanoramicaView()
                .tabItem { Label("Panoramica", systemImage: "chart.pie.fill") }
            MovimentiView()
                .tabItem { Label("Movimenti", systemImage: "list.bullet.rectangle") }
            StatisticheView()
                .tabItem { Label("Statistiche", systemImage: "chart.bar.xaxis") }
            BudgetView()
                .tabItem { Label("Budget", systemImage: "target") }
            ImpostazioniView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
    }
}
