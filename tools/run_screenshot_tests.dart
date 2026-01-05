// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:args/args.dart'; // Import the args package

// Custom log function to handle output redirection
void _log(String message, IOSink? sink, [bool both = false]) {
  if (both) {
    sink?.writeln(message);
    print(message);
  } else {
    if (sink != null) {
      sink.writeln(message);
    } else {
      print(message);
    }
  }
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('customize',
        abbr: 'c',
        help:
            'Enable customization of test items (languages, resolutions). If not set, default values are used.')
    ..addOption('languages',
        abbr: 'l',
        help: 'Comma-separated list of languages (e.g., en,zh). Requires -c.')
    ..addOption('resolutions',
        abbr: 's',
        help:
            'Comma-separated list of resolutions (e.g., 480,1280). Requires -c.')
    ..addOption('output',
        abbr: 'o',
        help: 'Path to an output file to write logs to instead of stdout.')
    ..addOption('filter',
        abbr: 'f', help: 'Filter test paths by key (e.g., "pnp").');

  ArgResults argResults = parser.parse(arguments);

  IOSink? outputSink;
  if (argResults['output'] != null) {
    final outputFile = File(argResults['output'] as String);
    outputSink = outputFile.openWrite(mode: FileMode.writeOnlyAppend);
    _log('Output will be written to: ${outputFile.path}',
        null); // Log to console about redirection
  }

  String? filterKey;
  if (argResults['filter'] != null) {
    filterKey = argResults['filter'] as String;
    _log('Filtering test paths by key: $filterKey', outputSink, true);
  }

  _log('Starting screenshot test runner...', outputSink, true);

  final projectRoot = Directory.current.path;
  final testDir = Directory(p.join(projectRoot, 'test', 'page'));

  try {
    final allTestFiles = await _findTestFiles(testDir, filterKey);
    if (allTestFiles.isEmpty) {
      _log('No screenshot test files found matching the pattern.', outputSink,
          true);
      return;
    }

    _log('Found ${allTestFiles.length} test files:', outputSink, true);
    for (int i = 0; i < allTestFiles.length; i++) {
      _log('${i + 1}. ${p.relative(allTestFiles[i].path, from: testDir.path)}',
          outputSink, true);
    }

    // skip prompt file selection if allTestFiles length is 1
    final skipPrompt = allTestFiles.length == 1;

    final selectedFiles = skipPrompt
        ? allTestFiles
        : _promptForFileSelection(allTestFiles, outputSink);
    if (selectedFiles.isEmpty) {
      _log('No test files selected. Exiting.', outputSink, true);
      return;
    }
    _log('Selected ${selectedFiles.length} files for execution.', outputSink,
        true);
    for (var file in selectedFiles) {
      _log('- ${p.relative(file.path, from: projectRoot)}', outputSink, true);
    }

    List<String> selectedLanguages;
    List<int> selectedResolutions;

    if (argResults['customize'] as bool) {
      // Customization is enabled
      if (argResults['languages'] != null) {
        final parts = argResults['languages']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final validLanguages = [
          'ar',
          'da',
          'de',
          'el',
          'en',
          'es',
          'es-AR',
          'fi',
          'fr',
          'fr-CA',
          'id',
          'it',
          'ja',
          'ko',
          'nb',
          'nl',
          'pl',
          'pt',
          'pt-PT',
          'ru',
          'sv',
          'th',
          'tr',
          'vi',
          'zh',
          'zh-TW',
        ]; // Example valid languages
        bool isValid = true;
        for (var part in parts) {
          if (!validLanguages.contains(part)) {
            _log(
                'Invalid language code provided via --languages: $part. Valid codes are: ${validLanguages.join(', ')}',
                outputSink);
            isValid = false;
            break;
          }
        }
        if (isValid) {
          selectedLanguages = parts;
          _log('Languages from arguments: ${selectedLanguages.join(', ')}',
              outputSink);
        } else {
          _log(
              'Falling back to interactive language selection due to invalid --languages argument.',
              outputSink);
          selectedLanguages = _promptForLanguages(outputSink);
        }
      } else {
        selectedLanguages = _promptForLanguages(outputSink);
      }

      if (selectedLanguages.isEmpty) {
        _log('No languages selected. Exiting.', outputSink);
        return;
      }

      if (argResults['resolutions'] != null) {
        final parts = argResults['resolutions']
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        bool isValid = true;
        List<int> parsedResolutions = [];
        for (var part in parts) {
          final resolution = int.tryParse(part);
          if (resolution == null || resolution <= 0) {
            _log(
                'Invalid resolution provided via --resolutions: $part. Please enter positive numbers.',
                outputSink);
            isValid = false;
            break;
          }
          parsedResolutions.add(resolution);
        }
        if (isValid) {
          selectedResolutions = parsedResolutions;
          _log('Resolutions from arguments: ${selectedResolutions.join(', ')}',
              outputSink);
        } else {
          _log(
              'Falling back to interactive resolution selection due to invalid --resolutions argument.',
              outputSink);
          selectedResolutions = _promptForResolutions(outputSink);
        }
      } else {
        selectedResolutions = _promptForResolutions(outputSink);
      }

      if (selectedResolutions.isEmpty) {
        _log('No resolutions selected. Exiting.', outputSink);
        return;
      }
    } else {
      // Customization is NOT enabled, use defaults
      _log(
          'Customization not enabled. Using default languages and resolutions.',
          outputSink);
      selectedLanguages = ['en'];
      selectedResolutions = [480, 1280];
    }

    _log('Selected languages: ${selectedLanguages.join(', ')}', outputSink);
    _log('Selected resolutions: ${selectedResolutions.join(', ')}', outputSink);

    await _runTests(selectedFiles, selectedLanguages, selectedResolutions,
        projectRoot, outputSink);
  } catch (e) {
    _log('An error occurred: $e', outputSink);
    exit(1);
  } finally {
    await outputSink?.close();
  }
}

/// Recursively finds files matching `localizations/.*_test.dart`.
Future<List<File>> _findTestFiles(Directory startDir, String? filterKey) async {
  final files = <File>[];
  final pattern = RegExp(r'localizations[\/].*_test\.dart$');

  if (!await startDir.exists()) {
    return files;
  }

  await for (final entity
      in startDir.list(recursive: true, followLinks: false)) {
    if (entity is File && pattern.hasMatch(entity.path)) {
      if (filterKey != null && filterKey.isNotEmpty) {
        if (entity.path.contains(filterKey)) {
          files.add(entity);
        }
      } else {
        files.add(entity);
      }
    }
  }
  return files;
}

/// Prompts the user to select test files from a list.
List<File> _promptForFileSelection(List<File> allTestFiles,
    [IOSink? outputSink]) {
  List<File> selectedFiles = [];
  while (selectedFiles.isEmpty) {
    stdout.write(
        'Enter numbers of files to run (e.g., 1,3,5), "all" for all, or "q" to quit: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == 'q') {
      return [];
    }

    if (input == 'all' || input == 'a') {
      selectedFiles = List.from(allTestFiles);
    } else {
      final parts = input
          ?.split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts == null || parts.isEmpty) {
        _log('Invalid input. Please try again.', outputSink);
        continue;
      }

      bool isValid = true;
      for (var part in parts) {
        final index = int.tryParse(part);
        if (index == null || index < 1 || index > allTestFiles.length) {
          _log(
              'Invalid file number: $part. Please enter numbers between 1 and ${allTestFiles.length}.',
              outputSink);
          isValid = false;
          break;
        }
        selectedFiles.add(allTestFiles[index - 1]);
      }

      if (!isValid) {
        selectedFiles.clear(); // Clear invalid selections
      }
    }
  }
  return selectedFiles;
}

/// Prompts the user to select languages for test execution.
List<String> _promptForLanguages([IOSink? outputSink]) {
  List<String> selectedLanguages = [];
  final validLanguages = [
    'ar',
    'da',
    'de',
    'el',
    'en',
    'es',
    'es-AR',
    'fi',
    'fr',
    'fr-CA',
    'id',
    'it',
    'ja',
    'ko',
    'nb',
    'nl',
    'pl',
    'pt',
    'pt-PT',
    'ru',
    'sv',
    'th',
    'tr',
    'vi',
    'zh',
    'zh-TW',
  ]; // Example valid languages
  while (selectedLanguages.isEmpty) {
    stdout.write(
        'Enter languages (e.g., en,zh), or press Enter for default (en): ');
    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      selectedLanguages.add('en'); // Default to English
    } else {
      final parts = input
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      bool isValid = true;
      for (var part in parts) {
        if (!validLanguages.contains(part)) {
          _log(
              'Invalid language code: $part. Valid codes are: ${validLanguages.join(', ')}',
              outputSink);
          isValid = false;
          break;
        }
        selectedLanguages.add(part);
      }

      if (!isValid) {
        selectedLanguages.clear(); // Clear invalid selections
      }
    }
  }
  return selectedLanguages;
}

/// Prompts the user to select resolutions for test execution.
List<int> _promptForResolutions([IOSink? outputSink]) {
  List<int> selectedResolutions = [];
  while (selectedResolutions.isEmpty) {
    stdout.write(
        'Enter resolutions (e.g., 480,1280), or press Enter for default (480,1280): ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      selectedResolutions.addAll([480, 1280]); // Default resolutions
    } else {
      final parts = input
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      bool isValid = true;
      for (var part in parts) {
        final resolution = int.tryParse(part);
        if (resolution == null || resolution <= 0) {
          _log('Invalid resolution: $part. Please enter positive numbers.',
              outputSink);
          isValid = false;
          break;
        }
        selectedResolutions.add(resolution);
      }

      if (!isValid) {
        selectedResolutions.clear(); // Clear invalid selections
      }
    }
  }
  return selectedResolutions;
}

class TestFailure {
  final String filePath;
  final String language;
  final int resolution;
  final String? testDescription;
  final String errorMessage;

  TestFailure({
    required this.filePath,
    required this.language,
    required this.resolution,
    this.testDescription,
    required this.errorMessage,
  });
}

/// Runs the selected tests with the given languages and resolutions using the project's snapshot generation script.
Future<void> _runTests(List<File> files, List<String> languages,
    List<int> resolutions, String projectRoot, IOSink? outputSink) async {
  _log('\n--- Starting Test Execution ---', outputSink);
  final List<TestFailure> failures = [];
  final String resolutionsString = resolutions.join(',');

  for (final file in files) {
    final relativeFilePath = p.relative(file.path, from: projectRoot);
    for (final lang in languages) {
      _log(
          '\nRunning test: $relativeFilePath, Language: $lang, Resolutions: $resolutionsString',
          outputSink);
      final process = await Process.run(
        'sh',
        [
          'run_generate_loc_snapshots.sh',
          '-c', 'true', // Always copy golden files
          '-f', relativeFilePath,
          '-l', lang,
          '-s', resolutionsString,
        ],
        workingDirectory: projectRoot,
      );

      if (outputSink != null) {
        outputSink.write(process.stdout);
      } else {
        stdout.write(process.stdout);
      }
      stderr.write(process.stderr);

      if (process.exitCode != 0) {
        _log(
            'Test failed for $relativeFilePath (Language: $lang, Resolutions: $resolutionsString)',
            outputSink);

        String rawOutput =
            process.stdout.toString() + process.stderr.toString();
        List<String> filteredErrorLines = rawOutput
            .split('\n')
            .where((line) => !line.contains('mkdir: ./snapshots/: File exists'))
            .toList();
        String fullErrorMessage = filteredErrorLines.join('\n');

        // Regex to find individual test failures and their variants
        final testFailureLineRegex = RegExp(
            r"^\d{2}:\d{2} \+\d+ -\d+: (.*) \(variant: Device(\d+).*\) \[E\]",
            multiLine: true);
        final matches = testFailureLineRegex.allMatches(rawOutput);

        if (matches.isNotEmpty) {
          for (final match in matches) {
            final testDescription = match.group(1)?.trim();
            final failedResolution = int.tryParse(match.group(2) ?? '');

            // Extract the actual exception message from the fullErrorMessage
            String actualExceptionMessage = "Unknown error";
            final exceptionStart = fullErrorMessage.indexOf(
                '══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════');
            if (exceptionStart != -1) {
              final exceptionEnd = fullErrorMessage.indexOf(
                  '════════════════════════════════════════════════════════════════════════════════════════════════════',
                  exceptionStart);
              if (exceptionEnd != -1) {
                actualExceptionMessage = fullErrorMessage.substring(
                    exceptionStart,
                    exceptionEnd +
                        '════════════════════════════════════════════════════════════════════════════════════════════════════'
                            .length);
              } else {
                actualExceptionMessage =
                    fullErrorMessage.substring(exceptionStart);
              }
            } else if (fullErrorMessage.isNotEmpty) {
              actualExceptionMessage = fullErrorMessage;
            }

            failures.add(TestFailure(
              filePath: relativeFilePath,
              language: lang,
              resolution: failedResolution ?? -1,
              testDescription: testDescription,
              errorMessage:
                  actualExceptionMessage, // Capture only the exception
            ));
          }
        } else {
          // Fallback if individual failure lines are not parsed, but process.exitCode != 0
          // This ensures that at least one failure is reported if process.exitCode is non-zero
          String actualExceptionMessage = "Unknown error";
          final exceptionStart = fullErrorMessage.indexOf(
              '══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════');
          if (exceptionStart != -1) {
            final exceptionEnd = fullErrorMessage.indexOf(
                '════════════════════════════════════════════════════════════════════════════════════════════════════',
                exceptionStart);
            if (exceptionEnd != -1) {
              actualExceptionMessage = fullErrorMessage.substring(
                  exceptionStart,
                  exceptionEnd +
                      '════════════════════════════════════════════════════════════════════════════════════════════════════'
                          .length);
            } else {
              actualExceptionMessage =
                  fullErrorMessage.substring(exceptionStart);
            }
          } else if (fullErrorMessage.isNotEmpty) {
            actualExceptionMessage = fullErrorMessage;
          }

          failures.add(TestFailure(
            filePath: relativeFilePath,
            language: lang,
            resolution: -1, // Unknown resolution
            testDescription: null, // Unknown description
            errorMessage: actualExceptionMessage,
          ));
        }
      } else {
        _log(
            'Test passed for $relativeFilePath (Language: $lang, Resolutions: $resolutionsString)',
            outputSink);
      }
    }
  }
  _log('\n--- Test Execution Finished ---', outputSink);

  if (failures.isNotEmpty) {
    _log('\n--- Summary of Failed Tests ---', outputSink);
    for (int i = 0; i < failures.length; i++) {
      final f = failures[i];
      _log('\n${i + 1}. File: ${f.filePath}', outputSink);
      _log(
          '   Language: ${f.language}, Resolution: ${f.resolution == -1 ? 'Unknown' : f.resolution}',
          outputSink);
      if (f.testDescription != null) {
        _log('   Test: ${f.testDescription}', outputSink);
      }
      _log('   Error: ${f.errorMessage}', outputSink);
    }
    _log('\n${failures.length} test(s) failed.', outputSink);
  } else {
    _log('\nAll tests passed successfully!', outputSink);
  }
}
