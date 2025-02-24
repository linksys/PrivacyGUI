import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

mixin PreservedStateMixin<T extends Equatable, R extends StatefulWidget>
    on State<R> {
  final Map<String, T> _preservedState = {};

  set preservedState(T? value) {
    setState(() {
      if (value == null) {
        _preservedState.remove('main');
        return;
      }
      _preservedState['main'] = value;
    });
  }

  T? get preservedState {
    return _preservedState['main'];
  }

  void setPreservedState(String key, T value) {
    setState(() {
      _preservedState[key] = value;
    });
  }

  T? getPreservedState(String key) {
    return _preservedState[key];
  }

  bool isStateChanged(T currentState, [String key = 'main']) {
    return _preservedState[key] != currentState;
  }
}
