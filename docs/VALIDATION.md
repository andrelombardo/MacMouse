# Verifiche della beta 0.1.2

Ambiente locale del 16 ottobre 2026: macOS 27.0.1 (26A434), Apple Silicon arm64, Swift 6.4, SDK macOS 27.0, Command Line Tools. Xcode completo non installato localmente.

| Verifica | Esito |
| --- | --- |
| Compilazione Release del package e creazione MacMouse.app | Superata |
| Verifica codesign strict | Superata; Apple Development nell’installazione locale, ad hoc nella distribuzione pubblica |
| 31 test automatici Swift Testing | Superati |
| Azioni Scrivania a sinistra/destra | Voci presenti nel menu della copia installata; configurazione senza registrazione, serializzazione e gestione delle pressioni verificate automaticamente. Passaggio fisico tra gli spazi da verificare manualmente |
| Coppie di eventi Quartz down/up, flag modificatori, marcatore sintetico | Superata con eventi creati in memoria, senza invio globale |
| Pressione/rilascio, trascinamento centrale, interruzione, down duplicati | Superata nella macchina a stati |
| 10.000 cicli di pressione/rilascio | Superati nella macchina a stati |
| Persistenza, dati corrotti, schema futuro, codici duplicati | Superata |
| Avvio reale del bundle e stato con permesso mancante | Superata |
| Pop-up Rileva pulsante, candidati ripetuti, conferma e annullamento | Macchina a stati verificata; nell’interfaccia reale rilevati i pulsanti 3 e 4 senza salvataggio automatico |
| Rilevamento locale senza permesso globale | Verificato nel pop-up reale con i pulsanti aggiuntivi del mouse |
| Riquadro accessibile e indicazione premuto/rilasciato | Verificati nell’albero Accessibilità della finestra reale |
| Menu azioni, registrazione Command–Shift–K e persistenza al riavvio | Superata nell’interfaccia reale |
| Ripristino e diagnostica nell’interfaccia reale | Superata |
| Interfaccia chiara e scura | Verificata visivamente |
| Progetto Xcode | Build Release superata nel workflow GitHub con Xcode 27 |
| Chiusura finestra e riapertura | Processo mantenuto attivo e finestra riaperta correttamente |
| Firma Developer ID e notarizzazione | Non disponibili |
| TECKNET TK-MS317, Bluetooth / USB e provenienza HID | Non verificati fisicamente |
| Permesso del bundle installato | Dopo il consenso alla nuova copia: controllo del dispositivo e invio eventi entrambi consentiti, motore attivo |
| Event tap globale | Creazione e avvio verificati nel processo installato; azioni fisiche nelle app da verificare manualmente |
| Aggiornamento del consenso TCC | Eseguito per il solo bundle MacMouse con reset mirato, aggiunta tramite Impostazioni di Sistema e autenticazione dell’utente |
| Installazione con app già in esecuzione | Rifiutata prima di modificare il bundle, anche con argomenti di avvio |
| Avvio dopo vero login, sleep/wake | Da verificare manualmente |
| Uso giornaliero, consumi continuativi, leak e opzioni di accessibilità | Da verificare manualmente |

I test automatici non richiedono permessi elevati e non inviano click o scorciatoie all’utente. Le immagini nel README sono screenshot dell’app realmente eseguita: le due immagini principali documentano lo stato iniziale della 0.1.0, il pop-up documenta il rilevamento reale nella 0.1.1. Non rappresentano una certificazione del modello hardware.

La [pipeline](https://github.com/andrelombardo/MacMouse/actions) separa test automatici, compilazione Xcode, packaging e firma opzionale. Una build verde non sostituisce i [test manuali](MANUAL_TESTS.md).
