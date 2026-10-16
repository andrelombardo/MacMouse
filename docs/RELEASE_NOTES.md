MacMouse 0.1.3 beta 1 corregge il cambio scrivania e rende verificabile l’invio delle azioni.

- Gli eventi freccia includono ora il flag funzione implicito previsto dalle scorciatoie di sistema. Le combinazioni complete restano accoppiate e serializzate, senza mantenere modificatori sintetici premuti.
- Quando scegli Scrivania a sinistra/destra, la finestra ricorda che servono almeno due spazi in Mission Control. Con un solo spazio o al limite della sequenza, una direzione non produce uno spostamento.
- La diagnostica permette di provare entrambe le azioni e mostra l’ultima combinazione inviata e il numero di cambi spazio osservati. Questi dati restano in memoria soltanto mentre è aperta.
- Sulla copia locale entrambe le direzioni sono state confermate dall’utente con i pulsanti fisici 4 e 3, dopo la creazione di un secondo spazio.

**Requisiti:** macOS 27+, Apple Silicon. Scarica `MacMouse-v0.1.3-macOS.zip` oppure il DMG e verifica `SHA256SUMS.txt`.

**Firma della Release pubblica:** ad hoc, senza Developer ID e senza notarizzazione. La firma Apple Development eventualmente usata per l’installazione locale non è inclusa in questi archivi. Gatekeeper può richiedere la procedura di approvazione offerta da macOS; nessuna protezione viene disabilitata.

**Consenso macOS:** una compilazione ad hoc può richiedere di riaggiungere l’app in Privacy e sicurezza → Controllo del dispositivo e accesso ai dati. Se macOS conserva ancora un’identità precedente, può essere necessario un riavvio del Mac. Il rilevamento locale nel pop-up non sostituisce il permesso necessario per rimappare globalmente.

**Verifiche:** 32 test automatici su pressione/rilascio, selezione provvisoria e conferma, annullamento, duplicati, isolamento dei clic primari, eventi sintetici, stati delle autorizzazioni, persistenza e recupero del tap. La build Release Xcode e i pacchetti sono verificati dal workflow prima della pubblicazione.

**Limiti:** profilo globale, senza attribuzione degli eventi al singolo mouse. Il supporto fisico completo al TECKNET TK-MS317 resta da verificare con la [procedura manuale](https://github.com/andrelombardo/MacMouse/blob/main/docs/MANUAL_TESTS.md). Navigazione dipendente dai menu dell’app e dal layout; le azioni di sistema richiedono scorciatoie abilitate. Logout/login reale, sleep/wake e uso prolungato richiedono ancora verifica manuale.
