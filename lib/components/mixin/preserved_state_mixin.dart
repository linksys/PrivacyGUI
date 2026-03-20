import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// class FormStateRegistry {
//   final Map<String, WeakReference<PreservedStateMixin2>> data;

//   FormStateRegistry() : data = {};

//   void register(String key, PreservedStateMixin2 value) {
//     data[key] = WeakReference(value);
//   }

//   void unregister(String key) {
//     data.remove(key);
//   }
// }

// class FormStateNotifier extends InheritedWidget {
//   const FormStateNotifier({
//     Key? key,
//     required this.registry,
//     required Widget child,
//   }) : super(
//           key: key,
//           child: child,
//         );

//   final FormStateRegistry registry;

//   void register(String key, PreservedStateMixin2 value) {
//     registry.register(key, value);
//   }

//   void unregister(String key) {
//     registry.unregister(key);
//   }

//   bool isDirty(String key) {

//     final value = registry.data[key]?.target;
//     if (value == null) {
//       return false;
//     }
//     return value.isDirty();
//   }

//   static FormStateNotifier? maybeOf(BuildContext context) {
//     final widget =
//         context.dependOnInheritedWidgetOfExactType<FormStateNotifier>();
//     return widget;
//   }

//   @override
//   bool updateShouldNotify(covariant FormStateNotifier oldWidget) {
//     return registry != oldWidget.registry;
//   }
// }

// mixin PreservedStateMixin2<T extends Equatable, R extends StatefulWidget>
//     on State<R> {
//   final Map<String, T> _preservedState = {};
//   T getCurrentState();

//   set preservedState(T? value) {
//     setState(() {
//       if (value == null) {
//         _preservedState.remove('main');
//         return;
//       }
//       _preservedState['main'] = value;
//     });
//   }

//   T? get preservedState {
//     return _preservedState['main'];
//   }

//   void setPreservedState(String key, T value) {
//     setState(() {
//       _preservedState[key] = value;
//     });
//   }

//   T? getPreservedState(String key) {
//     return _preservedState[key];
//   }

//   bool isStateChanged(T currentState, [String key = 'main']) {
//     return _preservedState[key] != currentState;
//   }

//   bool isDirty() {
//     return isStateChanged(getCurrentState());
//   }
// }
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
