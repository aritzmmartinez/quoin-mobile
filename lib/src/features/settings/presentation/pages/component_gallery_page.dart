import 'package:flutter/material.dart';

import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/display_figure.dart';
import 'package:quoin/src/ui/atoms/quoin_card.dart';
import 'package:quoin/src/ui/atoms/quoin_chip.dart';
import 'package:quoin/src/ui/molecules/empty_state.dart';
import 'package:quoin/src/ui/molecules/icon_tile.dart';
import 'package:quoin/src/ui/molecules/quoin_segmented.dart';
import 'package:quoin/src/ui/molecules/quoin_text_field.dart';
import 'package:quoin/src/ui/molecules/settings_row.dart';
import 'package:quoin/src/ui/organisms/settings_section.dart';
import 'package:quoin/src/ui/templates/quoin_page.dart';

const _positions = [
  ('Índice Global Acc', 'IGA', '12.450,20 €', '+1,41 %', true),
  ('Bonos Euro Corto', 'BEC', '6.120,00 €', '-0,12 %', false),
  ('Oro Físico', 'ORO', '3.240,55 €', '+0,37 %', true),
  ('Mercados Emergentes', 'MEM', '2.980,10 €', '-1,08 %', false),
  ('Tecnología Norteamérica', 'TNA', '2.310,45 €', '+2,64 %', true),
  ('Cripto Uno', 'CR1', '1.890,00 €', '+6,78 %', true),
  ('Inmobiliario Europa', 'INE', '1.204,90 €', '-0,55 %', false),
  ('Salud Mundial', 'SAM', '980,30 €', '+0,21 %', true),
];

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  var _range = '1M';
  var _segment = 0;

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
          label('Chips de rango'),
          Wrap(
            spacing: 8,
            children: [
              for (final r in ['1D', '1S', '1M', '1A', 'Todo'])
                QuoinChip(
                  label: r,
                  selected: r == _range,
                  onTap: () => setState(() => _range = r),
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
          label('Posiciones (para ver el cristal de la barra)'),
          QuoinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < 32; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _PositionRow(_positions[i % _positions.length]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow(this.position);

  final (String, String, String, String, bool) position;

  @override
  Widget build(BuildContext context) {
    final (name, ticker, value, change, up) = position;
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Row(
            spacing: 12,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: c.accent.withValues(alpha: 0.15),
                // A fixed circle: the initial shrinks rather than overflow it.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name[0],
                    style: type.row.mono.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(name, style: type.row),
                    Text(
                      ticker,
                      style: type.secondary.mono.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              // Figures don't wrap: past 55 % of the row (a large system font)
              // they shrink to fit instead.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.55),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 4,
                    children: [
                      Text(value, style: type.row.mono.copyWith(color: c.text)),
                      Text(
                        change,
                        style: type.secondary.mono.copyWith(
                          color: up ? c.positive : c.negative,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
