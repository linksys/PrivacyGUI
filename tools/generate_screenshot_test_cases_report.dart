import 'dart:io';
import 'package:path/path.dart' as p;

/// A data class to hold information about a single golden file.
class GoldenFileInfo {
  final String filename;
  final String description; // Optional, can be derived or added later

  GoldenFileInfo({required this.filename, this.description = ''});

  @override
  String toString() {
    return 'GoldenFileInfo(filename: $filename, description: $description)';
  }
}

/// A data class to hold information about a single test case.
class TestCaseInfo {
  final String id; // This will be the base Test ID (e.g., PNPS-STEP1_WIFI)
  final String description; // Main test description
  final String filePath;
  final List<GoldenFileInfo> goldenFiles; // List of all golden files for this test case

  TestCaseInfo({
    required this.id,
    required this.description,
    required this.filePath,
    required this.goldenFiles,
  });

  @override
  String toString() {
    return 'TestCaseInfo(id: $id, description: $description, filePath: $filePath, goldenFiles: $goldenFiles)';
  }
}

/// A script to automatically generate a Markdown report of test cases.
///
/// This script performs the following steps:
/// 1. Gets the Git remote URL to build web links.
/// 2. Recursively finds all `*_test.dart` files within `test/page/**/localizations/`.
/// 3. Parses each file to extract Test IDs and descriptions.
/// 4. Generates a `TEST_CASES.md` file with a table of all found test cases.
Future<void> main(List<String> arguments) async {
  final bool debugMode = arguments.contains('--debug');
  if (debugMode) {
    print('Debug mode enabled.');
  }
  print('Starting test case report generation...');

  final projectRoot = Directory.current.path;
  final testDir = Directory(p.join(projectRoot, 'test', 'page'));
  final outputFile = File(p.join(projectRoot, 'TEST_CASES.md'));

  try {
    // 1. Get Git remote URL
    final remoteUrl = await _getGitRemoteUrl(projectRoot);
    if (remoteUrl == null) {
      print('Error: Could not determine Git remote URL. Make sure this is a Git repository with a remote named "origin".');
      exit(1);
    }
    if (debugMode) {
      print('Found Git remote: $remoteUrl');
    }

    // 2. Find all relevant test files
    final testFiles = await _findTestFiles(testDir);
    if (testFiles.isEmpty) {
      print('No test files found matching the pattern.');
      return;
    }
    if (debugMode) {
      print('Found ${testFiles.length} test files.');
    }

        // 3. Parse files to extract test case info

        final allTestCases = <TestCaseInfo>[];

        for (final file in testFiles) {

          if (debugMode) {

            print('Parsing file: ${file.path}');

          }

          final testCases = await _parseTestFile(file, debugMode);

          allTestCases.addAll(testCases);

        }

        print('Extracted ${allTestCases.length} total test cases.');

    

        // Consolidate test cases by ID

        final consolidatedMap = <String, List<TestCaseInfo>>{};

        for (final testCase in allTestCases) {

          consolidatedMap.putIfAbsent(testCase.id, () => []).add(testCase);

        }

    

        // 4. Generate Markdown content

        final markdownContent =

            _generateMarkdown(consolidatedMap, remoteUrl, projectRoot);

    // 5. Write to output file
    await outputFile.writeAsString(markdownContent);
    print('Successfully generated report at ${outputFile.path}');

  } catch (e) {
    print('An error occurred: $e');
    exit(1);
  }
}

/// Finds the HTTPS URL for the 'origin' remote.
Future<String?> _getGitRemoteUrl(String projectRoot) async {
  final result = await Process.run('git', ['remote', '-v'], workingDirectory: projectRoot);
  if (result.exitCode != 0) {
    return null;
  }

  final lines = (result.stdout as String).split('\n');
  final originLine = lines.firstWhere(
    (line) => line.startsWith('origin') && line.contains('(fetch)'),
    orElse: () => '',
  );

  if (originLine.isEmpty) {
    return null;
  }

  // Extract URL part
  final parts = originLine.split(RegExp(r'\s+'));
  if (parts.length < 2) {
    return null;
  }
  var url = parts[1];

  // Convert SSH URL to HTTPS URL
  if (url.startsWith('git@')) {
    url = url.replaceFirst(':', '/').replaceFirst('git@', 'https://');
  }
  // Remove .git suffix if it exists
  if (url.endsWith('.git')) {
    url = url.substring(0, url.length - 4);
  }

  return url;
}

/// Recursively finds files matching `localizations/.*_test\.dart$`.
Future<List<File>> _findTestFiles(Directory startDir) async {
  final files = <File>[];
  final pattern = RegExp(r'localizations[\/].*_test\.dart$');

  if (!await startDir.exists()) {
    return files;
  }

  await for (final entity in startDir.list(recursive: true, followLinks: false)) {
    if (entity is File && pattern.hasMatch(entity.path)) {
      files.add(entity);
    }
  }
  return files;
}

/// Parses a single test file to extract all test cases and their associated golden files.
Future<List<TestCaseInfo>> _parseTestFile(File file, bool debugMode) async {
  final testCases = <TestCaseInfo>[];
  final content = await file.readAsString();

  final idRegex = RegExp(r'// Test ID: ([A-Z0-9-]+)');
  // Regex to find the test function call and its arguments block
  final testFunctionCallRegex = RegExp(r"(testLocalizations|testLocalizationsV2)\s*\((.*?)\);", multiLine: true, dotAll: true);
  final goldenFilenameParamRegex = RegExp(r"goldenFilename:\s*'([^']*)'");
  // Corrected to use lowercase 't' for testHelper
  final takeScreenshotRegex = RegExp(r"(\w+)\.takeScreenshot\(\s*(\w+),\s*'([^']*)'\s*\)", dotAll: true);

  final idMatches = idRegex.allMatches(content).toList();

  for (int i = 0; i < idMatches.length; i++) {
    final idMatch = idMatches[i];
    final baseId = idMatch.group(1)!.trim();

    final start = idMatch.end;
    final end = (i + 1 < idMatches.length) ? idMatches[i + 1].start : content.length;
    final testBlock = content.substring(start, end);

    String? mainDescription;
    final List<GoldenFileInfo> goldenFiles = [];

    // Find description from the first argument of the test function
    final descriptionMatch = testFunctionCallRegex.firstMatch(testBlock);
    if (descriptionMatch != null) {
      final argsBlock = descriptionMatch.group(2)!;
      final simpleDescMatch = RegExp(r"^\s*'([^']*)'").firstMatch(argsBlock);
      if (simpleDescMatch != null) {
        mainDescription = simpleDescMatch.group(1)!.trim();
      }
    }

    if (mainDescription == null) {
      if (debugMode) print('    No main description found for Test ID: $baseId in file ${file.path}, skipping test case.');
      continue; // Skip if no description found
    }

    // Find goldenFilename from the named parameter
    final goldenFilenameMatch = goldenFilenameParamRegex.firstMatch(testBlock);
    if (goldenFilenameMatch != null) {
      final goldenFilename = goldenFilenameMatch.group(1)!.trim();
      goldenFiles.add(GoldenFileInfo(filename: goldenFilename, description: 'Final State'));
    }

    // Find all takeScreenshot calls
    final takeScreenshotMatches = takeScreenshotRegex.allMatches(testBlock);
    for (final match in takeScreenshotMatches) {
      final screenshotFilename = match.group(3)!.trim();
      // Create a description from the filename, e.g., "ID_01_initial_state" -> "initial state"
      final descParts = screenshotFilename.split('_');
      final desc = descParts.length > 2 ? descParts.sublist(2).join(' ').replaceAll(RegExp(r'\.png$'), '') : 'Intermediate State';
      goldenFiles.add(GoldenFileInfo(filename: screenshotFilename, description: desc));
    }

    if (goldenFiles.isEmpty) {
      if (debugMode) print('    No golden files found for Test ID: $baseId in file ${file.path}, skipping test case.');
      continue;
    }

    if (debugMode) {
      print('  Found Test Case: $baseId');
      print('    Description: $mainDescription');
      print('    Golden Files collected:');
      for (var gf in goldenFiles) {
        print('      - ${gf.filename} (${gf.description})');
      }
    }

    testCases.add(TestCaseInfo(
      id: baseId,
      description: mainDescription,
      filePath: file.path,
      goldenFiles: goldenFiles,
    ));
  }

  return testCases;
}


/// Generates the final Markdown string from the collected test cases.


String _generateMarkdown(Map<String, List<TestCaseInfo>> consolidatedMap,


    String remoteUrl, String projectRoot) {


  final buffer = StringBuffer();





  buffer.writeln('# Test Case Documentation');


  buffer.writeln();


  buffer.writeln(


      'This document lists all screenshot test cases found in the project.');


  buffer.writeln(


      'It is auto-generated by `tools/generate_screenshot_test_cases_report.dart`.');


  buffer.writeln();





  // Sort by ID for consistent ordering


  final sortedIds = consolidatedMap.keys.toList()..sort();





  for (final id in sortedIds) {


    final testCasesForId = consolidatedMap[id]!;





    buffer.writeln('## `$id`');


    buffer.writeln();





    // Handle file paths


    final filePaths = testCasesForId.map((c) => c.filePath).toSet();


    if (filePaths.length == 1) {


      final relativePath =


          p.relative(filePaths.first, from: projectRoot).replaceAll('\\', '/');


      final fileUrl = '$remoteUrl/blob/main/$relativePath';


      final fileName = p.basename(relativePath);


      buffer.writeln('**File**: [`$fileName`]($fileUrl)');


      buffer.writeln();


    }





    for (final testCase in testCasesForId) {


      buffer.writeln('- **Description**: ${testCase.description}');





      if (filePaths.length > 1) {


        final relativePath =


            p.relative(testCase.filePath, from: projectRoot).replaceAll('\\', '/');


        final fileUrl = '$remoteUrl/blob/main/$relativePath';


        final fileName = p.basename(relativePath);


        buffer.writeln('  - **File**: [`$fileName`]($fileUrl)');


      }





      if (testCase.goldenFiles.isNotEmpty) {


        buffer.writeln('  - **Golden Files:**');


        for (final goldenFile in testCase.goldenFiles) {


          buffer.writeln(


              '    - `${goldenFile.filename}`: ${goldenFile.description}');


        }


      }


    }


    buffer.writeln();


    buffer.writeln('---'); // Separator for each test case


    buffer.writeln();


  }





  buffer.writeln('## Test Case Summary Table');


  buffer.writeln();


  buffer.writeln('| Test ID | Description | File | Golden Files |');


  buffer.writeln('|---|---|---|---|');





    for (final id in sortedIds) {





      final testCasesForId = consolidatedMap[id]!;





  





      // Determine if all test cases for this ID share the same file path





      final allFilesAreSame =





          testCasesForId.map((c) => c.filePath).toSet().length == 1;





  





      bool firstEntryForId = true;





      for (final testCase in testCasesForId) {





        final currentIdCell =





            firstEntryForId ? '`$id`' : ''; // Only show ID for the first row of a group





  





        final descriptionContent = '- ${testCase.description}';





  





        String filesContent;





        if (allFilesAreSame) {





          filesContent = firstEntryForId





              ? testCasesForId.map((c) {





                  final relativePath = p





                      .relative(c.filePath, from: projectRoot)





                      .replaceAll('\\', '/');





                  final fileUrl = '$remoteUrl/blob/main/$relativePath';





                  final fileName = p.basename(relativePath);





                  return '[`$fileName`]($fileUrl)';





                }).toSet().join('<br>')





              : ''; // Show files only once if all are same





        } else {





          // If files differ, show file for each entry





          final relativePath = p





              .relative(testCase.filePath, from: projectRoot)





              .replaceAll('\\', '/');





          final fileUrl = '$remoteUrl/blob/main/$relativePath';





          final fileName = p.basename(relativePath);





          filesContent = '[`$fileName`]($fileUrl)';





        }





  





        final goldenFilesContent =





            testCase.goldenFiles.map((gf) => '`${gf.filename}`').join(', ');





  





        buffer.writeln(





            '| $currentIdCell | $descriptionContent | $filesContent | $goldenFilesContent |');





        firstEntryForId = false;





      }





    }





  return buffer.toString();


}