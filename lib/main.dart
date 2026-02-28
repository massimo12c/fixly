import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const BollettaApp());
}

class BollettaApp extends StatelessWidget {
  const BollettaApp({super.key});

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
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: EdgeInsets.zero,
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
  final _ultima = TextEditingController();
  final _media = TextEditingController();
  final _azienda = TextEditingController();
  final _codice = TextEditingController();
  final _nome = TextEditingController();
  final _emailPec = TextEditingController();

  String risultato = "";
  bool anomalia = false;
  double? diffPerc;

  @override
  void dispose() {
    _ultima.dispose();
    _media.dispose();
    _azienda.dispose();
    _codice.dispose();
    _nome.dispose();
    _emailPec.dispose();
    super.dispose();
  }

  double _parseEuro(String s) {
    final cleaned = s.trim().replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  void calcola() {
    final ultima = _parseEuro(_ultima.text);
    final media = _parseEuro(_media.text);

    if (media <= 0 || ultima <= 0) {
      setState(() {
        anomalia = false;
        diffPerc = null;
        risultato = "Inserisci importi validi (ultima bolletta e media).";
      });
      return;
    }

    final diff = ((ultima - media) / media) * 100;
    diffPerc = diff;

    final soglia = 20.0;
    anomalia = diff > soglia;

    if (!anomalia) {
      setState(() {
        risultato =
            "Nessuna anomalia significativa rilevata (${diff.toStringAsFixed(1)}%).\n"
            "Se pensi comunque ci sia un errore, puoi scrivere un reclamo indicando i dettagli.";
      });
      return;
    }

    final azienda = _azienda.text.trim().isEmpty ? "________" : _azienda.text.trim();
    final nome = _nome.text.trim().isEmpty ? "________" : _nome.text.trim();
    final codice = _codice.text.trim().isEmpty ? "________" : _codice.text.trim();
    final pec = _emailPec.text.trim().isEmpty ? "________" : _emailPec.text.trim();

    final ultimaTxt = _ultima.text.trim().isEmpty ? ultima.toStringAsFixed(2) : _ultima.text.trim();
    final mediaTxt = _media.text.trim().isEmpty ? media.toStringAsFixed(2) : _media.text.trim();

    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yyyy = now.year.toString();
    final data = "$dd/$mm/$yyyy";

    setState(() {
      risultato = """
Oggetto: Reclamo per importo anomalo bolletta – richiesta verifica e rettifica

Spett.le $azienda,

Il/La sottoscritto/a $nome (codice cliente: $codice), con la presente segnala un importo anomalo nell’ultima bolletta pari a €$ultimaTxt, rispetto alla media delle bollette precedenti pari a €$mediaTxt (variazione: +${diff.toStringAsFixed(1)}%).

Si richiede:
1) verifica dettagliata dei consumi e dei criteri di fatturazione;
2) rettifica dell’importo e storno di eventuali addebiti non dovuti;
3) riscontro scritto entro i termini previsti.

Recapito PEC (per risposta): $pec

Luogo e data: $data

Cordiali saluti
$nome
""".trim();
    });
  }

  Future<void> scaricaPdf() async {
    if (risultato.trim().isEmpty) return;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RECLAMO PRONTO PER PEC',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              if (anomalia && diffPerc != null)
                pw.Text(
                  'Esito: possibile anomalia (+${diffPerc!.toStringAsFixed(1)}%)',
                  style: pw.TextStyle(fontSize: 11),
                ),
              pw.SizedBox(height: 18),
              pw.Text(risultato, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 18),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Suggerimento: allega la bolletta (PDF) e indica eventuale POD/PDR o numero fornitura.',
                style: pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final canPdf = risultato.trim().isNotEmpty && anomalia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolletta Check'),
        actions: [
          IconButton(
            tooltip: 'Copia reclamo',
            onPressed: risultato.trim().isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: risultato));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reclamo copiato')),
                      );
                    }
                  },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "Ti hanno gonfiato la bolletta?",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Inserisci gli importi: se è anomala, generi il reclamo pronto per PEC in 30 secondi.",
                      style: TextStyle(fontSize: 16, color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ultima,
                            decoration: const InputDecoration(
                              labelText: "Ultima bolletta (€)",
                              prefixIcon: Icon(Icons.receipt_long_rounded),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _media,
                            decoration: const InputDecoration(
                              labelText: "Media bollette precedenti (€)",
                              prefixIcon: Icon(Icons.query_stats_rounded),
                            ),
                            keyboardType: TextInputType.number,
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
                              labelText: "Azienda (es. Enel Energia)",
                              prefixIcon: Icon(Icons.business_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _codice,
                            decoration: const InputDecoration(
                              labelText: "Codice cliente / POD / PDR (se lo hai)",
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
                              labelText: "Nome e cognome",
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _emailPec,
                            decoration: const InputDecoration(
                              labelText: "Tua PEC (per risposta, opzionale)",
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: calcola,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text("Verifica e genera reclamo"),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: canPdf ? scaricaPdf : null,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text("Scarica PDF pronto per PEC"),
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
                        risultato.trim().isEmpty
                            ? "Qui apparirà il reclamo. Compila i campi e premi “Verifica e genera reclamo”."
                            : risultato,
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