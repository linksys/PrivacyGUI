import 'dart:async';

mixin StateStreamRegister {
  final List<StreamSubscription> _streamSubscriptions = [];
  late Stream _stream;
  set shareStream(Stream stream) => _stream = stream;

  register(StateStreamListener listener) {
    _streamSubscriptions.add(_stream.listen(listener.consume));
  }

  unregisterAll() {
    for (var element in _streamSubscriptions) {
      element.cancel();
    }
  }
}

mixin StateStreamListener {
  consume(event);
}