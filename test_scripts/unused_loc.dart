import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser();
  parser.addFlag('remove',
      abbr: 'r',
      help: 'Remove unused keys from .arb files.',
      defaultsTo: false);

  final argResults = parser.parse(arguments);
  final shouldRemoveUnused = argResults['remove'] as bool;

  // en arb file
  final enArbFile = File('./lib/l10n/app_en.arb');
  final fileString = enArbFile.readAsStringSync();

  final Map<String, dynamic> enJson = jsonDecode(fileString);
  final stringKeyList =
      enJson.keys.where((e) => !e.startsWith('@') && e != 'appTitle').toList();
  // all dart files
  final dir = Directory('./lib');
  final allDartFiles = dir
      .listSync(recursive: true)
      .where((e) => e.path.endsWith('.dart'))
      .whereType<File>()
      .toList();

  final usedStringKeys = <String>{};

  // Regex pattern to match localization strings.
  final pattern = RegExp(r"loc\(context\)[\s]*[\n]*\.(\w+)");
  for (final file in allDartFiles) {
    final fileContent = file.readAsStringSync();
    final matches = pattern.allMatches(fileContent);

    for (final match in matches) {
      final stringKey = match.group(1);
      if (stringKey != null) {
        usedStringKeys.add(stringKey);
      }
    }
  }
  // Find unused keys
  final unusedKeys =
      stringKeyList.where((key) => !usedStringKeys.contains(key)).toList();

  print('Unused localization strings:');
  if (unusedKeys.isEmpty) {
    print('No unused localization strings found!');
  } else {
    for (final key in unusedKeys) {
      print('- $key');
    }
    print('Total Unused strings: ${unusedKeys.length}');
  }

  if (shouldRemoveUnused) {
    _removeUnusedKeys(unusedKeys, stringKeyList);
  }
}

Map<String, dynamic> _sort(Map<String, dynamic> arbJson) {
  final sortedArbJson = <String, dynamic>{};

  // Find and add @@locale first
  if (arbJson.containsKey('@@locale')) {
    sortedArbJson['@@locale'] = arbJson['@@locale'];
  }

  // Sort the remaining keys
  final sortedKeys = arbJson.keys.where((key) => key != '@@locale').toList()..sort();
  
  // Add the remaining sorted key without @
  final sortedKeysWithoutAt = <String>[];
  for (final key in sortedKeys) {
    if (!key.startsWith('@')) {
      sortedKeysWithoutAt.add(key);
    }
  }
  // Add the related @key
  for (final key in sortedKeysWithoutAt) {
    sortedArbJson[key] = arbJson[key];
    if (arbJson.containsKey('@$key')) {
      sortedArbJson['@$key'] = arbJson['@$key'];
    }
  }

  return sortedArbJson;
}

void _removeUnusedKeys(List<String> unusedKeys, List<String> stringKeyList) {
  // Handle all arb files
  final dir = Directory('./lib/l10n');
  final allArbFiles = dir
      .listSync(recursive: true)
      .where((e) => e.path.endsWith('.arb'))
      .whereType<File>()
      .toList();

  for (final file in allArbFiles) {
    final fileString = file.readAsStringSync();
    final Map<String, dynamic> arbJson = jsonDecode(fileString);

    // Remove unused keys from the JSON
    final removeUnusedKeysList =
        unusedKeys.where((element) => arbJson.containsKey(element)).toList();
    for (final key in removeUnusedKeysList) {
      print('Remove $key from ${file.path}');
      arbJson.remove(key);
      if (arbJson.containsKey('@$key')) {
        arbJson.remove('@$key');
      }
    }

    final sortedArbJson = _sort(arbJson);

    // Write the modified JSON back to the file
    final encoder = JsonEncoder.withIndent('  ');
    final newFileString = encoder.convert(sortedArbJson);
    file.writeAsStringSync(newFileString);
    print(
        'Removed ${removeUnusedKeysList.length} unused keys from ${file.path}');
  }
}
