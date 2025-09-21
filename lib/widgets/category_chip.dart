import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatalogProvider>();
    final cats = const ['all','vegetables','fruits','grains','leafy'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(c == 'all' ? 'category_all'.tr() : c[0].toUpperCase() + c.substring(1)),
                selected: prov.category == c,
                onSelected: (_) => prov.category = c,
              ),
            ),
        ],
      ),
    );
  }
}
