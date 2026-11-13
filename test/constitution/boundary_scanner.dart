import 'package:analyzer/dart/ast/ast.dart';

import 'source_scan.dart';

/// Finds the dependencies that cross an architecture boundary set by
/// `constitution.md` Article I.
///
/// [sources] maps repo-relative paths (`lib/...`) to Dart source. Each
/// violation reads `<from> -> <to>`.
Set<String> findBoundaryViolations(Map<String, String> sources) {
  final violations = <String>{};
  sources.forEach((path, source) {
    final unit = parseDart(source);
    final targets = [
      for (final uri in directiveUris(unit)) _resolve(path, uri),
    ].whereType<String>();
    final names = namesIn(unit);
    if (_isPresentation(path, unit, names)) {
      // Constitution 1.2.
      for (final target in targets) {
        if (_isDataLayer(target)) violations.add('$path -> $target');
      }
      for (final provider in _dataLayerProviders) {
        if (names.contains(provider)) violations.add('$path -> $provider');
      }
    } else if (path.startsWith('lib/core/')) {
      // Constitution 1.3.
      for (final target in targets) {
        if (target.startsWith('lib/page/')) violations.add('$path -> $target');
      }
    }
  });
  return violations;
}

/// The data layer a presentation file stays away from (constitution 1.2).
bool _isDataLayer(String path) =>
    path == 'lib/core/jnap/router_repository.dart' ||
    path.startsWith('lib/core/jnap/command/') ||
    path.startsWith('lib/core/http/') ||
    path == 'lib/core/cloud/linksys_cloud_repository.dart' ||
    path == 'lib/core/cloud/linksys_device_cloud_service.dart';

const _dataLayerProviders = [
  'routerRepositoryProvider',
  'cloudRepositoryProvider',
  'deviceCloudServiceProvider',
];

/// Directories under `lib/page/` that hold application code (constitution 1.1).
const _applicationDirectories = {
  'providers',
  'service',
  'services',
  'data',
  'models',
  'model',
};

/// Classes a widget or its state extends.
const _uiSupertypes = {
  'StatelessWidget',
  'StatefulWidget',
  'ConsumerWidget',
  'ConsumerStatefulWidget',
  'State',
  'ConsumerState',
};

/// A presentation file is under `lib/page/` and either outside the
/// application directories or building UI wherever it sits (constitution 1.1).
bool _isPresentation(String path, CompilationUnit unit, Set<String> names) {
  if (!path.startsWith('lib/page/')) return false;
  final directories = path.split('/')..removeLast();
  return !directories.any(_applicationDirectories.contains) ||
      names.contains('WidgetRef') ||
      unit.declarations.whereType<ClassDeclaration>().any((declaration) =>
          _uiSupertypes
              .contains(declaration.extendsClause?.superclass.name2.lexeme));
}

const _packagePrefix = 'package:privacy_gui/';

/// The repo-relative path [uri] names when imported from [from], or null when
/// it is outside this package (`dart:`, another package).
String? _resolve(String from, String uri) {
  final List<String> segments;
  if (uri.startsWith(_packagePrefix)) {
    segments = ['lib', ...uri.substring(_packagePrefix.length).split('/')];
  } else if (uri.contains(':')) {
    return null;
  } else {
    segments = [...(from.split('/')..removeLast()), ...uri.split('/')];
  }
  final resolved = <String>[];
  for (final segment in segments) {
    if (segment == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else if (segment != '.') {
      resolved.add(segment);
    }
  }
  return resolved.join('/');
}
