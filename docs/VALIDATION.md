# Verifiche della beta 0.1.0

Ambiente locale del 16 ottobre 2026: macOS 27.0.1 (26A434), Apple Silicon arm64, Swift 6.4, SDK macOS 27.0, Command Line Tools. Xcode completo non installato localmente.

| Verifica | Esito |
| --- | --- |
| Compilazione Release del package e creazione MacMouse.app | Superata |
| Verifica codesign strict | Superata, firma ad hoc |
| 23 test automatici Swift Testing | Superati |
| Coppie di eventi Quartz down/up, flag modificatori, marcatore sintetico | Superata con eventi creati in memoria, senza invio globale |
| Pressione/rilascio, trascinamento centrale, interruzione, down duplicati | Superata nella macchina a stati |
| 10.000 cicli di pressione/rilascio | Superati nella macchina a stati |
| Persistenza, dati corrotti, schema futuro, codici duplicati | Superata |
| Avvio reale del bundle e stato con permesso mancante | Superata |
| Menu azioni, registrazione Command–Shift–K e persistenza al riavvio | Superata nell’interfaccia reale |
| Ripristino e diagnostica nell’interfaccia reale | Superata |
| Interfaccia chiara e scura | Verificata visivamente |
| Progetto Xcode | Build Release superata nel workflow GitHub con Xcode 27 |
| Chiusura finestra e riapertura | Processo mantenuto attivo e finestra riaperta correttamente |
| Firma Developer ID e notarizzazione | Non disponibili |
| TECKNET TK-MS317, Bluetooth / USB e provenienza HID | Non verificati fisicamente |
| Event tap autorizzato e invio delle azioni nelle app | Non verificati globalmente: Accessibilità non concessa |
| Avvio dopo vero login, sleep/wake, revoca TCC | Da verificare manualmente |
| Uso giornaliero, consumi continuativi, leak e opzioni di accessibilità | Da verificare manualmente |

I test automatici non richiedono permessi elevati e non inviano click o scorciatoie all’utente. Le immagini nel README sono screenshot della finestra realmente eseguita, nello stato di autorizzazione mancante; non rappresentano test hardware riusciti.

La [pipeline](https://github.com/andrelombardo/MacMouse/actions) separa test automatici, compilazione Xcode, packaging e firma opzionale. Una build verde non sostituisce i [test manuali](MANUAL_TESTS.md).
