import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:provider/provider.dart';
import 'package:pub_client/pub_client.dart';
import 'package:tavern/src/pub_colors.dart';

class PlatformFilter extends StatelessWidget {
  final ValueChanged<FilterType> onSegmentChosen;
  final FilterType value;

  const PlatformFilter(
      {Key key, @required this.value, @required this.onSegmentChosen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: MaterialSegmentedControl<FilterType>(
            children: {
              FilterType.flutter: Text('Flutter'),
              FilterType.web: Text('Web'),
              FilterType.all: Text('All'),
            },
            selectionIndex: value,
            borderColor: Color.fromRGBO(71, 99, 132, 1),
            selectedColor: Theme.of(context).accentColor,
            unselectedColor:
                DynamicTheme.of(context).brightness == Brightness.light
                    ? Theme.of(context).canvasColor
                    : Provider.of<PubColors>(context).darkAccent,
            borderRadius: 5.0,
            onSegmentChosen: onSegmentChosen,
          ),
        ),
      ],
    );
  }
}
