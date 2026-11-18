import 'package:flutter/material.dart';
import 'package:quoin_core/quoin_core.dart';

import 'package:quoin/src/core/error/failures.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/features/sync/domain/entities/pairing.dart';
import 'package:quoin/src/features/sync/domain/entities/sync_outcome.dart';
import 'package:quoin/src/features/sync/presentation/widgets/conflict_card.dart';
import 'package:quoin/src/features/sync/presentation/widgets/pc_row.dart';
import 'package:quoin/src/features/sync/presentation/widgets/pc_sheet.dart';
import 'package:quoin/src/features/sync/presentation/widgets/sync_detail_view.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/instrument_icon.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/allocation_bar.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/figure_block.dart';
import 'package:quoin/src/ui/molecules/group_header.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/molecules/movement_row.dart';
import 'package:quoin/src/ui/molecules/notice_row.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/organisms/quoin_segmented_pages.dart';
import 'package:quoin/src/ui/organisms/quoin_toast.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';
import 'package:quoin/src/ui/molecules/sale_row.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/molecules/stat_columns.dart';
import 'package:quoin/src/ui/molecules/stat_tile.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
import 'package:quoin/src/ui/organisms/quoin_dropdown.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

const _positions = [
  ('Índice Global Acc', 'IGA', '12.450,20 €', '+1,41 %', 1),
  ('Bonos Euro Corto', 'BEC', '6120,00 €', '-0,12 %', -1),
  ('Oro Físico', 'ORO', '3240,55 €', '+0,37 %', 1),
  ('Mercados Emergentes', 'MEM', '2980,10 €', '-1,08 %', -1),
  ('Tecnología Norteamérica', 'TNA', '2310,45 €', '0,0 %', 0),
  ('Cripto Uno', 'CR1', '1890,00 €', '+6,78 %', 1),
  ('Inmobiliario Europa', 'INE', '1204,90 €', '-0,55 %', -1),
  ('Salud Mundial', 'SAM', '980,30 €', '+0,21 %', 1),
];

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  var _range = '1M';
  var _segment = 0;
  var _filter = 'Todas';
  var _placement = QuoinBarActionPlacement.trailing;
  var _tab = 0;
  final _choices = <String, Resolution>{};

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(
        top: QuoinSpace.section,
        bottom: QuoinSpace.row,
      ),
      child: Text(
        s.toUpperCase(),
        style: type.section.copyWith(color: c.muted),
      ),
    );

    return Scaffold(
      body: QuoinPage.list(
        title: 'Galería de componentes',
        children: [
          label('Cifra grande'),
          const DisplayFigure('24.380,50 €'),
          const SizedBox(height: QuoinSpace.xs),
          Text(
            '+349,15 € (+1,41 %)',
            style: type.secondary.mono.copyWith(color: c.positive),
          ),
          label('Botones'),
          Wrap(
            spacing: QuoinSpace.s,
            runSpacing: QuoinSpace.s,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Principal')),
              OutlinedButton(onPressed: () {}, child: const Text('Secundario')),
              TextButton(onPressed: () {}, child: const Text('Texto')),
              const FilledButton(onPressed: null, child: Text('Desactivado')),
            ],
          ),
          label('Chips de rango (código)'),
          Wrap(
            spacing: QuoinSpace.s,
            children: [
              for (final r in ['1D', '1S', '1M', '1A', 'Todo'])
                QuoinChip.code(
                  label: r,
                  selected: r == _range,
                  onTap: () => setState(() => _range = r),
                ),
            ],
          ),
          label('Chips de filtro'),
          Wrap(
            spacing: QuoinSpace.s,
            runSpacing: QuoinSpace.s,
            children: [
              for (final k in ['Todas', 'Fondo de renta variable', 'Cripto'])
                QuoinChip.text(
                  label: k,
                  selected: k == _filter,
                  onTap: () => setState(() => _filter = k),
                ),
            ],
          ),
          label('Segmentado'),
          SizedBox(
            height: 280,
            child: QuoinSegmentedPages<int>(
              padding: EdgeInsets.zero,
              segments: const [(0, 'Ventas'), (1, 'Fiscal'), (2, 'Resumen')],
              pages: const [
                [
                  Wrap(
                    spacing: QuoinSpace.section,
                    runSpacing: QuoinSpace.card,
                    children: [
                      FigureBlock(
                        label: 'Resultado',
                        value: '+1.234,56 €',
                        sign: 1,
                      ),
                      FigureBlock(label: 'Vendido', value: '12.345,00 €'),
                    ],
                  ),
                ],
                [
                  Wrap(
                    spacing: QuoinSpace.section,
                    runSpacing: QuoinSpace.card,
                    children: [
                      FigureBlock(label: 'Base', value: '8.765,43 €'),
                      FigureBlock(label: 'Cuota', value: '1.753,09 €'),
                    ],
                  ),
                ],
                [
                  Wrap(
                    spacing: QuoinSpace.section,
                    runSpacing: QuoinSpace.card,
                    children: [
                      FigureBlock(label: 'Coste', value: '10.000,00 €'),
                      FigureBlock(label: 'Valor', value: '11.234,56 €'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          label('Avisos'),
          Wrap(
            spacing: QuoinSpace.s,
            runSpacing: QuoinSpace.s,
            children: [
              for (final (name, show) in <(String, VoidCallback)>[
                (
                  'Éxito',
                  () => showQuoinToast(
                    context,
                    tone: QuoinToastTone.positive,
                    title: 'Cambios guardados',
                  ),
                ),
                (
                  'Error',
                  () => showQuoinToast(
                    context,
                    tone: QuoinToastTone.negative,
                    title: 'No se ha podido sincronizar',
                    body: 'El PC de ejemplo no responde en la red.',
                  ),
                ),
                (
                  'Aviso',
                  () => showQuoinToast(
                    context,
                    tone: QuoinToastTone.neutral,
                    title: 'Precios pendientes',
                    body: 'Se completarán en la próxima sincronización.',
                  ),
                ),
                (
                  'Con acción',
                  () => showQuoinToast(
                    context,
                    tone: QuoinToastTone.neutral,
                    title: 'Tu PC tiene cambios por revisar',
                    action: (label: 'Revisar', onPressed: () {}),
                  ),
                ),
              ])
                OutlinedButton(onPressed: show, child: Text(name)),
            ],
          ),
          label('Campos de texto'),
          const QuoinTextField(label: 'Nombre', hint: 'Plan 2027'),
          const SizedBox(height: QuoinSpace.card),
          const QuoinTextField(
            label: 'Aportación mensual',
            hint: '500',
            unit: '€',
            help: 'Lo que aportas cada mes.',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: QuoinSpace.card),
          const QuoinTextField.search(label: 'Buscar por ISIN o nombre'),
          const SizedBox(height: QuoinSpace.card),
          const QuoinTextField(
            label: 'Horizonte',
            hint: '10',
            unit: 'años',
            error: 'Entre 1 y 50 años.',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: QuoinSpace.card),
          const QuoinTextField(label: 'Moneda', hint: 'EUR', enabled: false),
          const SizedBox(height: QuoinSpace.card),
          const QuoinTextField(
            label: 'Nota',
            hint: 'Por qué cambia el plan',
            maxLines: 4,
          ),
          label('Barra inferior'),
          QuoinSegmented<QuoinBarActionPlacement>(
            segments: const [
              (QuoinBarActionPlacement.trailing, 'Derecha'),
              (QuoinBarActionPlacement.leading, 'Izquierda'),
              (QuoinBarActionPlacement.above, 'Encima'),
              (QuoinBarActionPlacement.center, 'Centro'),
            ],
            selected: _placement,
            onChanged: (v) => setState(() => _placement = v),
          ),
          const SizedBox(height: QuoinSpace.m),
          _bar(context),
          label('Bloques de cifra'),
          const Wrap(
            spacing: QuoinSpace.section,
            runSpacing: QuoinSpace.card,
            children: [
              FigureBlock(label: 'Coste', value: '1.602,00 €'),
              FigureBlock(label: 'Resultado', value: '+45,00 €', sign: 1),
              FigureBlock(label: 'Pérdida', value: '−60,00 €', sign: -1),
              FigureBlock(
                label: 'Cuota',
                value: 'Sin escala',
                muted: true,
                caption: 'Nota al pie',
              ),
            ],
          ),
          label('Filas de venta'),
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const SaleRow(
                  name: 'Fondo de ejemplo',
                  when: '10 mar 2026 · 49 d',
                  result: '+78,20 €',
                  sign: 1,
                  returnPct: '+12,2 %',
                  details: [('Uds', '6'), ('Coste', '640,80 €')],
                ),
                const Divider(height: 1),
                SaleRow(
                  name: 'Acción de ejemplo',
                  when: '20 mar 2025',
                  result: '−150,00 €',
                  sign: -1,
                  badge: 'Recompra',
                  notes: const ['Se recompraron 4 de las 10 uds vendidas.'],
                  details: const [('Uds', '10'), ('Coste', '1000,00 €')],
                  more: [
                    Text(
                      '10 uds del 10 ene 2025 a 100,00 €',
                      style: type.secondary.mono.copyWith(color: c.body),
                    ),
                  ],
                ),
              ],
            ),
          ),
          label('Filas de movimiento'),
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MovementRow(
                  type: 'Compra',
                  subject: 'Fondo de ejemplo',
                  date: '12 ene 2026',
                  amount: '−1001,00 €',
                  onTap: () {},
                ),
                const Divider(height: 1),
                const MovementRow(
                  type: 'Compra',
                  subject: 'Acción en dólares',
                  date: '2 may 2025',
                  amount: '−201,00 €',
                  marks: ['USD → €'],
                ),
                const Divider(height: 1),
                const MovementRow(
                  type: 'Recompensa',
                  subject: 'Moneda de ejemplo',
                  date: '1 oct 2025',
                  amount: '+15,00 €',
                ),
                const Divider(height: 1),
                const MovementRow(
                  type: 'Venta',
                  subject: 'Acción sin tipo',
                  date: '3 nov 2025',
                  amount: '—',
                  marks: ['sin tipo'],
                ),
              ],
            ),
          ),
          label('Tarjeta'),
          QuoinCard(
            onTap: () {},
            child: Row(
              spacing: QuoinSpace.m,
              children: [
                const IconTile(icon: QuoinIcons.projection),
                Expanded(
                  child: Text('Tarjeta con mosaico', style: type.rowStrong),
                ),
              ],
            ),
          ),
          label('Filas de ajustes'),
          SettingsSection(
            title: 'Sección',
            rows: [
              SettingsRow(
                icon: QuoinIcons.language,
                label: 'Enlace',
                onTap: () {},
              ),
              SettingsRow(
                icon: QuoinIcons.theme,
                label: 'Con valor',
                value: 'Sistema',
                onTap: () {},
              ),
              const SettingsRow(
                icon: QuoinIcons.version,
                label: 'Cifra',
                value: '0.1.0',
                valueIsFigure: true,
              ),
              const SettingsRow(
                icon: QuoinIcons.currency,
                label: 'Desactivada',
                comingSoon: true,
              ),
            ],
          ),
          label('Estado vacío'),
          QuoinCard(
            child: EmptyState(
              icon: QuoinIcons.portfolio,
              title: 'Aún no hay nada aquí',
              body: 'Una explicación corta de qué hacer.',
              actionLabel: 'Acción',
              onAction: () {},
            ),
          ),
          label('Estado de error'),
          const QuoinCard(
            child: EmptyState(
              icon: QuoinIcons.alert,
              title: 'No se ha podido leer',
              body: 'Qué ha pasado y qué hacer.',
              negative: true,
            ),
          ),
          label('Desplegables'),
          Wrap(
            spacing: QuoinSpace.s,
            children: [
              QuoinDropdown<String>(
                label: 'Categoría',
                value: _filter,
                options: [
                  for (final k in [
                    'Todas',
                    'Fondo de renta variable',
                    'Cripto',
                  ])
                    (value: k, label: k),
                ],
                onChanged: (k) => setState(() => _filter = k),
              ),
              QuoinDropdown<int>(
                label: 'Orden',
                value: _segment,
                options: const [
                  (value: 0, label: 'Por valor'),
                  (value: 1, label: 'Por plusvalía'),
                  (value: 2, label: 'Alfabético'),
                ],
                onChanged: (v) => setState(() => _segment = v),
              ),
            ],
          ),
          ..._sync(context, label),
          label('Badge de plusvalía'),
          const Wrap(
            spacing: QuoinSpace.s,
            runSpacing: QuoinSpace.s,
            children: [
              GainBadge(text: '+349,15 € (+1,4 %)', sign: 1),
              GainBadge(text: '−80,00 € (−13,8 %)', sign: -1),
              GainBadge(text: '0,00 €', sign: 0),
            ],
          ),
          label('Distribución'),
          const AllocationBar(
            segments: [
              AllocationSegment(
                label: 'Fondo de renta variable',
                fraction: 0.46,
                percent: '46 %',
              ),
              AllocationSegment(
                label: 'Fondo de bonos',
                fraction: 0.3,
                percent: '30 %',
              ),
              AllocationSegment(
                label: 'Acción',
                fraction: 0.17,
                percent: '17 %',
              ),
              AllocationSegment(
                label: 'Cripto',
                fraction: 0.05,
                percent: '5 %',
              ),
              AllocationSegment(
                label: 'Sin clasificar',
                fraction: 0.02,
                percent: '2 %',
                unclassified: true,
              ),
            ],
          ),
          label('Aviso'),
          NoticeRow(
            text: '2 posiciones sin precio',
            action: 'Revisar',
            onTap: () {},
          ),
          label('Cifras'),
          Row(
            spacing: QuoinSpace.row,
            children: [
              Expanded(
                child: StatTile(
                  label: 'Realizado 2026',
                  value: '+399,39 €',
                  sign: 1,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: StatTile(
                  label: 'Impuesto estimado 2026',
                  value: '75,89 €',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: QuoinSpace.m),
          const StatColumns(
            stats: [
              (label: 'Valor', value: '15.918,72 €', sign: 0),
              (label: 'Coste', value: '13.806,84 €', sign: 0),
              (label: 'Resultado', value: '+15,3 %', sign: 1),
            ],
          ),
          label('Iconos de instrumento'),
          const Wrap(
            spacing: QuoinSpace.m,
            runSpacing: QuoinSpace.m,
            children: [
              InstrumentIcon.tile(QuoinIcons.equityFund),
              InstrumentIcon.tile(QuoinIcons.bondFund),
              InstrumentIcon.tile(QuoinIcons.commodityFund),
              InstrumentIcon.tile(QuoinIcons.crypto),
              InstrumentIcon.tile(QuoinIcons.fund),
              InstrumentIcon.circle('E'),
              InstrumentIcon.coin(QuoinIcons.crypto),
            ],
          ),
          label('Posiciones (para ver el cristal de la barra)'),
          PositionList(
            children: [
              const GroupHeader(
                label: 'Fondo de renta variable',
                total: '11.555,75 €',
              ),
              const PositionRow(
                leading: InstrumentIcon.tile(QuoinIcons.fund),
                name: 'Sin Precio Ejemplo',
                detail: '12 participaciones',
                value: 'Sin precio',
                valueIsFigure: false,
                changePrefix: 'coste',
                change: '720,00 €',
              ),
              for (var i = 0; i < 32; i++)
                _row(context, _positions[i % _positions.length]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context) {
    final c = QuoinColors.of(context);
    // Stripes behind the preview so the glass has something to bend.
    return ClipRRect(
      borderRadius: BorderRadius.circular(QuoinRadius.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.dn1, c.dn3, c.dn5, c.dn2],
            stops: const [0, 0.35, 0.7, 1],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: QuoinSpace.section),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: QuoinBottomBar(
              items: const [
                QuoinBarItem(icon: QuoinIcons.home, label: 'Inicio'),
                QuoinBarItem(icon: QuoinIcons.portfolio, label: 'Cartera'),
                QuoinBarItem(icon: QuoinIcons.analysis, label: 'Análisis'),
                QuoinBarItem(icon: QuoinIcons.settings, label: 'Ajustes'),
              ],
              currentIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
              addIcon: QuoinIcons.add,
              addLabel: 'Añadir',
              onAdd: () {},
              placement: _placement,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sync(BuildContext context, Widget Function(String) label) {
    SettingsRow pc(
      Pairing pairing, {
      Failure? failure,
      LastSync? last,
      String? twin,
      bool running = false,
      bool searching = false,
    }) => pcRow(
      context,
      pairing: pairing,
      twin: twin,
      running: running,
      searching: searching,
      failure: failure,
      last: last,
      onTap: () => showPcSheet(
        context,
        pc: pairing,
        failure: pairing.shared ? SharedIdentityFailure(twin ?? '') : failure,
        last: last,
        onCheckAgain: () {},
        onSearch: () {},
        onRescan: () {},
        onPairAgain: () {},
        onUnpair: () {},
      ),
    );

    return [
      label('Sincronización: PCs'),
      SettingsSection(
        title: 'Sincronización',
        rows: [
          pc(_syncedPc, last: _lastSync),
          pc(_pc('Portátil'), running: true),
          pc(_pc('Torre'), searching: true),
          pc(_pc('Oficina'), failure: const PcUnreachableFailure()),
          pc(_pc('Sobremesa'), failure: const CertificateMismatchFailure()),
          pc(_pc('Copia de Sobremesa', shared: true), twin: 'Sobremesa'),
          pc(_pc('Nuevo')),
        ],
      ),
      label('Sincronización: detalle'),
      ...syncDetailSections(
        context,
        toPhone: _lastSync.toPhone,
        toPc: _lastSync.toPc,
      ),
      label('Sincronización: al día'),
      ...syncDetailSections(
        context,
        toPhone: const SyncDetail(),
        toPc: const SyncDetail(),
      ),
      label('Sincronización: conflictos'),
      for (final conflict in _conflicts) ...[
        ConflictCard(
          conflict: conflict,
          names: const {'XX00EJEMPLO1': 'Fondo de ejemplo'},
          choice: _choices[conflictKey(conflict)],
          onChanged: (choice) =>
              setState(() => _choices[conflictKey(conflict)] = choice),
        ),
        const SizedBox(height: QuoinSpace.m),
      ],
    ];
  }
}

Pairing _pc(String name, {bool shared = false, DateTime? lastSyncAt}) =>
    Pairing(
      endpoint: SyncEndpoint(
        host: '192.0.2.10',
        port: 4443,
        sha256: name.hashCode.toRadixString(16).padLeft(64, '0'),
      ),
      token: 'ejemplo',
      pcName: name,
      pairedAt: DateTime.utc(2026, 1, 5),
      lastSyncAt: lastSyncAt,
      shared: shared,
    );

final _syncedPc = _pc('Estudio', lastSyncAt: DateTime.utc(2026, 3, 10, 9, 41));

final _lastSync = LastSync(
  at: DateTime.utc(2026, 3, 10, 9, 41),
  toPhone: SyncDetail(
    ledger: const {'BUY': 3, 'DIVIDEND': 1},
    newInstruments: Cut.of(const ['Fondo de ejemplo', 'Acción de ejemplo']),
    changedInstruments: Cut.of(const [
      InstrumentChange('Bono de ejemplo', [
        DetailField.quoteSymbol,
        DetailField.ter,
      ]),
    ]),
    resolved: Cut.of(const [
      ResolvedConflict(
        kind: ResolvedKind.instrument,
        subject: 'Fondo de ejemplo',
        field: DetailField.exposure,
        resolution: Resolution.take,
      ),
    ]),
    setAside: Cut.of(const [
      SetAsideRow(
        ts: '2026-02-03T10:00:00.000Z',
        type: 'BUY',
        instrument: 'Acción de ejemplo',
        fields: ['quantity', 'price'],
      ),
    ]),
  ),
  toPc: SyncDetail(
    ledger: const {'SELL': 1},
    newTargets: Cut.of(const ['Plan de ejemplo']),
  ),
);

const _conflicts = <Conflict>[
  FieldConflict(
    entity: 'instrument',
    key: 'XX00EJEMPLO1',
    field: 'quoteSymbol',
    local: 'EJM.DE',
    incoming: 'EJM.AS',
  ),
  FieldConflict(
    entity: 'settings',
    key: 'settings',
    field: 'residence',
    local: 'bizkaia',
    incoming: 'gipuzkoa',
  ),
  TargetDayConflict(day: '2026-03-01', local: 'a', incoming: 'b'),
  HoldingsConflict('XX00EJEMPLO1'),
];

PositionRow _row(
  BuildContext context,
  (String, String, String, String, int) position,
) {
  final (name, ticker, value, change, sign) = position;
  final c = QuoinColors.of(context);
  return PositionRow(
    leading: ticker == 'CR1'
        ? const InstrumentIcon.coin(QuoinIcons.crypto)
        : const InstrumentIcon.tile(QuoinIcons.equityFund),
    name: name,
    detail: ticker,
    value: value,
    change: change,
    changeColor: switch (sign) {
      > 0 => c.positive,
      < 0 => c.negative,
      _ => c.muted,
    },
  );
}
