Prima beta pubblica di MacMouse, utility nativa macOS in italiano.

- Due pulsanti aggiuntivi con rilevamento del codice Quartz effettivo.
- Navigazione, scorciatoie personalizzate, azioni di sistema, apertura di app, clic centrale, comportamento originale e disattivazione.
- Interfaccia SwiftUI con Liquid Glass nativo, menu bar e impostazioni locali.
- Avvio al login mediante ServiceManagement; nessun helper o servizio di rete.

**Requisiti:** macOS 27+, Apple Silicon. Archivio principale: `MacMouse-v0.1.0-macOS.zip`; disponibile anche DMG. Copiare MacMouse.app in Applicazioni prima di concedere Accessibilità. `SHA256SUMS.txt` permette di verificare gli archivi.

**Distribuzione:** firma ad hoc, senza Developer ID e senza notarizzazione. Gatekeeper può bloccare l’apertura: seguire la procedura di approvazione di macOS quando disponibile, oppure compilare localmente. Nessuno script disabilita le protezioni.

**Verifiche:** build Release locale con SDK macOS 27.0 e Swift 6.4; 23 test automatici superati su instradamento down/up/drag, indipendenza dei binding, eventi sintetici, modificatori, recupero limitato del tap, recupero impostazioni e persistenza. Verificati avvio, menu azioni, registrazione e persistenza della scorciatoia, ripristino e interfaccia chiara/scura. Lo stato della compilazione Xcode remota è consultabile in Actions.

**Limiti della beta:** TECKNET TK-MS317 e rimappatura globale reale non ancora verificati fisicamente; Accessibilità non concessa nell’ambiente di test. Profilo globale, senza attribuzione degli eventi al singolo dispositivo. Navigazione dipendente dai menu dell’app e dal layout tastiera. Le azioni di sistema richiedono scorciatoie abilitate; Launchpad / Applicazioni richiede una combinazione registrata dall’utente. Logout/login reale, cambi TCC, sleep/wake fisico e uso prolungato richiedono la [procedura manuale](https://github.com/andrelombardo/MacMouse/blob/main/docs/MANUAL_TESTS.md).
