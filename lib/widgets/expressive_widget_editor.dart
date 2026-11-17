import 'package:flutter/material.dart';
import 'expressive_lesson_card.dart';

class ExpressiveWidgetEditor extends StatefulWidget {
  final Function(ExpressiveShapeVariant, ExpressiveTone?) onConfigChanged;

  const ExpressiveWidgetEditor({super.key, required this.onConfigChanged});

  @override
  State<ExpressiveWidgetEditor> createState() => _ExpressiveWidgetEditorState();
}

class _ExpressiveWidgetEditorState extends State<ExpressiveWidgetEditor> {
  ExpressiveShapeVariant _shape = ExpressiveShapeVariant.shape0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Widget Editor"),
        DropdownButton<ExpressiveShapeVariant>(
          value: _shape,
          onChanged: (value) {
            setState(() {
              _shape = value!;
              widget.onConfigChanged(_shape, null);
            });
          },
          items: ExpressiveShapeVariant.values.map((shape) {
            return DropdownMenuItem(
              value: shape,
              child: Text(shape.toString().split('.').last),
            );
          }).toList(),
        ),
      ],
    );
  }
}
