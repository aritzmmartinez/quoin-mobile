import 'package:flutter/material.dart';

import 'package:quoin/src/core/l10n/gen/app_localizations.dart';
import 'package:quoin/src/core/theme/quoin_colors.dart';
import 'package:quoin/src/core/theme/quoin_icons.dart';
import 'package:quoin/src/core/theme/quoin_tokens.dart';
import 'package:quoin/src/core/theme/quoin_type.dart';
import 'package:quoin/src/ui/atoms/quoin_icon.dart';

class QuoinTextField extends StatelessWidget {
  const QuoinTextField({
    super.key,
    required String this.label,
    this.hint,
    this.help,
    this.error,
    this.unit,
    this.maxLines = 1,
    this.enabled = true,
    this.controller,
    this.onChanged,
    this.keyboardType,
  }) : _search = false;

  const QuoinTextField.search({
    super.key,
    required String this.label,
    this.enabled = true,
    this.controller,
    this.onChanged,
  }) : hint = null,
       help = null,
       error = null,
       unit = null,
       maxLines = 1,
       keyboardType = TextInputType.text,
       _search = true;

  final String? label;

  final String? hint;
  final String? help;
  final String? error;
  final String? unit;
  final int maxLines;
  final bool enabled;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool _search;

  @override
  Widget build(BuildContext context) {
    final c = QuoinColors.of(context);
    final type = QuoinType.of(context);
    final theme = Theme.of(context).inputDecorationTheme;
    final text = unit != null ? type.field.mono : type.field;
    final iconSize = MediaQuery.textScalerOf(context)
        .scale(type.field.fontSize!);
    OutlineInputBorder? shaped(InputBorder? border) => maxLines == 1
        ? null
        : (border as OutlineInputBorder?)?.copyWith(
            borderRadius: BorderRadius.circular(QuoinRadius.card),
          );

    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      minLines: maxLines == 1 ? null : 3,
      keyboardType: keyboardType,
      textInputAction: _search ? TextInputAction.search : null,
      style: text.copyWith(color: c.text),
      decoration: InputDecoration(
        hintText: _search ? AppLocalizations.of(context).searchHint : hint,
        hintStyle: text.copyWith(color: c.faint),
        helperText: help,
        errorText: error,
        prefixIcon: _search
            ? Center(
                widthFactor: 1,
                child: QuoinIcon(
                  QuoinIcons.search,
                  size: iconSize,
                  color: c.muted,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: unit == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Center(
                  widthFactor: 1,
                  child: Text(unit!, style: text.copyWith(color: c.muted)),
                ),
              ),
        border: shaped(theme.border),
        enabledBorder: shaped(theme.enabledBorder),
        focusedBorder: shaped(theme.focusedBorder),
        disabledBorder: shaped(theme.disabledBorder),
        errorBorder: shaped(theme.errorBorder),
        focusedErrorBorder: shaped(theme.focusedErrorBorder),
      ),
    );
    if (_search) return Semantics(label: label, child: field);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(label!, style: type.secondary.copyWith(color: c.muted)),
          ),
        ),
        Semantics(label: label, child: field),
      ],
    );
  }
}
