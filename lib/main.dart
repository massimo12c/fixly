import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final store = PracticheStore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifiche.init();
  await store.load();
  runApp(const FixlyApp());
}

/* =======================
   APP + THEME
======================= */

class FixlyApp extends StatelessWidget {
  const FixlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixly',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
          iconTheme: IconThemeData(color: Color(0xFF101828)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F4F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const PracticheHome(),
    );
  }
}

/* =======================
   MODELLI
======================= */

enum StatoPratica { nuova, inAttesa, risolta }

extension StatoPraticaX on StatoPratica {
  String get label => switch (this) {
        StatoPratica.nuova => 'Nuova',
        StatoPratica.inAttesa => 'In attesa',
        StatoPratica.risolta => 'Risolta',
      };
}

enum TipoProblema {
  internetLento,
  fatturaAlta,
  attivazioneNonRichiesta,
  disdettaDifficile,
  servizioNonFunzionante,
  rimborsoIndennizzo,
  altro
}

extension TipoProblemaX on TipoProblema {
  String get label => switch (this) {
        TipoProblema.internetLento => 'Internet lento / instabile',
        TipoProblema.fatturaAlta => 'Fattura troppo alta',
        TipoProblema.attivazioneNonRichiesta => 'Attivazione non richiesta',
        TipoProblema.disdettaDifficile => 'Disdetta difficile',
        TipoProblema.servizioNonFunzionante => 'Servizio non funzionante',
        TipoProblema.rimborsoIndennizzo => 'Rimborso / indennizzo',
        TipoProblema.altro => 'Altro',
      };
}

enum Azienda {
  tim,
  vodafone,
  windtre,
  enelEnergia,
  eniPlenitude,
  a2a,
  hera,
  poste,
  banca,
  altro
}

extension AziendaX on Azienda {
  String get label => switch (this) {
        Azienda.tim => 'TIM',
        Azienda.vodafone => 'Vodafone',
        Azienda.windtre => 'WindTre',
        Azienda.enelEnergia => 'Enel Energia',
        Azienda.eniPlenitude => 'Eni Plenitude',
        Azienda.a2a => 'A2A',
        Azienda.hera => 'Hera',
        Azienda.poste => 'Poste Italiane',
        Azienda.banca => 'Banca',
        Azienda.altro => 'Altro',
      };

  IconData get icon => switch (this) {
        Azienda.tim => Icons.wifi_rounded,
        Azienda.vodafone => Icons.network_cell_rounded,
        Azienda.windtre => Icons.network_wifi_rounded,
        Azienda.enelEnergia => Icons.bolt_rounded,
        Azienda.eniPlenitude => Icons.local_gas_station_rounded,
        Azienda.a2a => Icons.electric_bolt_rounded,
        Azienda.hera => Icons.water_drop_rounded,
        Azienda.poste => Icons.local_post_office_rounded,
        Azienda.banca => Icons.account_balance_rounded,
        Azienda.altro => Icons.apartment_rounded,
      };

  bool get isTelco => this == Azienda.tim || this == Azienda.vodafone || this == Azienda.windtre;

  bool get isEnergia =>
      this == Azienda.enelEnergia ||
      this == Azienda.eniPlenitude ||
      this == Azienda.a2a ||
      this == Azienda.hera;
}

class Pratica {
  final String id;
  final DateTime creataIl;

  Azienda azienda;
  String riferimento;
  TipoProblema tipoProblema;
  String descrizione;

  String? numeroTicket;
  DateTime? dataInizio;

  StatoPratica stato;

  DateTime? scadenzaRisposta;
  DateTime? scadenzaPassoSuccessivo;

  Pratica({
    required this.id,
    required this.creataIl,
    required this.azienda,
    required this.riferimento,
    required this.tipoProblema,
    required this.descrizione,
    this.numeroTicket,
    this.dataInizio,
    this.stato = StatoPratica.nuova,
    this.scadenzaRisposta,
    this.scadenzaPassoSuccessivo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'creataIl': creataIl.toIso8601String(),
        'azienda': azienda.name,
        'riferimento': riferimento,
        'tipoProblema': tipoProblema.name,
        'descrizione': descrizione,
        'numeroTicket': numeroTicket,
        'dataInizio': dataInizio?.toIso8601String(),
        'stato': stato.name,
        'scadenzaRisposta': scadenzaRisposta?.toIso8601String(),
        'scadenzaPassoSuccessivo': scadenzaPassoSuccessivo?.toIso8601String(),
      };

  static Pratica fromJson(Map<String, dynamic> j) => Pratica(
        id: (j['id'] ?? '').toString(),
        creataIl: DateTime.tryParse((j['creataIl'] ?? '').toString()) ?? DateTime.now(),
        azienda: Azienda.values.firstWhere(
          (e) => e.name == (j['azienda'] ?? '').toString(),
          orElse: () => Azienda.altro,
        ),
        riferimento: (j['riferimento'] ?? '').toString(),
        tipoProblema: TipoProblema.values.firstWhere(
          (e) => e.name == (j['tipoProblema'] ?? '').toString(),
          orElse: () => TipoProblema.altro,
        ),
        descrizione: (j['descrizione'] ?? '').toString(),
        numeroTicket: (j['numeroTicket'] as String?),
        dataInizio: j['dataInizio'] == null ? null : DateTime.tryParse(j['dataInizio'].toString()),
        stato: StatoPratica.values.firstWhere(
          (e) => e.name == (j['stato'] ?? '').toString(),
          orElse: () => StatoPratica.nuova,
        ),
        scadenzaRisposta: j['scadenzaRisposta'] == null ? null : DateTime.tryParse(j['scadenzaRisposta'].toString()),
        scadenzaPassoSuccessivo: j['scadenzaPassoSuccessivo'] == null
            ? null
            : DateTime.tryParse(j['scadenzaPassoSuccessivo'].toString()),
      );
}

/* =======================
   STORE (SALVATAGGIO + NOTIFICHE)
======================= */

class PracticheStore extends ChangeNotifier {
  static const _kKey = 'fixly_pratiche_v1';

  final List<Pratica> _pratiche = [];

  List<Pratica> get pratiche => List.unmodifiable(_pratiche);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _pratiche
        ..clear()
        ..addAll(list.map(Pratica.fromJson));
      notifyListeners();
      await Notifiche.syncAll(_pratiche);
    } catch (_) {
      // ignore
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_pratiche.map((e) => e.toJson()).toList());
    await prefs.setString(_kKey, raw);
  }

  void add(Pratica p) {
    _pratiche.insert(0, p);
    notifyListeners();
    save();
    Notifiche.syncAll(_pratiche);
  }

  void remove(String id) {
    _pratiche.removeWhere((p) => p.id == id);
    notifyListeners();
    save();
    Notifiche.syncAll(_pratiche);
  }

  void update() {
    notifyListeners();
    save();
    Notifiche.syncAll(_pratiche);
  }

  String exportJson() => jsonEncode(_pratiche.map((e) => e.toJson()).toList());

  void importJson(String raw) {
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _pratiche
      ..clear()
      ..addAll(list.map(Pratica.fromJson));
    notifyListeners();
    save();
    Notifiche.syncAll(_pratiche);
  }
}

/* =======================
   HOME
======================= */

class PracticheHome extends StatefulWidget {
  const PracticheHome({super.key});

  @override
  State<PracticheHome> createState() => _PracticheHomeState();
}

class _PracticheHomeState extends State<PracticheHome> {
  @override
  void initState() {
    super.initState();
    store.addListener(_rerender);
  }

  @override
  void dispose() {
    store.removeListener(_rerender);
    super.dispose();
  }

  void _rerender() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fixly'),
        actions: [
          IconButton(
            tooltip: 'Esporta (debug)',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _ExportDialog(raw: store.exportJson()),
            ),
            icon: const Icon(Icons.upload_rounded),
          ),
          IconButton(
            tooltip: 'Importa (debug)',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _ImportDialog(),
            ),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              'Le tue pratiche',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF101828),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Azienda, script, reclamo e scadenze in un posto solo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: store.pratiche.isEmpty
                  ? _EmptyState(onCreate: () => _openNuova(context))
                  : ListView.separated(
                      itemCount: store.pratiche.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = store.pratiche[i];
                        return _PraticaCard(
                          pratica: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DettaglioPratica(pratica: p)),
                          ),
                          onDelete: () => store.remove(p.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNuova(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuova pratica'),
      ),
    );
  }

  void _openNuova(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuovaPratica()));
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea la tua prima pratica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Con Fixly hai script, reclamo e scadenze in un posto solo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuova pratica'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PraticaCard extends StatelessWidget {
  final Pratica pratica;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PraticaCard({
    required this.pratica,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final next = _nextDeadline(pratica);

    final badgeColor = switch (pratica.stato) {
      StatoPratica.nuova => const Color(0xFFEEF4FF),
      StatoPratica.inAttesa => const Color(0xFFFFFAEB),
      StatoPratica.risolta => const Color(0xFFECFDF3),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(pratica.azienda.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pratica.azienda.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            pratica.stato.label,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pratica.tipoProblema.label,
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rif: ${pratica.riferimento.isEmpty ? "—" : pratica.riferimento}',
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Prossima scadenza: ${_fmtDate(next)}',
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Elimina',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _nextDeadline(Pratica p) {
    final c = <DateTime>[];
    if (p.scadenzaRisposta != null) c.add(p.scadenzaRisposta!);
    if (p.scadenzaPassoSuccessivo != null) c.add(p.scadenzaPassoSuccessivo!);
    c.sort();
    return c.isEmpty ? null : c.first;
  }
}

/* =======================
   NUOVA PRATICA
======================= */

class NuovaPratica extends StatefulWidget {
  const NuovaPratica({super.key});

  @override
  State<NuovaPratica> createState() => _NuovaPraticaState();
}

class _NuovaPraticaState extends State<NuovaPratica> {
  final _formKey = GlobalKey<FormState>();

  Azienda _azienda = Azienda.tim;
  TipoProblema _tipo = TipoProblema.internetLento;

  final _riferimento = TextEditingController();
  final _descrizione = TextEditingController();

  DateTime? _dataInizio;

  @override
  void dispose() {
    _riferimento.dispose();
    _descrizione.dispose();
    super.dispose();
  }

  String get _labelRiferimento {
    if (_azienda.isTelco) return 'Numero linea (es. 0XXXXXXXXX)';
    if (_azienda.isEnergia) return 'Codice cliente / POD / PDR (se lo hai)';
    if (_azienda == Azienda.poste) return 'Codice cliente / Numero pratica';
    if (_azienda == Azienda.banca) return 'IBAN / Numero conto (se serve)';
    return 'Riferimento (facoltativo)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuova pratica')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Azienda>(
                              initialValue: _azienda,
                              decoration: const InputDecoration(
                                labelText: 'Azienda',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                              items: Azienda.values
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                                  .toList(),
                              onChanged: (v) => setState(() => _azienda = v ?? _azienda),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<TipoProblema>(
                              initialValue: _tipo,
                              decoration: const InputDecoration(
                                labelText: 'Problema',
                                prefixIcon: Icon(Icons.report_problem_rounded),
                              ),
                              items: TipoProblema.values
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                                  .toList(),
                              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _riferimento,
                        decoration: InputDecoration(
                          labelText: _labelRiferimento,
                          prefixIcon: const Icon(Icons.confirmation_number_rounded),
                        ),
                        validator: (v) {
                          if (_azienda.isTelco && (v == null || v.trim().isEmpty)) {
                            return 'Inserisci il numero linea';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descrizione,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Descrizione (cosa succede?)',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Scrivi due righe' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data inizio problema (opzionale)',
                                prefixIcon: Icon(Icons.event_rounded),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_dataInizio == null ? '—' : _fmtDate(_dataInizio!)),
                                  TextButton(
                                    onPressed: () async {
                                      final now = DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime(now.year - 2),
                                        lastDate: now,
                                        initialDate: _dataInizio ?? now,
                                      );
                                      if (picked != null) setState(() => _dataInizio = picked);
                                    },
                                    child: const Text('Scegli'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _save,
                            child: const Text('Crea pratica'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final created = DateTime.now();
    final id = created.millisecondsSinceEpoch.toString();

    final scad30 = created.add(const Duration(days: 30));
    final scad45 = created.add(const Duration(days: 45));

    store.add(
      Pratica(
        id: id,
        creataIl: created,
        azienda: _azienda,
        riferimento: _riferimento.text.trim(),
        tipoProblema: _tipo,
        descrizione: _descrizione.text.trim(),
        dataInizio: _dataInizio,
        scadenzaRisposta: scad30,
        scadenzaPassoSuccessivo: scad45,
      ),
    );

    Navigator.of(context).pop();
  }
}

/* =======================
   DETTAGLIO
======================= */

class DettaglioPratica extends StatefulWidget {
  final Pratica pratica;
  const DettaglioPratica({super.key, required this.pratica});

  @override
  State<DettaglioPratica> createState() => _DettaglioPraticaState();
}

class _DettaglioPraticaState extends State<DettaglioPratica> {
  @override
  Widget build(BuildContext context) {
    final p = widget.pratica;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pratica ${p.azienda.label}'),
        actions: [
          PopupMenuButton<StatoPratica>(
            tooltip: 'Stato',
            onSelected: (s) {
              setState(() => p.stato = s);
              store.update();
            },
            itemBuilder: (_) => StatoPratica.values
                .map((s) => PopupMenuItem(value: s, child: Text('Segna: ${s.label}')))
                .toList(),
            icon: const Icon(Icons.tune_rounded),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Dettagli',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Azienda', p.azienda.label),
                _kv('Riferimento', p.riferimento.isEmpty ? '—' : p.riferimento),
                _kv('Problema', p.tipoProblema.label),
                _kv('Stato', p.stato.label),
                _kv('Creato il', _fmtDate(p.creataIl)),
                _kv('Inizio problema', p.dataInizio == null ? '—' : _fmtDate(p.dataInizio!)),
                _kv('Ticket', p.numeroTicket ?? '—'),
                const SizedBox(height: 10),
                Text(p.descrizione),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Numero ticket (se te lo danno)',
                    prefixIcon: Icon(Icons.confirmation_number_rounded),
                  ),
                  controller: TextEditingController(text: p.numeroTicket ?? ''),
                  onChanged: (v) {
                    p.numeroTicket = v.trim().isEmpty ? null : v.trim();
                    store.update();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(title: 'Script chiamata', child: _CopyBox(text: buildScript(p))),
          const SizedBox(height: 12),
          _Section(title: 'Reclamo pronto', child: _CopyBox(text: buildReclamo(p))),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 170, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700))),
            Expanded(child: Text(v)),
          ],
        ),
      );
}

/* =======================
   UI PIECES
======================= */

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _CopyBox extends StatelessWidget {
  final String text;
  const _CopyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(text, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiato negli appunti')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copia'),
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================
   EXPORT / IMPORT (DEBUG)
======================= */

class _ExportDialog extends StatelessWidget {
  final String raw;
  const _ExportDialog({required this.raw});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export (debug)'),
      content: SizedBox(width: 520, child: SelectableText(raw)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: raw));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON copiato')));
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copia JSON'),
        ),
      ],
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import (debug)'),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: ctrl,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Incolla qui il JSON esportato...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(
          onPressed: () {
            try {
              store.importJson(ctrl.text.trim());
              Navigator.pop(context);
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON non valido')));
            }
          },
          child: const Text('Importa'),
        ),
      ],
    );
  }
}

/* =======================
   TESTI
======================= */

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yy = d.year.toString();
  return '$dd/$mm/$yy';
}

String buildScript(Pratica p) {
  final start = p.dataInizio == null ? '' : ' dal ${_fmtDate(p.dataInizio!)}';
  final ticket = (p.numeroTicket == null || p.numeroTicket!.isEmpty) ? '' : 'Ticket: ${p.numeroTicket}.';
  final rif = p.riferimento.isEmpty ? '' : 'Riferimento: ${p.riferimento}.';

  if (p.azienda.isTelco) {
    return [
      'Buongiorno, contatto ${p.azienda.label}.',
      if (rif.isNotEmpty) rif,
      'Problema: ${p.tipoProblema.label}$start.',
      'Dettagli: ${p.descrizione}.',
      if (ticket.isNotEmpty) ticket,
      'Chiedo numero pratica e tempi di risoluzione.',
      'Se previsto, chiedo rimborso/indennizzo per disservizio.',
    ].join('\n');
  }

  if (p.azienda.isEnergia) {
    return [
      'Buongiorno, contatto ${p.azienda.label}.',
      if (p.riferimento.isNotEmpty) 'Codice cliente / POD-PDR: ${p.riferimento}.',
      'Problema: ${p.tipoProblema.label}$start.',
      'Dettagli: ${p.descrizione}.',
      if (ticket.isNotEmpty) ticket,
      'Chiedo numero pratica, tempi di gestione e risposta scritta.',
    ].join('\n');
  }

  return [
    'Buongiorno, contatto ${p.azienda.label}.',
    if (rif.isNotEmpty) rif,
    'Problema: ${p.tipoProblema.label}$start.',
    'Dettagli: ${p.descrizione}.',
    if (ticket.isNotEmpty) ticket,
    'Chiedo numero pratica e tempi di gestione.',
  ].join('\n');
}

String buildReclamo(Pratica p) {
  final dataDis = p.dataInizio == null ? '—' : _fmtDate(p.dataInizio!);
  final ticket = p.numeroTicket == null ? '—' : p.numeroTicket!;
  final rif = p.riferimento.isEmpty ? '—' : p.riferimento;

  final oggetto = p.azienda.isTelco
      ? 'Reclamo per disservizio – ${p.azienda.label} – Linea $rif'
      : p.azienda.isEnergia
          ? 'Reclamo – ${p.azienda.label} – Codice/POD/PDR $rif'
          : 'Reclamo – ${p.azienda.label} – Riferimento $rif';

  return '''
Oggetto: $oggetto

Spett.le ${p.azienda.label},
il/la sottoscritto/a segnala quanto segue.

Azienda: ${p.azienda.label}
Riferimento: $rif
Problema: ${p.tipoProblema.label}
Data inizio problema: $dataDis
Ticket/segnalazione: $ticket

Descrizione:
${p.descrizione}

Richieste:
1) Presa in carico e gestione/risoluzione della problematica.
2) Comunicazione scritta dell’esito e dei tempi.
3) Verifica addebiti non dovuti e, se presenti, storno/rimborso.

Distinti saluti.
(Firma)
(Nome e cognome)
(Recapito)
'''.trim();
}

/* =======================
   NOTIFICHE
======================= */

class Notifiche {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> syncAll(List<Pratica> pratiche) async {
    await _plugin.cancelAll();

    for (final p in pratiche) {
      if (p.scadenzaRisposta != null) {
        final when = p.scadenzaRisposta!;
        await _schedule(p, when, 1, 'Oggi scadenza risposta');
      }
      if (p.scadenzaPassoSuccessivo != null) {
        final when = p.scadenzaPassoSuccessivo!;
        await _schedule(p, when, 2, 'Oggi passo successivo');
      }
    }
  }

  static Future<void> _schedule(Pratica p, DateTime when, int kind, String msg) async {
    final now = DateTime.now();
    if (when.isBefore(now.add(const Duration(seconds: 5)))) return;

    final id = ((p.id.hashCode & 0x7fffffff) % 100000) * 10 + kind;

    await _plugin.zonedSchedule(
      id,
      'Fixly • ${p.azienda.label}',
      '$msg • ${p.tipoProblema.label}',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fixly_scadenze',
          'Scadenze Fixly',
          channelDescription: 'Promemoria scadenze pratiche',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}