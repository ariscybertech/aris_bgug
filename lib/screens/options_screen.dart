import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../data.dart';
import '../options.dart';
import 'gui_commons.dart';

final optionLine = (String label, String value, VoidCallback onTap) => pad(
      GestureDetector(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label + ': ', style: small_text),
            Text(value, style: small_text),
          ],
        ),
        onTap: onTap,
      ),
      12.0,
    );

class OptionsScreen extends StatefulWidget {
  @override
  State<OptionsScreen> createState() => _OptionsState();
}

class _OptionsState extends State<OptionsScreen> {
  Widget currentEditor;
  Options options;

  _OptionsState() {
    options = Data.options.clone();
  }

  @override
  Widget build(BuildContext context) {
    if (currentEditor != null) {
      return rootContainer(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          currentEditor,
          btn('Go back', () {
            setState(() => currentEditor = null);
            Flame.util.fullScreen();
          }),
        ],
      ));
    }

    final boolItemBuilder = (String title, bool value, void Function(bool) setter) => optionLine(title, '$value', () {
          setState(() => currentEditor = StatefulCheckbox(value: value, onChanged: setter));
        });
    final stringItemBuilder = (String title, String value, Validator validator, void Function(String) setter) => optionLine(title, value, () {
          setState(() => currentEditor = textField(title, validator, value, setter));
        });
    final intItemBuilder = (String title, int value, void Function(int) setter) {
      return stringItemBuilder(title, value.toString(), intValidator, (str) => setter(int.parse(str)));
    };
    final doubleItemBuilder = (String title, double value, void Function(double) setter) {
      return stringItemBuilder(title, value.toString(), doubleValidator, (str) => setter(double.parse(str)));
    };
    return rootContainer(
      Row(
        children: [
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pad(const Text('OpTiOnS', style: title), 20.0),
              btn('Save', () {
                Data.options = options;
                Data.save().then((a) {
                  Navigator.of(context).pop();
                });
              }),
              btn('Cancel', () {
                Navigator.of(context).pop();
              }),
              Container(
                padding: const EdgeInsets.fromLTRB(0.0, 24.0, 0.0, 0.0),
                child: btn('Reset Defaults', () {
                  Data.options = Options();
                  Data.save().then((a) {
                    Navigator.of(context).pop();
                  });
                }, style: small_text),
              ),
            ],
          )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: ListView(
                  children: [
                    doubleItemBuilder(
                      'Bullet Speed',
                      options.bulletSpeed,
                      (v) => options.bulletSpeed = v,
                    ),
                    intItemBuilder(
                      'Block Button Starting Cost',
                      options.buttonCost,
                      (v) => options.buttonCost = v,
                    ),
                    intItemBuilder(
                      'Block Button Inc Cost',
                      options.buttonIncCost,
                      (v) => options.buttonIncCost = v,
                    ),
                    intItemBuilder(
                      'Coins Awarded Per Block',
                      options.coinsAwardedPerBlock,
                      (v) => options.coinsAwardedPerBlock = v,
                    ),
                    doubleItemBuilder(
                      'Block Lifespan (seconds)',
                      options.blockLifespan,
                      (v) => options.blockLifespan = v,
                    ),
                    intItemBuilder(
                      'Max Hold Jump (millis)',
                      options.maxHoldJumpMillis,
                      (v) => options.maxHoldJumpMillis = v,
                    ),
                    doubleItemBuilder(
                      'Gravity Impulse',
                      options.gravityImpulse,
                      (v) => options.gravityImpulse = v,
                    ),
                    doubleItemBuilder(
                      'Jump Impulse',
                      options.jumpImpulse,
                      (v) => options.jumpImpulse = v,
                    ),
                    doubleItemBuilder(
                      'Dive Impulse',
                      options.diveImpulse,
                      (v) => options.diveImpulse = v,
                    ),
                    doubleItemBuilder(
                      'Jump Time Multiplier',
                      options.jumpTimeMultiplier,
                      (v) => options.jumpTimeMultiplier = v,
                    ),
                    intItemBuilder(
                      'Map Size (-1 for infinite)',
                      options.mapSize,
                      (v) => options.mapSize = v,
                    ),
                    boolItemBuilder(
                      'Has Guns',
                      options.hasGuns,
                      (v) => options.hasGuns = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
