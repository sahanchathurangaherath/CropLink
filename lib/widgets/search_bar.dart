import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalog_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatalogProvider>();
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'search_hint'.tr(),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
      ),
      onChanged: (v) => prov.query = v,
    );
  }
}
