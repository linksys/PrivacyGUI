// ignore_for_file: avoid_print

void main(List<String> args) {
  if (args.isEmpty) {
    print('No arguments provided.');
    return;
  }
  const startMarker = "══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════════════════";
  const endMarker = "end of failure";
  const stackMarker = ", this was the stack:";
  final text = args[0];
  int startIndex = text.indexOf(startMarker);
  startIndex = startIndex == -1 ? 0 : startIndex;
  int endIndex = text.indexOf(endMarker);
  endIndex = endIndex == -1 ? text.length : endIndex;
  int stackIndex = text.indexOf(stackMarker);
  stackIndex = stackIndex == -1 ? endIndex : stackIndex;
  String result = text.substring(startIndex, stackIndex);
  print(result);
}
