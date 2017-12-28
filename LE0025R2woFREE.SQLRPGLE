//------------------------------------------------------------------------------------------*
//                                                                                          *
// Wareneingangsscannung mobil                                                              *
//                                                                                          *
//------------------------------------------------------------------------------------------*
//  Datum   / Author / Beschreibung                                                         *
//------------------------------------------------------------------------------------------*
// 13.03.17 / DB     / Erstellung                                                           *
//------------------------------------------------------------------------------------------*
Ctl-Opt Main(Main);
 
//------------------------------------------------------------------------------------------*
// Dateibestimmungen                                                                        *
//------------------------------------------------------------------------------------------*
Dcl-F Dialog   Workstn
               Handler('PROFOUNDUI(HANDLER)')
               Usage(*Input:*Output)
               Extdesc('LE0025D2')
               Extfile(*Extdesc)
               Usropn;
 
Dcl-F LKSTAM01 Disk
               Usage(*Input)
               Usropn
               Keyed;
 
//------------------------------------------------------------------------------------------*
// Programmstatus-Datenstruktur
//------------------------------------------------------------------------------------------*
Dcl-Ds EXCPGM Len(429) Psds Qualified;
  MAINPROC *PROC;
  JOB    Char(10)  Pos(244);
  USER   Char(10)  Pos(254);
  JOBNBR Char(6)   Pos(264);
  ALL    Char(429) Pos(1);
End-Ds;
 
//------------------------------------------------------------------------------------------*
// externe Programme                                                                        *
//------------------------------------------------------------------------------------------*
/Copy QCPYSRC,SO0024R
/Copy QCPYSRC,SO0011R
/Copy QCPYSRC,SO0004R
/Copy QCPYSRC,SO0007R
/Copy QCPYSRC,SO0072R
/Copy QCPYSRC,LE0008R
/Copy QCPYSRC,LE0009R1
 
//------------------------------------------------------------------------------------------*
// Globale Felddeklarationen                                                                *
//------------------------------------------------------------------------------------------*
Dcl-S g_master Ind;               // Kennzeichen Master-Palette
Dcl-S g_MNVE   Char(22);          // Master-NVE
Dcl-S g_WENRK  Char(2) Inz('01'); // Wareneingangsnummernkreis
Dcl-S g_WENR   Char(10);          // Wareneingangsnummer
Dcl-S g_VBNRK  Char(2) Inz('11'); // Verbundnummernkreis
Dcl-S g_VBNR   Char(10);          // Verbundnummer
Dcl-S g_LOT    Ind;               // Lotindikator
Dcl-S g_ERROR  Ind;               // Fehlerkennzeichen
Dcl-S g_NVE    Char(18);          // NVE ohne Datenbezeichner
Dcl-S g_LHMN   Packed(4);         // LHM-Numer
 
 
// EAN128-Scannung
Dcl-S SO0072_SC   Char(2);                         // Startcode
Dcl-S SO0072_RC   Char(2);                         // Returncode
Dcl-S SO0072_DATA Char(48);                        // Datenstring
Dcl-S SO0072_SYMB Char(2);                         // Symboligie-Identifier
Dcl-Ds SO0072_OUTP;
  SO0072_ELEM     Char(34) Dim(5);                 // Datenelemente
  SO0072_DBEZ     Char(4)  Overlay(SO0072_ELEM:1); // Datenbezeichner
  SO0072_DINH     Char(30) Overlay(SO0072_ELEM:5); // Dateninhalt
End-Ds;
Dcl-S SO0072_MVHE Char(1);                         // mengenvariable HE
Dcl-S DTALIB      Char(10) DtaAra;                 //Datenbereich DTALIB
 
 
//------------------------------------------------------------------------------------------*
// Hauptsteuerung                                                                           *
//------------------------------------------------------------------------------------------*
Dcl-Proc Main;
  Dcl-Pi *N ExtPgm('LE0025R2');
    pep_FINR Char(2);
    pep_KDNR Char(10);
  End-Pi;
 
  // Dateien öffnen
  If openFile();
    // Initialisierung
    initialize(pep_FINR : pep_KDNR);
    DoU BTN_ENDE = '1' ;
 
      If TXT_SHIPM <> *Blanks;
        SHPM_VISI = *On;
        SEL_SHIPM = %Trim(TXT_SHIPM);
      EndIf;
 
      Exfmt Start;
 
      If TXT_ARNR <> *Blank;
 
        DoU BTN_BACK = '1';
 
          // Vorbereitung des Scannungsdialogs
          prepareScan(pep_FINR : pep_KDNR);
 
          Exfmt Scannung;
 
          If TXT_SCANN <> *Blanks;
            checkScan();
          EndIf;
 
          If g_error = *Off;
 
            If g_master = *On;
 
              // Verarbeitung der Master - Scannung
              If TXT_SCANN <> *Blanks And OUT_MASTER = *Blanks;
                processMaster(pep_FINR : pep_KDNR);
              ElseIf (TXT_SCANN <> *Blanks Or
                      TXT_MENGE <> *Zeros) And
                      OUT_MASTER <> *Blanks;
                processMScan(pep_FINR : pep_KDNR);
              EndIf;
 
              // Palette abschließen und buchen
              If BTN_OK = '1';
                // Wareneingang buchen
                warehouseGoods(pep_FINR : pep_KDNR);
                // Masterfelder wieder zurücksetzen
                OUT_NVE    = *Blanks;
                OUT_MENGE  = *Zeros;
              EndIf;
 
            ElseIf g_master = *Off;
              // Verarbeitung der Scannung
              If TXT_SCANN <> *Blanks Or
                 TXT_MENGE <> *Zeros;
                processSScan(pep_FINR : pep_KDNR);
              EndIf;
 
              // Karton abschließen und buchen
              If BTN_OK = '1';
                // Wareneingang buchen
                warehouseGoods(pep_FINR : pep_KDNR);
                OUT_NVE    = *Blanks;
                OUT_MENGE  = *Zeros;
              EndIf;
 
            EndIf;
 
          EndIf;
 
        EndDo;
        // Felder zurücksetzen
        TXT_MSG    = *Blanks;
        TXT_ARNR   = *Blanks;
        TXT_LONR   = *Blanks;
        TXT_FAR    = *Blanks;
        TXT_GRO    = *Blanks;
        TXT_SAISON = *Blanks;
        OUT_NVE    = *Blanks;
        OUT_MENGE  = *Zeros;
      EndIf;
 
    EndDo;
  EndIf;
 
  // Dateien schließen
  closeFile();
 
  Return;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Initialisierung                                                                          *
//------------------------------------------------------------------------------------------*
Dcl-Proc initialize;
  Dcl-Pi *N ;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  // Felder initialisieren
  OUT_ART   = *Blanks;
  OUT_MASTER = *Blanks;
  OUT_MENGE  = *Zeros;
  OUT_NVE    = *Blanks;
  OUT_SHIPM  = *Blanks;
  OUT_PGM    = *Blanks;
  OUT_USER   = EXCPGM.USER;
 
  TXT_CHARGE = *Blanks;
  TXT_ARNR   = *Blanks;
  TXT_FAR    = *Blanks;
  TXT_GRO    = *Blanks;
  TXT_LONR   = *Blanks;
  TXT_SAISON = *Blanks;
  TXT_SHIPM  = *Blanks;
  TXT_MENGE  = *Zeros;
  TXT_SCANN  = *Blanks;
  TXT_MSG    = *Blanks;
 
  CMB_MNVE   = 'N';
  g_master   = *Off;
  g_ERROR = *Off;
  SHPM_VISI  = *Off;
  SEL_SHIPM  = *Blanks;
 
  // Versorgung Programmname
  OUT_PGM = EXCPGM.MAINPROC;
 
  // Wareneingangsnummer ermitteln
  SO0011R(p_FINR : g_WENRK : g_WENR);
 
  // Subfile nach Wareneingangsnummer filtern
  MASTER_SEL = g_WENR;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Vorbereitung des Scanndialogs                                                            *
//------------------------------------------------------------------------------------------*
Dcl-Proc prepareScan;
  Dcl-Pi *N;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  If CMB_MNVE = 'J';
    g_master   = *On;
    IMG_NVE    = '/profoundui/userdata/linkimages/Palette.jpg';
    MNG_VISI   = *Off;
    TXT_SCANN  = *Blanks;
    If g_ERROR = *Off;
      TXT_MSG    = 'Master-NVE scannen';
    EndIf;
  ElseIf CMB_MNVE = 'N';
    IMG_NVE    = '/profoundui/userdata/linkimages/Karton1.jpg';
    MNG_VISI   = *On;
    TXT_SCANN  = *Blanks;
    If g_ERROR = *Off;
      If OUT_NVE = *Blanks;
        FOCUS_SCAN = *On;
        FOCUS_MNG  = *Off;
        TXT_MSG    = 'Karton-NVE scannen';
      Else;
        FOCUS_SCAN = *Off;
        FOCUS_MNG  = *On;
        TXT_MSG    = 'Menge eingeben';
      EndIf;
    EndIf;
  EndIf;
 
  OUT_SHIPM = 'Shipment: ' + TXT_SHIPM;
  OUT_ART   = %Trim(TXT_ARNR) + ', ' + %Trim(TXT_LONR) + ', ' +
              %Trim(TXT_FAR)  + ', ' + %Trim(TXT_GRO)  + ', ' +
              %Trim(TXT_SAISON);
 
  IMG_ART   = '/bilder/' + %trim(TXT_ARNR) +'.JPG';
  g_ERROR   = *Off;
 
  If TXT_LONR <> *Blanks;
    g_LOT = *On;
  Else;
    g_LOT = *Off;
  EndIf;
 
  If ACT_SEC = 1;
    BACK_VISI = *Off;
    BOOK_VISI = *Off;
  Else;
    BACK_VISI = *On;
    BOOK_VISI = *On;
  EndIf;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Überprüfung der gescannten NVE                                                           *
//------------------------------------------------------------------------------------------*
Dcl-Proc checkScan;
  Dcl-Pi *N;
  End-Pi;
 
  If %Subst(TXT_SCANN:1:3) = '+C1' Or
     %Subst(TXT_SCANN:1:3) = ']C1' Or
     %Subst(TXT_SCANN:2:2) = 'C1';
 
    g_NVE       = %Subst(TXT_SCANN:6);
    SO0072_SC   = '00';
    SO0072_DATA = TXT_SCANN;
 
    //Auflösung Datenbezeichner
    SO0072R (SO0072_SC:
             SO0072_RC:
             TXT_SCANN:
             SO0072_SYMB:
             SO0072_OUTP:
             SO0072_MVHE);
 
    // NVE ungültig
    If SO0072_RC      <> '00' And
       SO0072_DBEZ(1) <> '00' And
       g_NVE          <> %Trim(SO0072_DINH(1));
      TXT_MSG = 'NVE ungültig';
      g_Error = *On;
    EndIf;
  Else;
    TXT_MSG = 'Das ist keine NVE';
    g_Error = *On;
  EndIf;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Verarbeitung der Master - Scannung                                                       *
//------------------------------------------------------------------------------------------*
Dcl-Proc processMaster;
  Dcl-Pi *N;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  g_MNVE     = %Subst(TXT_SCANN:6);
  OUT_MASTER = 'Master-NVE: ' + g_MNVE;
  TXT_SCANN  = *Blanks;
  CMB_MNVE   = 'N';
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Verarbeitung der Master - Einzel - Scannung                                              *
//------------------------------------------------------------------------------------------*
Dcl-Proc processMScan;
  Dcl-Pi *N;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  Dcl-S l_DATU Date;
  Dcl-S l_TIME Time;
  Dcl-S l_NVE  Char(18);
 
  l_DATU = %Date;
  l_TIME = %Time;
 
  l_NVE = %Subst(TXT_SCANN:6);
 
  If OUT_NVE <> l_NVE and l_NVE <> *Blanks;
    Exec Sql
      Insert Into MASNVE00
                  (MAFINR, MAKDNR,
                   MAVLNR,
                   MANVEM, MANVES,
                   MADATU, MAZEIT,
                   MAUSER)
           Values (:p_FINR,  :p_KDNR,
                   :g_WENR,
                   :g_MNVE,  :l_NVE,
                   :l_DATU,  :l_TIME,
                   :OUT_USER);
 
    OUT_NVE   = l_NVE;
  EndIf;
 
  // Anzeige füllen
  If TXT_MENGE <> *Zeros;
    OUT_MENGE = TXT_MENGE;
  Endif;
 
  //Felder zurücksetzen
  TXT_SCANN = *Blanks;
  TXT_MENGE = *Zeros;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Verarbeitung der Einzel - Scannung                                                       *
//------------------------------------------------------------------------------------------*
Dcl-Proc processSScan;
  Dcl-Pi *N;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  Dcl-S l_NVE  Char(18);
 
  l_NVE = %Subst(TXT_SCANN:6);
 
  If l_NVE <> *Blanks;
    OUT_NVE   = l_NVE;
  EndIf;
 
  // Anzeige füllen
  If TXT_MENGE <> *Zeros;
    OUT_MENGE = TXT_MENGE;
  Endif;
 
  //Felder zurücksetzen
  TXT_SCANN = *Blanks;
  TXT_MENGE = *Zeros;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Wareneingang buchen                                                                      *
//------------------------------------------------------------------------------------------*
Dcl-Proc warehouseGoods;
  Dcl-Pi *N;
    p_FINR Char(2);
    p_KDNR Char(10);
  End-Pi;
 
  Dcl-S l_GRHA  Char(4);        // Gridhandle
  Dcl-S l_STS   Char(10);       // Status
  Dcl-S l_MOD   Char(10);       // Modus
  Dcl-S l_LERR  Char(6);        // Fehler
  Dcl-S l_APLAN Char(12);       // Abwicklungsplan
  Dcl-S l_ULAND Char(2);        // Ursprungsland
 
  // Vorbesetzen für Wareneingang buchen
  l_STS  = '*PROCESS';
  l_MOD  = '*ADD';
 
  DoU 1 = 1;
 
    If g_master = *On;
      // Es muss eine Master-NVE hinterlegt sein.
      If OUT_MASTER = *Blanks;
        TXT_MSG = 'Es muss eine Master-NVE hinterlegt sein.';
        Leave;
      EndIf;
    EndIf;
 
    // Es muss eine NVE gescannt werden.
    If OUT_NVE = *Blanks;
      TXT_MSG = 'Es muss eine NVE gescannt werden.';
      Leave;
    EndIf;
 
    // Die Menge muss angegeben werden.
    If OUT_MENGE = *Zeros;
      TXT_MSG = 'Die Menge muss angegeben werden.';
      Leave;
    EndIf;
 
    // Farb- Größenraster erstellen (*CREATE)
    SO0004R(p_FINR       :
            p_KDNR       :
            TXT_ARNR     :
            'WE - Mobil' :
            l_GRHA       :
            l_LERR
            );
 
    // Ermittlung der Verbundnummer
    SO0011R(p_FINR : g_VBNRK : g_VBNR);
 
    //LHM-Nummer hochzählen
    g_LHMN +=1;
 
    // Ermittlung Ursprungsland und Abwicklungsplan
    Exec Sql
      Select EKULAND, EKAPLAN
        Into :l_ULAND, :l_APLAN
        From ELAVKO00
       Where EKFINR = :p_FINR
         And EKKDNR = :p_KDNR
         And EKAUNR = :TXT_SHIPM;
 
    // Bei einem Lot...
    If g_LOT = *On;
 
      SetLl (p_FINR   :
             p_KDNR   :
             TXT_ARNR :
             TXT_LONR) LKSTAM01;
 
      DoU %Eof(LKSTAM01);
        ReadE (p_FINR   :
               p_KDNR   :
               TXT_ARNR :
               TXT_LONR) LKSTAM01;
        If %Eof(LKSTAM01);
          Leave;
        EndIf;
 
        // Farb- Größenraster schreiben Lot(*WRITE)
        SO0007R(l_STS  :
                l_GRHA :
                l_MOD  :
                LKFAR  :
                LKGRO  :
                LKMNG  :
                l_LERR
                );
 
      EndDo;
 
      // Workfile Wareneingang - Erfassung LOT
      Exec Sql
        Insert Into WAREIN00
             Values (:p_FINR,    :p_KDNR,         // Firma, Kunde
                     :g_WENR,    '0000000001',    // Wareneingangsnummer, lfd. Nummer
                     :l_GRHA,    :TXT_ARNR,       // Rasterhandle, Artikelnummer
                     :TXT_LONR,  :OUT_MENGE,      // Lotnummer, Lot-Menge
                     1,          'Mobil',         // Anzahl VSE, VSE-Kennung
                     :LKMNG, '',                  // Einzelteile, Externe Auftragsn.
                     '',         :TXT_SAISON,     // PO-Nummer, Saison
                     :TXT_CHARGE);                // Charge
 
 
      // Workfile WE: Zuordnung LHM, VSE Kopfdatei Lot
      Exec Sql
        Insert Into ZUOKOP00
             Values (:p_FINR,    :p_KDNR,        // Firma, Kunde
                     :g_WENR,    :g_VBNR,        // Wareneingangsnummer, Verbundnummer
                     :TXT_ARNR,  :LKMNG,         // Artikelnummer, Menge Lot
                     :OUT_MENGE, 1,              // Menge fr. Einteilung, Anzahl VSE
                     :OUT_NVE,   :g_LHMN,        // Versand-EH-Kennung, LHM-Nr.
                     1,          '',             // VSE-Nr., VSE-Id
                     '');                        // Externe Auftragsnummer
 
    ElseIf g_LOT = *Off;
 
      // Farb- Größenraster schreiben Einzelartikel(*WRITE)
      SO0007R(l_STS     :
              l_GRHA    :
              l_MOD     :
              TXT_FAR   :
              TXT_GRO   :
              OUT_MENGE :
              l_LERR
              );
 
      // Workfile Wareneingang - Erfassung Einzelartikel
      Exec Sql
        Insert Into WAREIN00
             Values (:p_FINR,   :p_KDNR,         // Firma, Kunde
                     :g_WENR,   '0000000001',    // Wareneingangsnummer, lfd. Nummer
                     :l_GRHA,   :TXT_ARNR,       // Rasterhandle, Artikelnummer
                     '',        0,               // Lotnummer, Lot-Menge
                     1,         'Mobil',         // Anzahl VSE, VSE-Kennung
                     :OUT_MENGE, '',             // Einzelteile, Externe Auftragsn.
                     '',        :TXT_SAISON,     // PO-Nummer, Saison
                     :TXT_CHARGE);               // Charge
 
      // Workfile WE: Zuordnung LHM, VSE Kopfdatei Einzelartikel
      Exec Sql
        Insert Into ZUOKOP00
             Values (:p_FINR,    :p_KDNR,        // Firma, Kunde
                     :g_WENR,    :g_VBNR,        // Wareneingangsnummer, Verbundnummer
                     :TXT_ARNR,  0,              // Artikelnummer, Menge Lot
                     :OUT_MENGE, 1,              // Menge fr. Einteilung, Anzahl VSE
                     :OUT_NVE,   :g_LHMN,        // Versand-EH-Kennung, LHM-Nr.
                     1,          '',             // VSE-Nr., VSE-Id
                     '');                        // Externe Auftragsnummer
 
    EndIf;
 
    // Wareneingang - Lägerplatze
    Exec Sql
      Insert Into LAGPLA00
           Values (:p_FINR,   :p_KDNR,         // Firma, Kunde
                   :g_WENR,   1,               // Wareneingangsnummer, Position
                   'XXXXXX',  '',              // LHM-Verbund-Id, LHM-Id
                   'WE',      'BLOCK1',        // Physisches Lager, Lagerplatz
                   'N');                       // Kz. LHM-Id
 
    If l_APLAN <> *Blanks And l_ULAND <> *Blanks;
      // Wareneingang - Lagerplatzzuordnung
      Exec Sql
        Insert Into LOGDAT00
             Values (:p_FINR,     :p_KDNR,         // Firma, Kunde
                     :g_WENR,     'ZL',            // Wareneingangsnummer, logisches Lager
                     'WE',        'EZ',            // physisches Lager, Ladehilfsmittel
                     'N',         '0',             // LHM-Verbund, Anzahl LHM
                     1,           'N',             // Anz. VSE je LHM, Vergabe VSE-Id
                     'NOR',                        // Warenart
                     '',          :OUT_SHIPM,      // T-Papier-Nr., Bemerkung
                     '',          :l_APLAN,        // Individuelle Nr., Abwicklungsplan
                     :TXT_CHARGE, :l_ULAND);       // Chargennummer, Ursprungsland
    Else;
      // Wareneingang - Lagerplatzzuordnung
      Exec Sql
        Insert Into LOGDAT00
             Values (:p_FINR,     :p_KDNR,         // Firma, Kunde
                     :g_WENR,     'FL',            // Wareneingangsnummer, logisches Lager
                     'WE',        'EZ',            // physisches Lager, Ladehilfsmittel
                     'N',         '0',             // LHM-Verbund, Anzahl LHM
                     1,           'N',             // Anz. VSE je LHM, Vergabe VSE-Id
                     'NOR',                        // Warenart
                     '',          :OUT_SHIPM,      // T-Papier-Nr., Bemerkung
                     '',          :l_APLAN,        // Individuelle Nr., Abwicklungsplan
                     :TXT_CHARGE, :l_ULAND);       // Chargennummer, Ursprungsland
    EndIf;
 
    // Wareneing.- Lagerplatzzuord. - Positionsdatei
    Exec Sql
      Insert Into ZUOPOS00
           Values (:p_FINR,     :p_KDNR,       // Firma, Kunde
                   :g_WENR,     :g_VBNR,       // Wareneingangsnummer, Verbundnummer
                   :TXT_ARNR,   :TXT_LONR,     // Artikelnummer, Lotnummer
                   :TXT_FAR,    :TXT_GRO,      // Farbe, Größe
                   :OUT_MENGE,  '0000000001',  // Menge, lfd. Nummer
                   :TXT_SAISON, :TXT_CHARGE);  // Saison, Charge
 
    // Wareneingang - Verbuchung
    LE0008R(p_FINR :       //--> Firmennummer
            p_KDNR :       //--> Kundennummer
            g_WENR :       //--> Wareneingangsnummer
            ''     :       //--> Avisnummer
            ''     :       //--> Avistyp
            0      :       //--> Einzul. Teile
            0      :       //--> Ausgel. Teile
            ''             //--> KZ. Teileerfassung
           );
 
    LE0009R1(p_FINR :      //--> Firmennummer
             p_KDNR :      //--> Kundennummer
             g_WENR :      //--> Wareneingangsnummer
             ''     :      //--> Avisnummer
             ''            //--> Avistyp
             );
 
    If g_LOT = *On;
      // DFÜ Einlagerungsavis Positionen - Lot
      Exec Sql
        Update ELAVPO00
           Set EPMNGLG = EPMNGLG + :OUT_MENGE
         Where EPFINR  = :p_FINR
           And EPKDNR  = :p_KDNR
           And EPAUNR  = :TXT_SHIPM
           And EPARNR  = :TXT_ARNR
           And EPLONR  = :TXT_LONR;
    Else;
      // DFÜ Einlagerungsavis Positionen - Einzelartikel
      Exec Sql
        Update ELAVPO00
           Set EPMNGLG = EPMNGLG + :OUT_MENGE
         Where EPFINR  = :p_FINR
           And EPKDNR  = :p_KDNR
           And EPAUNR  = :TXT_SHIPM
           And EPARNR  = :TXT_ARNR
           And EPFAR   = :TXT_FAR
           And EPGRO   = :TXT_GRO;
    EndIf;
 
    // Dateien bereinigen
    Exec Sql
      Delete From WAREIN00
            Where WEFINR = :p_FINR
              And WEKDNR = :p_KDNR
              And WEWENR = :g_WENR;
 
    Exec Sql
      Delete From LAGPLA00
            Where LFFINR = :p_FINR
              And LFKDNR = :p_KDNR
              And LFWENR = :g_WENR;
 
    Exec Sql
      Delete From LOGDAT00
            Where LGFINR = :p_FINR
              And LGKDNR = :p_KDNR
              And LGWENR = :g_WENR;
 
    Exec Sql
      Delete From ZUOKOP00
            Where ZKFINR = :p_FINR
              And ZKKDNR = :p_KDNR
              And ZKWENR = :g_WENR;
 
    Exec Sql
      Delete From ZUOPOS00
            Where ZPFINR = :p_FINR
              And ZPKDNR = :p_KDNR
              And ZPWENR = :g_WENR;
 
  EndDo;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Dateien öffnen                                                                           *
//------------------------------------------------------------------------------------------*
Dcl-Proc openFile;
  Dcl-Pi *N Ind;
  End-Pi;
 
  Monitor;
    Open Dialog;
    Open LKSTAM01;
    On-Error;
      Return *Off;
  Endmon;
 
  Return *On;
 
End-Proc;
 
//------------------------------------------------------------------------------------------*
// Dateien schließen                                                                          *
//------------------------------------------------------------------------------------------*
Dcl-Proc closeFile;
  Dcl-Pi *N Ind;
  End-Pi;
 
  Monitor;
    Close *All;
    On-Error;
      Return *Off;
  Endmon;
 
  Return *On;
 
End-Proc;
 
 
