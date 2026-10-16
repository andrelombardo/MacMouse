MacMouse 0.1.2 beta 1 aggiunge due azioni per passare direttamente tra le scrivanie.

- Scegli **Scrivania a sinistra** o **Scrivania a destra** nella sezione macOS del menu azioni del pulsante.
- Le azioni usano Control–← e Control–→ senza richiedere la registrazione della combinazione, che può essere intercettata dal sistema e cambiare scrivania durante la registrazione.
- Le scorciatoie di cambio scrivania devono essere abilitate nelle impostazioni della tastiera. Le associazioni già salvate e le autorizzazioni della copia locale vengono conservate.

**Requisiti:** macOS 27+, Apple Silicon. Scarica `MacMouse-v0.1.2-macOS.zip` oppure il DMG e verifica `SHA256SUMS.txt`.

**Firma della Release pubblica:** ad hoc, senza Developer ID e senza notarizzazione. La firma Apple Development eventualmente usata per l’installazione locale non è inclusa in questi archivi. Gatekeeper può richiedere la procedura di approvazione offerta da macOS; nessuna protezione viene disabilitata.

**Consenso macOS:** una compilazione ad hoc può richiedere di riaggiungere l’app in Privacy e sicurezza → Controllo del dispositivo e accesso ai dati. Se macOS conserva ancora un’identità precedente, può essere necessario un riavvio del Mac. Il rilevamento locale nel pop-up non sostituisce il permesso necessario per rimappare globalmente.

**Verifiche:** 31 test automatici su pressione/rilascio, selezione provvisoria e conferma, annullamento, duplicati, isolamento dei clic primari, eventi sintetici, stati delle autorizzazioni, persistenza e recupero del tap. La build Release Xcode e i pacchetti sono verificati dal workflow prima della pubblicazione.

**Limiti:** profilo globale, senza attribuzione degli eventi al singolo mouse. Il supporto fisico completo al TECKNET TK-MS317 resta da verificare con la [procedura manuale](https://github.com/andrelombardo/MacMouse/blob/main/docs/MANUAL_TESTS.md). Navigazione dipendente dai menu dell’app e dal layout; le azioni di sistema richiedono scorciatoie abilitate. Logout/login reale, sleep/wake e uso prolungato richiedono ancora verifica manuale.
