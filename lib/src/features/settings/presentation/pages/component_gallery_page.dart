import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/allocation_donut.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/gain_badge.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';
import 'package:quoin/src/ui/molecules/position_row.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/quoin_bottom_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    final type = QuoinType.of(context);
    final c = QuoinColors.of(context);
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: QuoinSpace.section, bottom: 10),
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
          const SizedBox(height: 4),
          Text(
            '+349,15 € (+1,41 %)',
            style: type.secondary.mono.copyWith(color: c.positive),
          ),
          label('Botones'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Principal')),
              OutlinedButton(onPressed: () {}, child: const Text('Secundario')),
              TextButton(onPressed: () {}, child: const Text('Texto')),
              const FilledButton(onPressed: null, child: Text('Desactivado')),
            ],
          ),
          label('Chips de rango (código)'),
          Wrap(
            spacing: 8,
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
            spacing: 8,
            runSpacing: 8,
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
          QuoinSegmented<int>(
            segments: const [(0, 'Ventas'), (1, 'Fiscal'), (2, 'Resumen')],
            selected: _segment,
            onChanged: (v) => setState(() => _segment = v),
          ),
          label('Campos de texto'),
          const QuoinTextField(label: 'Nombre', hint: 'Plan 2027'),
          const SizedBox(height: 16),
          const QuoinTextField(
            label: 'Aportación mensual',
            hint: '500',
            unit: '€',
            help: 'Lo que aportas cada mes.',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const QuoinTextField.search(label: 'Buscar por ISIN o nombre'),
          const SizedBox(height: 16),
          const QuoinTextField(
            label: 'Horizonte',
            hint: '10',
            unit: 'años',
            error: 'Entre 1 y 50 años.',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const QuoinTextField(label: 'Moneda', hint: 'EUR', enabled: false),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          // Stripes behind the preview so the glass has something to bend.
          ClipRRect(
            borderRadius: BorderRadius.circular(QuoinRadius.card),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.dn1, c.dn3, c.dn5, c.dn2],
                  stops: const [0, 0.35, 0.7, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: QuoinBottomBar(
                    items: const [
                      QuoinBarItem(icon: QuoinIcons.home, label: 'Inicio'),
                      QuoinBarItem(
                        icon: QuoinIcons.portfolio,
                        label: 'Cartera',
                      ),
                      QuoinBarItem(
                        icon: QuoinIcons.analysis,
                        label: 'Análisis',
                      ),
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
          ),
          label('Tarjeta'),
          QuoinCard(
            onTap: () {},
            child: Row(
              spacing: 14,
              children: [
                const IconTile(icon: QuoinIcons.projection),
                Expanded(
                  child: Text(
                    'Tarjeta con mosaico',
                    style: type.row.copyWith(fontWeight: FontWeight.w600),
                  ),
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
            child: SizedBox(
              height: 160,
              child: EmptyState(
                message: 'Aún no hay nada aquí',
                actionLabel: 'Acción',
                onAction: () {},
              ),
            ),
          ),
          label('Badge de plusvalía'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GainBadge(text: '+349,15 € (+1,4 %)', sign: 1),
              GainBadge(text: '−80,00 € (−13,8 %)', sign: -1),
              GainBadge(text: '0,00 €', sign: 0),
            ],
          ),
          label('Distribución'),
          const QuoinCard(
            child: AllocationDonut(
              slices: [
                DonutSlice(
                  label: 'Fondo de renta variable',
                  fraction: 0.46,
                  percent: '46,1 %',
                ),
                DonutSlice(
                  label: 'Fondo de bonos',
                  fraction: 0.3,
                  percent: '30,1 %',
                ),
                DonutSlice(label: 'Acción', fraction: 0.17, percent: '17,2 %'),
                DonutSlice(label: 'Cripto', fraction: 0.05, percent: '4,9 %'),
                DonutSlice(
                  label: 'Sin clasificar',
                  fraction: 0.02,
                  percent: '1,7 %',
                ),
              ],
            ),
          ),
          label('Posiciones (para ver el cristal de la barra)'),
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const PositionRow(
                  name: 'Sin Precio Ejemplo',
                  detail: '12',
                  value: '720,00 € de coste',
                  valueMuted: true,
                  change: Text('Sin precio'),
                ),
                for (var i = 0; i < 32; i++) ...[
                  const Divider(height: 1),
                  _row(_positions[i % _positions.length]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

PositionRow _row((String, String, String, String, int) position) {
  final (name, ticker, value, change, sign) = position;
  return PositionRow(
    name: name,
    detail: ticker,
    value: value,
    change: GainBadge(text: change, sign: sign),
  );
}
