import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const BollettaCheckApp());
}

class BollettaCheckApp extends StatelessWidget {
  const BollettaCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bolletta Check',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F4F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Input
  final _ultima = TextEditingController();
  final _media = TextEditingController();
  final _azienda = TextEditingController();
  final _codice = TextEditingController();
  final _nome = TextEditingController();
  final _pec = TextEditingController();
  final _citta = TextEditingController();

  // Output
  String reclamo = '';
  bool anomalia = false;
  double? diffPerc;

  @override
  void dispose() {
    _ultima.dispose();
    _media.dispose();
    _azienda.dispose();
    _codice.dispose();
    _nome.dispose();
    _pec.dispose();
    _citta.dispose();
    super.dispose();
  }

  double _parseEuro(String s) {
    final cleaned = s
        .trim()
        .replaceAll('€', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  // ✅ NUOVO: svuota tutti i campi e resetta risultato
  void _nuovo() {
    setState(() {
      _ultima.clear();
      _media.clear();
      _azienda.clear();
      _codice.clear();
      _nome.clear();
      _pec.clear();
      _citta.clear();

      reclamo = '';
      anomalia = false;
      diffPerc = null;
    });
  }

  void _generaReclamo() {
    final ultima = _parseEuro(_ultima.text);
    final media = _parseEuro(_media.text);

    if (ultima <= 0 || media <= 0) {
      setState(() {
        reclamo = 'Inserisci importi validi (ultima bolletta e media).';
        anomalia = false;
        diffPerc = null;
      });
      return;
    }

    final diff = ((ultima - media) / media) * 100;
    diffPerc = diff;
    anomalia = diff > 20.0;

    final azienda = _azienda.text.trim().isEmpty ? '________' : _azienda.text.trim();
    final nome = _nome.text.trim().isEmpty ? '________' : _nome.text.trim();
    final codice = _codice.text.trim().isEmpty ? '________' : _codice.text.trim();
    final pec = _pec.text.trim().isEmpty ? '________' : _pec.text.trim();
    final citta = _citta.text.trim().isEmpty ? '________' : _citta.text.trim();
    final data = _fmtDate(DateTime.now());

    final ultimaTxt = _ultima.text.trim().isEmpty ? ultima.toStringAsFixed(2) : _ultima.text.trim();
    final mediaTxt = _media.text.trim().isEmpty ? media.toStringAsFixed(2) : _media.text.trim();

    if (!anomalia) {
      setState(() {
        reclamo =
            'Esito: nessuna anomalia significativa (${diff.toStringAsFixed(1)}%).\n\n'
            'Se vuoi comunque procedere, puoi inviare un reclamo indicando i dettagli e chiedendo verifica/trasparenza.\n'
            'Suggerimento: prova a inserire valori reali e premi di nuovo.';
      });
      return;
    }

    setState(() {
      reclamo = '''
Oggetto: Reclamo formale per importo anomalo bolletta – richiesta verifica e rettifica

Spett.le $azienda,

il/la sottoscritto/a $nome (codice cliente/POD/PDR: $codice) segnala un importo anomalo nell’ultima bolletta pari a €$ultimaTxt, rispetto alla media delle bollette precedenti pari a €$mediaTxt (variazione: +${diff.toStringAsFixed(1)}%).

Con la presente si richiede:
1) verifica dettagliata dei consumi e dei criteri di fatturazione/calcolo;
2) rettifica dell’importo e storno/rimborso di eventuali addebiti non dovuti;
3) riscontro scritto entro i termini previsti.

Recapito PEC per risposta (se disponibile): $pec

In difetto di riscontro, ci si riserva di attivare le procedure di conciliazione previste.

$citta, $data

Cordiali saluti
$nome
'''.trim();
    });
  }

  Future<void> _copiaReclamo() async {
    if (reclamo.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: reclamo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclamo copiato')));
  }

  Future<void> _scaricaPdfPec() async {
    if (reclamo.trim().isEmpty || !anomalia) return;

    final doc = pw.Document();

    final azienda = _azienda.text.trim().isEmpty ? '________' : _azienda.text.trim();
    final nome = _nome.text.trim().isEmpty ? '________' : _nome.text.trim();
    final codice = _codice.text.trim().isEmpty ? '________' : _codice.text.trim();
    final pec = _pec.text.trim().isEmpty ? '________' : _pec.text.trim();
    final citta = _citta.text.trim().isEmpty ? '________' : _citta.text.trim();
    final data = _fmtDate(DateTime.now());
    final perc = diffPerc == null ? '—' : '+${diffPerc!.toStringAsFixed(1)}%';

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RECLAMO FORMALE – PRONTO PER PEC',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Esito: possibile anomalia ($perc)', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 18),

              pw.Text('Destinatario:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Spett.le $azienda', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12),

              pw.Text('Dati del cliente:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Nome e cognome: $nome', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Codice cliente / POD / PDR: $codice', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('PEC per risposta (se disponibile): $pec', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),

              pw.Text(
                'Oggetto: Reclamo formale per importo anomalo bolletta – richiesta verifica e rettifica',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Text(
                reclamo,
                style: const pw.TextStyle(fontSize: 11),
              ),

              pw.SizedBox(height: 18),
              pw.Divider(),
              pw.SizedBox(height: 8),

              pw.Text(
                'Allegati consigliati:',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Bullet(text: 'Copia bolletta contestata (PDF).'),
              pw.Bullet(text: 'Eventuale documento d’identità (se richiesto dall’azienda).'),
              pw.Bullet(text: 'Eventuali letture/consumi e comunicazioni precedenti.'),

              pw.SizedBox(height: 18),
              pw.Text('Luogo e data: $citta, $data', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Text('Firma: __________________________', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(nome, style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final canPdf = anomalia && reclamo.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolletta Check'),
        actions: [
          IconButton(
            tooltip: 'Copia reclamo',
            onPressed: reclamo.trim().isEmpty ? null : _copiaReclamo,
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Ti hanno gonfiato la bolletta?',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Inserisci gli importi: se è anomala, generi il reclamo formale e il PDF pronto per PEC.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ultima,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ultima bolletta (€)',
                              prefixIcon: Icon(Icons.receipt_long_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _media,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Media bollette precedenti (€)',
                              prefixIcon: Icon(Icons.query_stats_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _azienda,
                            decoration: const InputDecoration(
                              labelText: 'Azienda (es. Enel Energia)',
                              prefixIcon: Icon(Icons.business_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _codice,
                            decoration: const InputDecoration(
                              labelText: 'Codice cliente / POD / PDR',
                              prefixIcon: Icon(Icons.badge_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nome,
                            decoration: const InputDecoration(
                              labelText: 'Nome e cognome',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _pec,
                            decoration: const InputDecoration(
                              labelText: 'Tua PEC (opzionale)',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _citta,
                      decoration: const InputDecoration(
                        labelText: 'Città (per firma, opzionale)',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ QUI HO INSERITO "NUOVO" (riga nuova)
                    OutlinedButton.icon(
                      onPressed: _nuovo,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nuovo'),
                    ),

                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _generaReclamo,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Verifica e genera reclamo'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: canPdf ? _scaricaPdfPec : null,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Scarica PDF pronto per PEC'),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: SelectableText(
                        reclamo.trim().isEmpty
                            ? 'Qui apparirà il reclamo. Compila i campi e premi “Verifica e genera reclamo”.'
                            : reclamo,
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}