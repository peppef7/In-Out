"use strict";

// ---------- Dati ----------

const CHIAVE = "gestione-spese-v1";

const CATEGORIE_INIZIALI = [
  ["Spesa", "🛒", "#34C759", "uscita"],
  ["Ristoranti", "🍽️", "#FF9500", "uscita"],
  ["Trasporti", "🚗", "#007AFF", "uscita"],
  ["Casa", "🏠", "#AF52DE", "uscita"],
  ["Bollette", "💡", "#FFCC00", "uscita"],
  ["Salute", "💊", "#FF3B30", "uscita"],
  ["Svago", "🎮", "#5856D6", "uscita"],
  ["Shopping", "🛍️", "#FF2D55", "uscita"],
  ["Viaggi", "✈️", "#5AC8FA", "uscita"],
  ["Altro", "📦", "#8E8E93", "uscita"],
  ["Stipendio", "💶", "#30B0C7", "entrata"],
  ["Extra", "🎁", "#A2845E", "entrata"],
  ["Rimborsi", "↩️", "#00C7BE", "entrata"],
];

const ICONE = ["🛒","🍽️","☕","🚗","⛽","🚌","🏠","💡","💧","📶","📱","💊","🏥","🎮","🎬","🎵","📚","🎓",
  "🛍️","👕","🎁","✈️","🐾","🏃","❤️","💳","💶","🏦","💼","↩️","🔧","👶","🍺","💇","🚬","📦"];
const COLORI = ["#FF3B30","#FF9500","#FFCC00","#34C759","#00C7BE","#30B0C7","#5AC8FA","#007AFF",
  "#5856D6","#AF52DE","#FF2D55","#A2845E","#8E8E93"];

function nuovoId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}

function caricaDati() {
  try {
    const grezzo = localStorage.getItem(CHIAVE);
    if (grezzo) return JSON.parse(grezzo);
  } catch (e) { /* dati assenti o illeggibili: si riparte da zero */ }
  return {
    valuta: "EUR",
    movimenti: [],
    categorie: CATEGORIE_INIZIALI.map(([nome, icona, colore, tipo], i) =>
      ({ id: nuovoId() + i, nome, icona, colore, tipo, budget: null, ordine: i })),
  };
}

let dati = caricaDati();

function salvaDati() {
  try {
    localStorage.setItem(CHIAVE, JSON.stringify(dati));
  } catch (e) {
    alert("Impossibile salvare i dati sul dispositivo.");
  }
}

// Chiede a Safari di non cancellare i dati in caso di poco spazio.
if (navigator.storage && navigator.storage.persist) navigator.storage.persist().catch(() => {});

// ---------- Utilità ----------

const $ = (sel) => document.querySelector(sel);

function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function soldi(v) {
  return new Intl.NumberFormat("it-IT", { style: "currency", currency: dati.valuta }).format(v);
}

function nomeMese(d, breve = false) {
  const s = d.toLocaleDateString("it-IT", breve ? { month: "short" } : { month: "long", year: "numeric" });
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function nomeGiorno(chiave) {
  const s = new Date(chiave + "T12:00").toLocaleDateString("it-IT", { weekday: "long", day: "numeric", month: "long" });
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function chiaveGiorno(iso) { return iso.slice(0, 10); }
function chiaveMese(d) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`; }
function oggiISO() {
  const d = new Date();
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 10);
}

function categoria(id) { return dati.categorie.find((c) => c.id === id); }
function categorieDi(tipo) {
  return dati.categorie.filter((c) => c.tipo === tipo).sort((a, b) => a.ordine - b.ordine);
}

function movimentiDelMese(d) {
  const k = chiaveMese(d);
  return dati.movimenti.filter((m) => m.data.startsWith(k));
}

function totali(lista) {
  let entrate = 0, uscite = 0;
  for (const m of lista) m.tipo === "entrata" ? (entrate += m.importo) : (uscite += m.importo);
  return { entrate, uscite, saldo: entrate - uscite };
}

function leggiImporto(testo) {
  let t = String(testo).trim();
  if (t.includes(",")) t = t.replace(/\./g, "").replace(",", ".");
  const v = parseFloat(t);
  return isFinite(v) && v > 0 ? Math.round(v * 100) / 100 : null;
}

function iconaHTML(c, classe = "icona") {
  const colore = c ? c.colore : "#8E8E93";
  return `<span class="${classe}" style="background:${colore}33">${c ? c.icona : "❔"}</span>`;
}

function rigaMovimento(m) {
  const c = categoria(m.categoria);
  const segno = m.tipo === "uscita" ? -m.importo : m.importo;
  return `<button class="riga" data-movimento="${m.id}">
    ${iconaHTML(c)}
    <span class="testi">
      <div class="nome">${esc(c ? c.nome : "Senza categoria")}</div>
      ${m.nota ? `<div class="sotto">${esc(m.nota)}</div>` : ""}
    </span>
    <span class="importo ${m.tipo === "entrata" ? "positivo" : ""}">${soldi(segno)}</span>
  </button>`;
}

// ---------- Stato interfaccia ----------

const stato = {
  tab: "panoramica",
  mese: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
  filtro: "tutti",
  ricerca: "",
  tipoStat: "uscita",
};

const TITOLI = {
  panoramica: "Panoramica", movimenti: "Movimenti", statistiche: "Statistiche",
  budget: "Budget", impostazioni: "Impostazioni",
};

function render() {
  $("#titolo").textContent = TITOLI[stato.tab];
  $("#etichetta-mese").textContent = nomeMese(stato.mese);
  $("#selettore-mese").classList.toggle("nascosto", stato.tab === "impostazioni");
  $("#btn-aggiungi").style.visibility = stato.tab === "impostazioni" ? "hidden" : "visible";
  document.querySelectorAll(".tabbar button").forEach((b) =>
    b.classList.toggle("attiva", b.dataset.tab === stato.tab));
  $("#contenuto").innerHTML = VISTE[stato.tab]();
}

// ---------- Viste ----------

const VISTE = {
  panoramica() {
    const lista = movimentiDelMese(stato.mese);
    const t = totali(lista);
    const giorniNelMese = new Date(stato.mese.getFullYear(), stato.mese.getMonth() + 1, 0).getDate();
    const oggi = new Date();
    const meseCorrente = chiaveMese(oggi) === chiaveMese(stato.mese);
    const giorni = meseCorrente ? oggi.getDate() : giorniNelMese;

    const perGiorno = new Array(giorniNelMese).fill(0);
    for (const m of lista) if (m.tipo === "uscita") perGiorno[parseInt(m.data.slice(8, 10), 10) - 1] += m.importo;
    const max = Math.max(...perGiorno);
    const barre = max > 0
      ? `<div class="barre">${perGiorno.map((v, i) =>
          `<div class="barra" style="height:${(v / max) * 100}%" title="${i + 1}: ${soldi(v)}"></div>`).join("")}</div>
         <div class="assi"><span>1</span><span>${Math.ceil(giorniNelMese / 2)}</span><span>${giorniNelMese}</span></div>`
      : `<div class="vuoto">Nessuna spesa in questo mese</div>`;

    const recenti = [...lista].sort((a, b) => b.data.localeCompare(a.data)).slice(0, 8);

    return `
      ${avvisoInstallazione()}
      <section class="card saldo">
        <div class="etichetta">Saldo del mese</div>
        <div class="valore ${t.saldo >= 0 ? "positivo" : "negativo"}">${soldi(t.saldo)}</div>
        <div class="nota">Media spesa giornaliera: ${soldi(t.uscite / Math.max(giorni, 1))}</div>
      </section>
      <div class="griglia2">
        <section class="card totale"><div class="etichetta positivo">↓ Entrate</div><div class="valore">${soldi(t.entrate)}</div></section>
        <section class="card totale"><div class="etichetta negativo">↑ Uscite</div><div class="valore">${soldi(t.uscite)}</div></section>
      </div>
      <section class="card"><h2>Spese giorno per giorno</h2>${barre}</section>
      <section class="card"><h2>Ultimi movimenti</h2>
        ${recenti.length ? recenti.map(rigaMovimento).join("") : `<div class="vuoto">Tocca + per aggiungere il primo movimento</div>`}
      </section>`;
  },

  movimenti() {
    const q = stato.ricerca.toLowerCase();
    const lista = movimentiDelMese(stato.mese).filter((m) => {
      if (stato.filtro !== "tutti" && m.tipo !== stato.filtro) return false;
      if (!q) return true;
      const c = categoria(m.categoria);
      return (m.nota || "").toLowerCase().includes(q) || (c && c.nome.toLowerCase().includes(q));
    });
    const gruppi = {};
    for (const m of lista) (gruppi[chiaveGiorno(m.data)] ||= []).push(m);
    const giorni = Object.keys(gruppi).sort().reverse();

    return `
      <input class="cerca" id="ricerca" type="search" placeholder="Cerca per nota o categoria" value="${esc(stato.ricerca)}">
      <div class="segmenti" id="filtro">
        ${[["tutti", "Tutti"], ["uscita", "Uscite"], ["entrata", "Entrate"]].map(([k, l]) =>
          `<button data-filtro="${k}" class="${stato.filtro === k ? "attivo" : ""}">${l}</button>`).join("")}
      </div>
      ${giorni.length ? giorni.map((g) => {
        const voci = gruppi[g].sort((a, b) => b.data.localeCompare(a.data));
        return `<div class="intestazione-giorno"><span>${nomeGiorno(g)}</span><span>${soldi(totali(voci).saldo)}</span></div>
                <section class="card gruppo">${voci.map(rigaMovimento).join("")}</section>`;
      }).join("") : `<section class="card"><div class="vuoto">Nessun movimento per questo mese</div></section>`}`;
  },

  statistiche() {
    const lista = movimentiDelMese(stato.mese).filter((m) => m.tipo === stato.tipoStat);
    const perCat = {};
    for (const m of lista) perCat[m.categoria || "-"] = (perCat[m.categoria || "-"] || 0) + m.importo;
    const voci = Object.entries(perCat).map(([id, totale]) => ({ c: categoria(id), totale }))
      .sort((a, b) => b.totale - a.totale);
    const totale = voci.reduce((s, v) => s + v.totale, 0);

    let ciambella = `<div class="vuoto">Nessun dato per questo mese</div>`;
    if (totale > 0) {
      const r = 70, circ = 2 * Math.PI * r;
      let offset = 0;
      const archi = voci.map((v) => {
        const lung = (v.totale / totale) * circ;
        const arco = `<circle r="${r}" cx="90" cy="90" fill="none" stroke="${v.c ? v.c.colore : "#8E8E93"}"
          stroke-width="26" stroke-dasharray="${Math.max(lung - 2, 0.5)} ${circ}" stroke-dashoffset="${-offset}"
          transform="rotate(-90 90 90)"/>`;
        offset += lung;
        return arco;
      }).join("");
      ciambella = `
        <svg class="ciambella" width="180" height="180" viewBox="0 0 180 180">${archi}
          <text x="90" y="84" text-anchor="middle" font-size="12" fill="currentColor" opacity=".6">Totale</text>
          <text x="90" y="104" text-anchor="middle" font-size="16" font-weight="600" fill="currentColor">${soldi(totale)}</text>
        </svg>
        ${voci.map((v) => `<div class="riga">${iconaHTML(v.c)}
          <span class="testi"><div class="nome">${esc(v.c ? v.c.nome : "Senza categoria")}</div>
          <div class="sotto">${Math.round((v.totale / totale) * 100)}%</div></span>
          <span class="importo">${soldi(v.totale)}</span></div>`).join("")}`;
    }

    const mesi = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(stato.mese.getFullYear(), stato.mese.getMonth() - i, 1);
      mesi.push({ d, ...totali(movimentiDelMese(d)) });
    }
    const maxMese = Math.max(1, ...mesi.map((m) => Math.max(m.entrate, m.uscite)));

    return `
      <div class="segmenti" id="tipo-stat">
        <button data-tipo="uscita" class="${stato.tipoStat === "uscita" ? "attivo" : ""}">Uscite</button>
        <button data-tipo="entrata" class="${stato.tipoStat === "entrata" ? "attivo" : ""}">Entrate</button>
      </div>
      <section class="card"><h2>Per categoria</h2>${ciambella}</section>
      <section class="card"><h2>Ultimi 6 mesi</h2>
        <div class="mesi">${mesi.map((m) => `<div class="colonna"><div class="coppia">
          <div class="b" style="height:${(m.entrate / maxMese) * 100}%;background:var(--verde)"></div>
          <div class="b" style="height:${(m.uscite / maxMese) * 100}%;background:var(--rosso)"></div>
          </div><div class="lab">${nomeMese(m.d, true)}</div></div>`).join("")}</div>
        <div class="legenda"><span><i style="background:var(--verde)"></i>Entrate</span><span><i style="background:var(--rosso)"></i>Uscite</span></div>
      </section>`;
  },

  budget() {
    const lista = movimentiDelMese(stato.mese).filter((m) => m.tipo === "uscita");
    const speso = (id) => lista.filter((m) => m.categoria === id).reduce((s, m) => s + m.importo, 0);
    const cats = categorieDi("uscita");
    const conBudget = cats.filter((c) => c.budget);
    const budgetTot = conBudget.reduce((s, c) => s + c.budget, 0);
    const spesoTot = conBudget.reduce((s, c) => s + speso(c.id), 0);

    return `
      ${budgetTot > 0 ? `<section class="card"><h2>Totale</h2>${barraBudget(spesoTot, budgetTot)}</section>` : ""}
      <section class="card"><h2>Per categoria</h2>
        ${cats.map((c) => `<button class="riga" data-budget="${c.id}" style="display:block">
          <div style="display:flex;align-items:center;gap:12px">${iconaHTML(c)}
            <span class="testi nome">${esc(c.nome)}</span>
            ${c.budget ? "" : `<span class="link">Imposta budget</span>`}</div>
          ${c.budget ? barraBudget(speso(c.id), c.budget) : `<div class="dettaglio-budget" style="margin-top:6px"><span>Speso: ${soldi(speso(c.id))}</span></div>`}
        </button>`).join("")}
      </section>
      <p class="piccolo">Tocca una categoria per impostare o modificare il budget mensile.</p>`;
  },

  impostazioni() {
    return `
      <section class="card">
        <h2>Categorie</h2>
        <button class="riga" data-azione="categorie-uscita"><span class="testi nome">Categorie di spesa</span><span class="sotto">›</span></button>
        <button class="riga" data-azione="categorie-entrata"><span class="testi nome">Categorie di entrata</span><span class="sotto">›</span></button>
      </section>
      <section class="card">
        <h2>Preferenze</h2>
        <label class="campo"><span>Valuta</span>
          <select id="valuta">${["EUR", "USD", "GBP", "CHF"].map((v) =>
            `<option ${v === dati.valuta ? "selected" : ""}>${v}</option>`).join("")}</select>
        </label>
      </section>
      <section class="card">
        <h2>Dati</h2>
        <button class="riga" data-azione="esporta-csv"><span class="testi nome">Esporta movimenti (CSV)</span></button>
        <button class="riga" data-azione="backup"><span class="testi nome">Salva backup</span></button>
        <button class="riga" data-azione="ripristina"><span class="testi nome">Ripristina da backup</span></button>
        <input type="file" id="file-backup" accept="application/json,.json" hidden>
      </section>
      <p class="piccolo">${dati.movimenti.length} movimenti salvati solo su questo dispositivo. Fai un backup ogni tanto: se cancelli i dati di Safari o rimuovi l'app dalla Home, i movimenti vanno persi.</p>`;
  },
};

function barraBudget(speso, budget) {
  const r = speso / budget;
  const colore = r >= 1 ? "var(--rosso)" : r >= 0.8 ? "var(--arancio)" : "var(--verde)";
  const residuo = budget - speso;
  return `<div class="progresso"><div style="width:${Math.min(r, 1) * 100}%;background:${colore}"></div></div>
    <div class="dettaglio-budget"><span>${soldi(speso)} di ${soldi(budget)}</span>
    <span class="${residuo < 0 ? "negativo" : ""}">${residuo >= 0 ? "Restano " + soldi(residuo) : "Sforato di " + soldi(-residuo)}</span></div>`;
}

function avvisoInstallazione() {
  const installata = window.navigator.standalone || matchMedia("(display-mode: standalone)").matches;
  if (installata || localStorage.getItem("avviso-chiuso")) return "";
  return `<div class="avviso">📲 <b>Installa l'app:</b> in Safari tocca <b>Condividi</b> e poi <b>Aggiungi a Home</b>.
    Così si apre a schermo intero e funziona anche offline.<br><button data-azione="chiudi-avviso">Ho capito</button></div>`;
}

// ---------- Fogli modali ----------

function apriFoglio(html) {
  $("#foglio-contenuto").innerHTML = html;
  $("#foglio").classList.remove("nascosto");
}
function chiudiFoglio() {
  $("#foglio").classList.add("nascosto");
  $("#foglio-contenuto").innerHTML = "";
  render();
}

function editorMovimento(id) {
  const esistente = dati.movimenti.find((m) => m.id === id);
  const bozza = esistente ? { ...esistente } : {
    tipo: "uscita", importo: null, categoria: categorieDi("uscita")[0]?.id, data: oggiISO(), nota: "",
  };

  function disegna() {
    const cats = categorieDi(bozza.tipo);
    apriFoglio(`
      <div class="barra-foglio">
        <button data-f="annulla">Annulla</button>
        <strong>${esistente ? "Modifica" : "Nuovo movimento"}</strong>
        <button data-f="salva" class="salva">Salva</button>
      </div>
      <div class="segmenti">
        <button data-f-tipo="uscita" class="${bozza.tipo === "uscita" ? "attivo" : ""}">Uscita</button>
        <button data-f-tipo="entrata" class="${bozza.tipo === "entrata" ? "attivo" : ""}">Entrata</button>
      </div>
      <section class="card importo-grande">
        <span class="segno ${bozza.tipo === "uscita" ? "negativo" : "positivo"}">${bozza.tipo === "uscita" ? "−" : "+"}</span>
        <input id="f-importo" inputmode="decimal" placeholder="0,00" autocomplete="off"
          value="${bozza.importo ? String(bozza.importo).replace(".", ",") : ""}">
        <span class="sotto">${dati.valuta}</span>
      </section>
      <section class="card"><h2>Categoria</h2><div class="griglia-cat">
        ${cats.map((c) => `<button data-f-cat="${c.id}" class="${bozza.categoria === c.id ? "scelta" : ""}">
          ${iconaHTML(c)}<span class="etichetta">${esc(c.nome)}</span></button>`).join("")}
      </div></section>
      <section class="card">
        <label class="campo"><span>Data</span><input type="date" id="f-data" value="${bozza.data.slice(0, 10)}"></label>
        <label class="campo"><span>Nota</span><input id="f-nota" placeholder="Facoltativa" value="${esc(bozza.nota)}"></label>
      </section>
      ${esistente ? `<button class="btn-pieno pericolo" data-f="elimina">Elimina movimento</button>` : ""}`);

    const leggiCampi = () => {
      bozza.importo = leggiImporto($("#f-importo").value);
      bozza.data = $("#f-data").value || oggiISO();
      bozza.nota = $("#f-nota").value.trim();
    };

    $("#foglio-contenuto").onclick = (e) => {
      const t = e.target.closest("button");
      if (!t) return;
      if (t.dataset.fTipo && t.dataset.fTipo !== bozza.tipo) {
        leggiCampi();
        bozza.tipo = t.dataset.fTipo;
        bozza.categoria = categorieDi(bozza.tipo)[0]?.id;
        disegna();
      } else if (t.dataset.fCat) {
        bozza.categoria = t.dataset.fCat;
        document.querySelectorAll("[data-f-cat]").forEach((b) => b.classList.toggle("scelta", b === t));
      } else if (t.dataset.f === "annulla") {
        chiudiFoglio();
      } else if (t.dataset.f === "elimina") {
        if (confirm("Eliminare questo movimento?")) {
          dati.movimenti = dati.movimenti.filter((m) => m.id !== esistente.id);
          salvaDati();
          chiudiFoglio();
        }
      } else if (t.dataset.f === "salva") {
        leggiCampi();
        if (!bozza.importo) { $("#f-importo").focus(); return; }
        if (esistente) Object.assign(esistente, bozza);
        else dati.movimenti.push({ ...bozza, id: nuovoId() });
        salvaDati();
        chiudiFoglio();
      }
    };
    if (!esistente) setTimeout(() => $("#f-importo")?.focus(), 300);
  }
  disegna();
}

function editorBudget(id) {
  const c = categoria(id);
  apriFoglio(`
    <div class="barra-foglio">
      <button data-f="annulla">Annulla</button><strong>Budget mensile</strong>
      <button data-f="salva" class="salva">Salva</button>
    </div>
    <section class="card">
      <div class="riga">${iconaHTML(c)}<span class="testi nome">${esc(c.nome)}</span></div>
      <label class="campo"><span>Budget</span>
        <input id="f-budget" inputmode="decimal" placeholder="Nessuno" value="${c.budget ? String(c.budget).replace(".", ",") : ""}"></label>
    </section>
    <p class="piccolo">Lascia vuoto per non avere un budget su questa categoria.</p>`);
  $("#foglio-contenuto").onclick = (e) => {
    const t = e.target.closest("button");
    if (!t) return;
    if (t.dataset.f === "annulla") chiudiFoglio();
    if (t.dataset.f === "salva") {
      c.budget = leggiImporto($("#f-budget").value);
      salvaDati();
      chiudiFoglio();
    }
  };
}

function elencoCategorie(tipo) {
  const cats = categorieDi(tipo);
  const conta = (id) => dati.movimenti.filter((m) => m.categoria === id).length;
  apriFoglio(`
    <div class="barra-foglio">
      <button data-f="annulla">Fine</button>
      <strong>${tipo === "uscita" ? "Categorie di spesa" : "Categorie di entrata"}</strong>
      <button data-f="nuova">Nuova</button>
    </div>
    <section class="card">
      ${cats.map((c, i) => `<div class="riga">
        ${iconaHTML(c)}
        <button class="testi nome" style="text-align:left" data-modifica="${c.id}">${esc(c.nome)}
          <div class="sotto">${conta(c.id)} movimenti</div></button>
        <button data-su="${c.id}" ${i === 0 ? "disabled style='opacity:.3'" : ""} aria-label="Sposta su">▲</button>
        <button data-giu="${c.id}" ${i === cats.length - 1 ? "disabled style='opacity:.3'" : ""} aria-label="Sposta giù">▼</button>
      </div>`).join("")}
    </section>
    <p class="piccolo">Tocca una categoria per modificarla o eliminarla. Usa le frecce per cambiare l'ordine.</p>`);

  $("#foglio-contenuto").onclick = (e) => {
    const t = e.target.closest("button");
    if (!t) return;
    if (t.dataset.f === "annulla") return chiudiFoglio();
    if (t.dataset.f === "nuova") return editorCategoria(null, tipo);
    if (t.dataset.modifica) return editorCategoria(t.dataset.modifica, tipo);
    const id = t.dataset.su || t.dataset.giu;
    if (id) {
      const i = cats.findIndex((c) => c.id === id);
      const j = t.dataset.su ? i - 1 : i + 1;
      [cats[i], cats[j]] = [cats[j], cats[i]];
      cats.forEach((c, k) => (c.ordine = k));
      salvaDati();
      elencoCategorie(tipo);
    }
  };
}

function editorCategoria(id, tipo) {
  const esistente = categoria(id);
  const bozza = esistente ? { ...esistente } : { nome: "", icona: ICONE[0], colore: COLORI[7], tipo };

  function disegna() {
    apriFoglio(`
      <div class="barra-foglio">
        <button data-f="annulla">Annulla</button>
        <strong>${esistente ? "Modifica categoria" : "Nuova categoria"}</strong>
        <button data-f="salva" class="salva">Salva</button>
      </div>
      <section class="card" style="text-align:center">
        <span class="icona" style="width:64px;height:64px;font-size:32px;margin:0 auto 10px;background:${bozza.colore}33">${bozza.icona}</span>
        <label class="campo"><input id="f-nome" placeholder="Nome categoria" style="text-align:center" value="${esc(bozza.nome)}"></label>
      </section>
      <section class="card"><h2>Colore</h2><div class="scelte">
        ${COLORI.map((c) => `<button data-colore="${c}" class="${c === bozza.colore ? "scelta" : ""}" style="background:${c}"></button>`).join("")}
      </div></section>
      <section class="card"><h2>Icona</h2><div class="scelte">
        ${ICONE.map((i) => `<button data-icona="${i}" class="${i === bozza.icona ? "scelta" : ""}">${i}</button>`).join("")}
      </div></section>
      ${esistente ? `<button class="btn-pieno pericolo" data-f="elimina">Elimina categoria</button>` : ""}`);

    $("#foglio-contenuto").onclick = (e) => {
      const t = e.target.closest("button");
      if (!t) return;
      bozza.nome = $("#f-nome").value.trim();
      if (t.dataset.colore) { bozza.colore = t.dataset.colore; disegna(); }
      else if (t.dataset.icona) { bozza.icona = t.dataset.icona; disegna(); }
      else if (t.dataset.f === "annulla") elencoCategorie(tipo);
      else if (t.dataset.f === "elimina") {
        if (confirm("Eliminare la categoria? I movimenti resteranno, senza categoria.")) {
          dati.categorie = dati.categorie.filter((c) => c.id !== esistente.id);
          dati.movimenti.forEach((m) => { if (m.categoria === esistente.id) m.categoria = null; });
          salvaDati();
          elencoCategorie(tipo);
        }
      } else if (t.dataset.f === "salva") {
        if (!bozza.nome) { $("#f-nome").focus(); return; }
        if (esistente) Object.assign(esistente, bozza);
        else dati.categorie.push({ ...bozza, id: nuovoId(), budget: null, ordine: 999 });
        salvaDati();
        elencoCategorie(tipo);
      }
    };
  }
  disegna();
}

// ---------- Esportazione e backup ----------

function scarica(nome, contenuto, tipo) {
  const file = new File([contenuto], nome, { type: tipo });
  if (navigator.canShare && navigator.canShare({ files: [file] })) {
    navigator.share({ files: [file] }).catch(() => {});
    return;
  }
  const a = document.createElement("a");
  a.href = URL.createObjectURL(file);
  a.download = nome;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

function esportaCSV() {
  const righe = ["data;tipo;categoria;importo;nota"];
  for (const m of [...dati.movimenti].sort((a, b) => a.data.localeCompare(b.data))) {
    const c = categoria(m.categoria);
    righe.push([m.data.slice(0, 10), m.tipo, c ? c.nome : "", m.importo.toFixed(2).replace(".", ","),
      (m.nota || "").replace(/[;\n]/g, " ")].join(";"));
  }
  scarica("Movimenti.csv", "﻿" + righe.join("\n"), "text/csv");
}

function ripristina(file) {
  const lettore = new FileReader();
  lettore.onload = () => {
    try {
      const nuovi = JSON.parse(lettore.result);
      if (!Array.isArray(nuovi.movimenti) || !Array.isArray(nuovi.categorie)) throw new Error();
      if (!confirm(`Sostituire i dati attuali con il backup (${nuovi.movimenti.length} movimenti)?`)) return;
      dati = nuovi;
      salvaDati();
      render();
    } catch (e) {
      alert("Il file non è un backup valido.");
    }
  };
  lettore.readAsText(file);
}

// ---------- Eventi ----------

document.querySelector(".tabbar").addEventListener("click", (e) => {
  const b = e.target.closest("button[data-tab]");
  if (!b) return;
  stato.tab = b.dataset.tab;
  render();
  window.scrollTo(0, 0);
});

$("#selettore-mese").addEventListener("click", (e) => {
  const b = e.target.closest("button[data-mese]");
  if (!b) return;
  stato.mese = new Date(stato.mese.getFullYear(), stato.mese.getMonth() + Number(b.dataset.mese), 1);
  render();
});

$("#btn-aggiungi").addEventListener("click", () => editorMovimento(null));
$("#foglio").addEventListener("click", (e) => { if (e.target.dataset.chiudi !== undefined) chiudiFoglio(); });

$("#contenuto").addEventListener("click", (e) => {
  const b = e.target.closest("button");
  if (!b) return;
  if (b.dataset.movimento) editorMovimento(b.dataset.movimento);
  else if (b.dataset.budget) editorBudget(b.dataset.budget);
  else if (b.dataset.filtro) { stato.filtro = b.dataset.filtro; render(); }
  else if (b.dataset.tipo) { stato.tipoStat = b.dataset.tipo; render(); }
  else if (b.dataset.azione === "categorie-uscita") elencoCategorie("uscita");
  else if (b.dataset.azione === "categorie-entrata") elencoCategorie("entrata");
  else if (b.dataset.azione === "esporta-csv") esportaCSV();
  else if (b.dataset.azione === "backup") scarica(`backup-spese-${oggiISO()}.json`, JSON.stringify(dati), "application/json");
  else if (b.dataset.azione === "ripristina") $("#file-backup").click();
  else if (b.dataset.azione === "chiudi-avviso") { localStorage.setItem("avviso-chiuso", "1"); render(); }
});

$("#contenuto").addEventListener("input", (e) => {
  if (e.target.id === "ricerca") {
    stato.ricerca = e.target.value;
    const pos = e.target.selectionStart;
    render();
    const campo = $("#ricerca");
    campo.focus();
    campo.setSelectionRange(pos, pos);
  }
});

$("#contenuto").addEventListener("change", (e) => {
  if (e.target.id === "valuta") { dati.valuta = e.target.value; salvaDati(); render(); }
  if (e.target.id === "file-backup" && e.target.files[0]) ripristina(e.target.files[0]);
});

if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});

render();
