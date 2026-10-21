# Gestione Spese – app iPhone

App nativa SwiftUI (iOS 17+) per tracciare entrate e uscite giornaliere e mensili, ispirata a Money Coach. I dati restano sul telefono (SwiftData), niente account né abbonamenti.

## Cosa fa

- **Panoramica**: saldo del mese, totale entrate e uscite, media di spesa giornaliera, grafico delle spese giorno per giorno, ultimi movimenti.
- **Movimenti**: elenco raggruppato per giorno, ricerca per nota o categoria, filtro entrate/uscite, modifica con un tocco, eliminazione con swipe.
- **Inserimento rapido**: importo, categoria a icone, data e nota.
- **Statistiche**: grafico a ciambella per categoria con percentuali, confronto entrate/uscite degli ultimi 6 mesi.
- **Budget**: budget mensile per categoria con barra colorata (verde, arancione all'80%, rosso se sforato) e budget totale.
- **Impostazioni**: categorie personalizzabili (nome, icona, colore, ordine), scelta della valuta, esportazione CSV.

Per partire ci sono già 13 categorie (Spesa, Ristoranti, Trasporti, Casa, Bollette, Stipendio, ecc.).

## Come installarla sul tuo iPhone

Ti servono un **Mac con Xcode 15 o successivo** (gratis dal Mac App Store) e un Apple ID. L'account sviluppatore a pagamento non serve per usarla sul tuo telefono.

### Opzione A – crea il progetto in Xcode (la più semplice)

1. Apri Xcode → **File › New › Project… › iOS › App**.
2. Product Name: `GestioneSpese`, Interface: **SwiftUI**, Storage: **None**, Language: Swift.
3. Nel progetto creato elimina `ContentView.swift` e `GestioneSpeseApp.swift` (Move to Trash).
4. Trascina dentro Xcode le cartelle `Models`, `Views`, `Utilities` e il file `GestioneSpeseApp.swift` da questa cartella, con **Copy items if needed** spuntato.
5. Nel target, scheda **General**, imposta *Minimum Deployments* a iOS 17.0.
6. Prosegui con "Avvio sul telefono" qui sotto.

### Opzione B – con XcodeGen

```bash
brew install xcodegen
cd GestioneSpese      # questa cartella, quella con project.yml
xcodegen
open GestioneSpese.xcodeproj
```

### Avvio sul telefono

1. Collega l'iPhone al Mac con il cavo e sbloccalo.
2. In Xcode, target → **Signing & Capabilities**: spunta *Automatically manage signing* e scegli il tuo Apple ID come *Team* (aggiungilo da Xcode › Settings › Accounts se non c'è). Se il Bundle Identifier è già preso, cambialo, ad esempio `com.tuonome.gestionespese`.
3. Sull'iPhone attiva **Impostazioni › Privacy e sicurezza › Modalità sviluppatore** (iOS 16+) e riavvia.
4. In alto in Xcode seleziona il tuo iPhone e premi ▶︎ (Cmd+R).
5. Al primo avvio, sull'iPhone vai in **Impostazioni › Generali › VPN e gestione dispositivi** e autorizza il tuo profilo sviluppatore.

Nota: con un Apple ID gratuito l'app va reinstallata da Xcode ogni 7 giorni (i dati restano). Con l'Apple Developer Program (99 €/anno) dura un anno e puoi distribuirla con TestFlight.

## Struttura del codice

```
GestioneSpese/
├── GestioneSpeseApp.swift      avvio app, database e barra delle schede
├── Models/Models.swift         Movimento, Categoria, categorie iniziali
├── Utilities/Helpers.swift     formattazione valuta/date, componenti condivisi
└── Views/
    ├── PanoramicaView.swift
    ├── MovimentiView.swift
    ├── EditorMovimentoView.swift
    ├── StatisticheView.swift
    ├── BudgetView.swift
    └── ImpostazioniView.swift  impostazioni, categorie, export CSV
```
