#ifndef H_LANG_IT
#define H_LANG_IT

// Thanks: MontyTRC

const char *STR_IT[] = { ""
// help
    , "Caricamento..."
    , "Press H for help"
    , helpText
    , "%s@@@"
      "UCCISIONI %d@@"
      "OGG. RACCOLTI %d@@"
      "SEGRETI %d di %d@@"
      "TEMPO %s"
    , "Salvataggio partita..."
    , "Salvataggio completato!"
    , "ERRORE DURANTE IL SALVATAGGIO!"
    , "S$I"
    , "NO"
    , "Off"
    , "On"
    , "Off"
    , "Side-By-Side"
    , "Anaglyph"
    , "Schermo diviso"
    , "VR"
    , "Basso"
    , "Medio"
    , "Alto"
    , STR_LANGUAGES
    , "Applica"
    , "Gamepad 1"
    , "Gamepad 2"
    , "Gamepad 3"
    , "Gamepad 4"
    , "Non pronto"
    , "Giocatore 1"
    , "Giocatore 2"
    , "Premi un tasto qualsiasi"
    , "%s - Seleziona"
    , "%s - Indietro"
// inventory pages
    , "OPZIONI"
    , "INVENTARIO"
    , "OGGETTI"
// save game page
    , "Salvare la partita?"
    , "Posizione attuale"
// inventory option
    , "Partita"
    , "Mappa"
    , "Bussola"
    , "Statistiche"
    , "Casa di Lara"
    , "Livelli di Dettaglio"
    , "Suoni"
    , "Controlli"
    , "Gamma"
// passport menu
    , "Carica partita"
    , "Inizia partita"
    , "Ricomincia livello"
    , "Torna ai titoli"
    , "Esci dal gioco"
    , "Seleziona livello"
// detail options
    , "Scegli Dettaglio"
    , "Filtro"
    , "Illuminazione"
    , "Ombra"
    , "Acqua"
    , "VSync"
    , "Stereo"
    , "Oggetti Semplici"
// sound options
    , "Imposta il Volume"
    , "Riverbero"
    , "Sottotitoli"
    , "Linguaggio"
// controls options
    , "Modifica Controlli"
    , "Tastiera"
    , "Gamepad"
    , "Vibrazione"
    , "Retargeting"
    , "Mira multipla"
    // controls
    , "Sinistra", "Destra", "Corri", "Indietro", "Jump", "Cammina", "Azione", "Estrai Arma", "Guarda", "Accovacciati", "Scatta", "Capriola", "Inventario", "Start"
    , STR_KEYS
// inventory items
    , "Sconosciuto"
    , "Esplosivo"
    , "Pistole"
    , "Fucile"
    , "Magnum"
    , "Uzi"
    , "Munizioni Pistola"
    , "Munizioni Fucile"
    , "Munizioni Magnum"
    , "Munizioni Uzi"
    , "Piccolo medikit"
    , "Grande medikit"
    , "Barra di piombo"
    , "Scion"
// keys
    , "Chiave"
    , "Chiave d'argento"
    , "Chiave arrugginita"
    , "Chiave d'oro"
    , "Chiave di zaffiro"
    , "Chiave di Nettuno"
    , "Chiave di Atlante"
    , "Chiave di Damocle"
    , "Chiave di Thor"
    , "Chiave Cesellata"
// puzzles
    , "Puzzle"
    , "Idolo d'oro"
    , "Barra d'oro"
    , "Ruota Dentata"
    , "Fusibile"
    , "Ankh"
    , "Occhio di Horus"
    , "Sigillo di Anubi"
    , "Scarabeo"
    , "Chiave della piramide"
// TR1 subtitles
    /* CAFE */ ,
    ""
    /* LIFT */ ,
    ""
    /* CANYON */ ,
    ""
    /* PRISON */ ,
    ""
    /* 22 */ , ""
    /* 23 */ , ""
    /* 24 */ , ""
    /* 25 */ , ""
    /* 26 */ , "Benvenuto nella mia casa."
    /* 27 */ , "Usa i tasti di controllo per andare nella stanza della musica."
    /* 28 */ , "Ok. Facciamo qualche acrobazia.@Premi il tasto Salto."
    /* 29 */ , "Ora fallo di nuovo premendo in una@delle direzioni: salter$o da quella parte."
    /* 30 */ , "Ecco l'atrio principale.@Scusa per quelle casse, ho imballato alcune cose@e il fattorino non $e ancora venuto."
    /* 31 */ , "Corri vicino a una cassa e, continuando a premere Avanti,@premi Azione e io ci salter$o sopra."
    /* 32 */ , "Una volta questa stanza era una sala da ballo,@ma io l'ho trasformata nella mia palestra personale.@Cosa ne pensi?@Ok, facciamo qualche esercizio."
    /* 33 */ , "In effetti io non corro sempre.@Quando devo essere cauta, cammino.@Tieni premuto il tasto Cammina e raggiungi la linea bianca."
    /* 34 */ , "Con il tasto Cammina premuto, non cadr$o@nemmeno se mi spingi a farlo.@Avanti, prova pure."
    /* 35 */ , "Se vuoi guardarti intorno, premi e tieni premuto il tasto Guarda.@Quindi premi nella direzione in cui vuoi guardare."
    /* 36 */ , "Se un salto $e troppo lungo, posso aggrapparmi al@bordo e risparmiarmi una brutta caduta.@Cammina verso il bordo con la linea bianca@finch)e non posso pi$u andare avanti.@Quindi premi Salto, immediatamente seguito da Avanti,@e mentre sono in aria premi e tieni premuto il tasto Azione."
    /* 37 */ , "Premi Avanti e mi arrampicher$o."
    /* 38 */ , "Se faccio un salto con rincorsa, posso arrivare@a quella distanza, senza alcun problema."
    /* 39 */ , "Cammina verso il bordo con la linea bianca finch)e mi fermo.@Quindi rilascia il tasto Cammina e premi una@volta Avanti per farmi prendere la rincorsa.@Premi Avanti e subito dopo premi e tieni premuto il tasto Salto.@Non spiccher$o il salto fino all'ultimo secondo."
    /* 40 */ , "Perfetto. Questo $e davvero grande.@Allora, fai un salto con rincorsa esattamente come prima,@ma questa volta, mentre sono in aria premi e tieni premuto@il tasto Azione per farmi aggrappare al bordo."
    /* 41 */ , "Bene."
    /* 42 */ , "Prova a saltare qui su.@Premi avanti e tieni premuto il tasto Azione."
    /* 43 */ , "Non posso arrampicarmi su perch)e la fessura $e troppo stretta.@Per$o puoi premere destra: mi sposter$o@lateralmente finch)e c'$e spazio, poi premi avanti."
    /* 44 */ , "Ottimo!@Se c'$e un grosso dislivello e non voglio farmi@male cadendo, posso calarmi gi$u lentamente."
    /* 45 */ , "Premi una volta indietro e far$o un salto in quella direzione.@Poi, immediatamente, premi e tieni premuto il@tasto Azione: mi aggrapper$o al bordo per scendere."
    /* 46 */ , "Ora lascia."
    /* 47 */ , "Andiamo a farci una nuotata."
    /* 48 */ , "Usa il tasto Salto ed i tasti di controllo@per muovermi sott'acqua."
    /* 49 */ , "Ah! Aria!@Usa avanti, sinistra e destra per muoverti quando sei a galla.@Premi Salto per immergerti e fare un'altra nuotata.@Oppure vai sul bordo e premi Azione per uscire."
    /* 50 */ , "Perfetto. Ora sar$a meglio che mi tolga@questi vestiti bagnati."
    /* 51 */ , "Sorridi!"
    /* 52 */ , "Niente di personale."
    /* 53 */ , "Maledetto, mi fai ancora venire il mal di testa.@E mi fai venire in mente alcuni pensieri cattivi@ad esempio spararti!"
    /* 54 */ , "Non puoi liberarti di me e della mia@stirpe cos$i facilmente, Lara."
    /* 55 */ , "Un po' in ritardo per la premiazione, no?@Tanto l'importante $e partecipare, giusto?"
    /* 56 */ , "Mi stai sparando?@Ehi, stai sparando a me?@Eh s$i, non c'$e nessun altro, stai proprio sparando a me!"
// TR1 levels
    , "Casa di Lara"
    , "Caverne"
    , "Citt$a di Vilcabamba"
    , "Valle perduta"
    , "Tomba di Qualopec"
    , "Rovine di St. Francis"
    , "Colosseo"
    , "Palazzo di Mida"
    , "La Cisterna"
    , "Tomba di Tihocan"
    , "Citt$a di Khamoon"
    , "Obelisco di Khamoon"
    , "Santuario dello Scion"
    , "Miniere di Natla"
    , "Atlantide"
    , "La grande piramide"
    , "Ritorno in Egitto"
    , "Tempio della Gatta"
    , "Fortezza Atlantidea"
    , "L'Alveare"
// TR2 levels
    , "Lara's Home"
    , "La Grande Muraglia"
    , "Venezia"
    , "Covo di Bartoli"
    , "Teatro dell'Opera"
    , "Piattaforma offshore"
    , "Area d'immersione"
    , "40 atmosfere"
    , "Relitto della Maria Doria"
    , "Saloni abitati"
    , "Il ponte"
    , "Pendici tibetante"
    , "Monastero di Barkhang"
    , "Catacombe di Talion"
    , "Palazzo del ghiaccio"
    , "Tempio dello Xian"
    , "Isole galleggianti"
    , "La tana del Drago"
    , "Casa dolce casa"
// TR3 levels
    , "Casa di Lara"
    , "Giungla"
    , "Rovine del tempio"
    , "Il fiume Gange"
    , "Caverne di Kaliya"
    , "Villaggio costiero"
    , "Luogo dell'incidente"
    , "Gola di Madubu"
    , "Tempio di Puna"
    , "Molo sul Tamigi"
    , "Aldwych"
    , "Cancello di Lud"
    , "Citt$a di Londra"
    , "Deserto del Nevada"
    , "Reparto di massima sicurezza"
    , "Area 51"
    , "Antartico"
    , "Miniere RX-Tech"
    , "CittГ  perduta di Tinnos"
    , "Caverna del meteorite"
    , "All Hallows"
};

#endif
