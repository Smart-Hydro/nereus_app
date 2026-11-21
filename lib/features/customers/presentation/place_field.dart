import 'package:flutter/material.dart';
import 'package:nereus_app/features/customers/domain/chile_places.dart';

class PlaceField extends StatelessWidget {
  const PlaceField({
    required this.commune,
    required this.focusNode,
    required this.region,
    required this.onPlace,
    super.key,
  });

  final TextEditingController commune;
  final FocusNode focusNode;
  final String? region;
  final ValueChanged<ChilePlace> onPlace;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<ChilePlace>(
      textEditingController: commune,
      focusNode: focusNode,
      displayStringForOption: (place) => place.commune,
      optionsBuilder: (value) => suggestPlaces(value.text, region: region),
      onSelected: onPlace,
      fieldViewBuilder: (context, controller, node, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: node,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Comuna',
            helperText:
                'Escribe y elige. Se completan la provincia y la región.',
          ),
          onSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final rows = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 480),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final place = rows[index];
                  return ListTile(
                    title: Text(place.commune),
                    subtitle: Text('${place.province} · ${place.region}'),
                    onTap: () => onSelected(place),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
