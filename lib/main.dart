import 'package:flutter/material.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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

  String risultato = "";

  void calcola() {
    double ultima = double.tryParse(_ultima.text.replaceAll(",", ".")) ?? 0;
    double media = double.tryParse(_media.text.replaceAll(",", ".")) ?? 0;

    if (media == 0) return;

    double diff = ((ultima - media) / media) * 100;

    if (diff > 20) {
      risultato = """
⚠️ Possibile anomalia rilevata (+${diff.toStringAsFixed(1)}%)

Oggetto: Reclamo per anomalia importo bolletta

Spett.le ${_azienda.text},

Il sottoscritto ${_nome.text}, codice cliente ${_codice.text},
segnala un importo anomalo nell’ultima bolletta pari a €${_ultima.text},
rispetto alla media precedente di €${_media.text}.

Si richiede verifica dettagliata e eventuale rettifica dell’importo.

In attesa di riscontro scritto.

Cordiali saluti.
""";
    } else {
      risultato = "Nessuna anomalia significativa rilevata.";
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bolletta Check")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _ultima,
              decoration: const InputDecoration(labelText: "Ultima bolletta (€)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _media,
              decoration: const InputDecoration(labelText: "Media bollette precedenti (€)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _azienda,
              decoration: const InputDecoration(labelText: "Nome azienda"),
            ),
            TextField(
              controller: _codice,
              decoration: const InputDecoration(labelText: "Codice cliente"),
            ),
            TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: "Il tuo nome"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: calcola,
              child: const Text("Verifica e genera reclamo"),
            ),
            const SizedBox(height: 20),
            SelectableText(risultato),
          ],
        ),
      ),
    );
  }
}