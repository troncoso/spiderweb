import 'package:flutter/material.dart';
import 'package:spiderweb/widgets/margins.dart';

class DialogButton extends ElevatedButton {
  DialogButton(String label, VoidCallback? onPressed, { Key? key }) :
        super(child: Text(label), onPressed: onPressed, key: key);
}

typedef SingleInputCallback = void Function(String inputValue);

showSingleInputDialog(BuildContext context, String inputLabel, SingleInputCallback callback, { String? startingValue }) async {
  await showDialog<SimpleDialog>(context: context, builder: (context) {
    return SimpleDialog(
        children: [
          Container(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (context) {
                  var inputController = TextEditingController(text: startingValue);
                  return Column(
                      children: [
                        TextFormField(
                          controller: inputController,
                          decoration: InputDecoration(labelText: inputLabel),
                        ),
                        const VerticalMargin(),
                        DialogButton('Save', () {
                          callback(inputController.text);
                        })
                      ]
                  );
                },
              )
          )
        ]
    );
  });
}