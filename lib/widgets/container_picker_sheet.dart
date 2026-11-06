import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Kap seçim sonucu.
class ContainerChoice {
  const ContainerChoice({required this.container, this.remember = false});

  /// `null` ise kullanıcı "bilmiyorum" dedi.
  final ContainerType? container;

  /// "Bir daha sorma" işaretlendi mi?
  final bool remember;
}

/// İçecek eklerken hangi kaptan içildiğini soran hızlı seçim sayfası.
///
/// Tek dokunuşla seçip kapatacak şekilde tasarlandı; kullanıcı sayfayı
/// kaydırarak kapatırsa `null` döner ve kayıt eklenmez.
Future<ContainerChoice?> showContainerPicker(
  BuildContext context, {
  required String drinkLabel,
  required int ml,
  String? selectedId,
  bool askAgain = true,
}) {
  return showModalBottomSheet<ContainerChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _ContainerPickerSheet(
        drinkLabel: drinkLabel,
        ml: ml,
        selectedId: selectedId,
        askAgain: askAgain,
      );
    },
  );
}

class _ContainerPickerSheet extends StatefulWidget {
  const _ContainerPickerSheet({
    required this.drinkLabel,
    required this.ml,
    required this.selectedId,
    required this.askAgain,
  });

  final String drinkLabel;
  final int ml;
  final String? selectedId;
  final bool askAgain;

  @override
  State<_ContainerPickerSheet> createState() => _ContainerPickerSheetState();
}

class _ContainerPickerSheetState extends State<_ContainerPickerSheet> {
  late bool _remember = !widget.askAgain;

  void _pick(ContainerType? container) {
    Navigator.of(
      context,
    ).pop(ContainerChoice(container: container, remember: _remember));
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hangi kaptan içtin?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.drinkLabel} · ${widget.ml} ml',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.96,
            children: <Widget>[
              for (final ContainerType container in kContainerTypes)
                _ContainerTile(
                  container: container,
                  ml: widget.ml,
                  selected: container.id == widget.selectedId,
                  onTap: () => _pick(container),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF1F7FE),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              value: _remember,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              onChanged: (bool value) => setState(() => _remember = value),
              title: const Text(
                'Bir daha sorma',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              subtitle: const Text(
                'Son seçtiğim kabı otomatik kullan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _pick(null),
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text(
                'Bilmiyorum, boş bırak',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
          Text(
            'Ambalaj bilgisi, atık ve karbon ayak izi hesaplamasında kullanılır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContainerTile extends StatelessWidget {
  const _ContainerTile({
    required this.container,
    required this.ml,
    required this.selected,
    required this.onTap,
  });

  final ContainerType container;
  final int ml;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String wasteLabel = container.isReusable
        ? 'Yeniden kullanılır'
        : '${container.wasteFor(ml).round()} g atık';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? container.color.withValues(alpha: 0.14)
                : const Color(0xFFF7FAFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? container.color : const Color(0xFFE7EEF7),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: container.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(container.icon, color: container.color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                container.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                wasteLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: container.isReusable
                      ? AppColors.green
                      : AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
