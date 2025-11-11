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
      final testCases = await _parseTestFile(file, debugMode);
      allTestCases.addAll(testCases);
    }
    print('Extracted ${allTestCases.length} total test cases.');

    // 4. Generate Markdown content
    final markdownContent = _generateMarkdown(allTestCases, remoteUrl, projectRoot);

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

/// Recursively finds files matching `localizations/.*_test.dart$`.
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
  final lines = await file.readAsLines();

  final idRegex = RegExp(r'// Test ID: ([A-Z0-9-]+)');
  final descriptionRegex = RegExp(r"testLocalizations\('([^']*)'");
  final goldenFilenameParamRegex = RegExp(r"goldenFilename: '([^']*)'");
  final takeScreenshotRegex = RegExp(r"TestHelper\.takeScreenshot\(tester, '([^']*)'\)");

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final idMatch = idRegex.firstMatch(line);

    if (idMatch != null) {
      final baseId = idMatch.group(1)!.trim();
      String? mainDescription;
      String? goldenFilename;
      final List<GoldenFileInfo> goldenFiles = [];
      int scanStart = i + 1; // Declare and initialize scanStart here

      // Scan forward to find the testLocalizations description within a limited range
      int descriptionScanEnd = i + 10; // Scan up to 10 lines after Test ID
      if (descriptionScanEnd > lines.length) descriptionScanEnd = lines.length;

      for (int j = i + 1; j < descriptionScanEnd; j++) { // Start from line after Test ID
        final currentLine = lines[j];
        
        // Attempt to find description on the same line as testLocalizations(
        final descMatchSameLine = RegExp(r"testLocalizations\('([^']*)'").firstMatch(currentLine);
        if (descMatchSameLine != null) {
          mainDescription = descMatchSameLine.group(1)!.trim();
          scanStart = j; // Update scanStart to the line where description was found
          break;
        }

        // If not found on the same line, check if currentLine contains "testLocalizations("
        // and then look for description on the next line.
        if (currentLine.contains("testLocalizations(")) {
          if (j + 1 < lines.length) {
            final nextLine = lines[j + 1];
            final descMatchNextLine = RegExp(r"'([^']*)'").firstMatch(nextLine); // Regex to just find the quoted string
            if (descMatchNextLine != null) {
              mainDescription = descMatchNextLine.group(1)!.trim();
              scanStart = j; // Update scanStart to the line where description was found
              break;
            }
          }
        }
      }

      if (mainDescription == null) {
        continue; // Skip if no description found
      }

      // Scan for goldenFilename and takeScreenshot calls within this test block
      // We'll scan until the next Test ID or end of file
      int testBlockEndLine = lines.length - 1; // Default to end of file
      for (int j = scanStart; j < lines.length; j++) {
        final currentLine = lines[j];

        // Stop if we hit the next Test ID
        if (idRegex.firstMatch(currentLine) != null && j > scanStart) {
          testBlockEndLine = j - 1; // Mark end before next Test ID
          break;
        }

        // Extract goldenFilename from testLocalizations parameter
        final goldenFilenameMatch = goldenFilenameParamRegex.firstMatch(currentLine);
        if (goldenFilenameMatch != null) {
          goldenFilename = goldenFilenameMatch.group(1)!.trim();
          goldenFiles.add(GoldenFileInfo(filename: goldenFilename, description: 'Final State')); // Default description
        }

        // Extract filenames from TestHelper.takeScreenshot calls
        // Look for "TestHelper.takeScreenshot(" on the current line
        if (currentLine.contains("TestHelper.takeScreenshot(")) {
          // Scan forward a few lines to find the filename
          int screenshotScanEnd = j + 5; // Scan up to 5 lines after the call
          if (screenshotScanEnd > lines.length) screenshotScanEnd = lines.length;

          for (int k = j; k < screenshotScanEnd; k++) {
            final scanLine = lines[k];
            final takeScreenshotMatch = RegExp(r"'([^']*)'").firstMatch(scanLine); // Just look for the quoted string
            if (takeScreenshotMatch != null) {
              final screenshotFilename = takeScreenshotMatch.group(1)!.trim();
              final desc = screenshotFilename.split('_').skip(3).join(' '); // Skip TestID_NN_
              goldenFiles.add(GoldenFileInfo(filename: screenshotFilename, description: desc.isNotEmpty ? desc : 'Intermediate State'));
              if (debugMode) {
                print('      Found takeScreenshot: $screenshotFilename at line ${k + 1}');
              }
              break; // Found the filename, move to next line in main loop
            }
          }
        }
      }

      // If goldenFilename was not found (e.g., testLocalizations without goldenFilename), skip this test case
      if (goldenFilename == null) {
        if (debugMode) {
          print('    No goldenFilename found for Test ID: $baseId, skipping test case.');
        }
        continue;
      }

      if (debugMode) {
        print('    Golden Files collected for $baseId:');
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

      // Advance the main loop to avoid re-processing lines already scanned
      i = testBlockEndLine;
    }
  }
  return testCases;
}

/// Generates the final Markdown string from the collected test cases.
String _generateMarkdown(List<TestCaseInfo> testCases, String remoteUrl, String projectRoot) {
  final buffer = StringBuffer();

  buffer.writeln('# Test Case Documentation');
  buffer.writeln();
  buffer.writeln('This document lists all screenshot test cases found in the project.');
  buffer.writeln('It is auto-generated by `tools/generate_test_report.dart`.');
  buffer.writeln();

  // Sort by ID for consistent ordering
  testCases.sort((a, b) => a.id.compareTo(b.id));

  for (final testCase in testCases) {
    final relativePath = p.relative(testCase.filePath, from: projectRoot).replaceAll('\\', '/');
    final fileUrl = '$remoteUrl/blob/main/$relativePath';
    final fileName = p.basename(relativePath);

    buffer.writeln('## `${testCase.id}`');
    buffer.writeln();
    buffer.writeln('**Description**: ${testCase.description}');
    buffer.writeln('**File**: [`$fileName`]($fileUrl)');
    buffer.writeln();

    if (testCase.goldenFiles.isNotEmpty) {
      buffer.writeln('### Golden Files:');
      buffer.writeln();
      for (final goldenFile in testCase.goldenFiles) {
        buffer.writeln('- `${goldenFile.filename}`: ${goldenFile.description}');
      }
      buffer.writeln();
    }
    buffer.writeln('---'); // Separator for each test case
    buffer.writeln();
  }

  buffer.writeln('## Test Case Summary Table');
  buffer.writeln();
  buffer.writeln('| Test ID | Description | File | Golden Files |');
  buffer.writeln('|---|---|---|---|');

  for (final testCase in testCases) {
    final relativePath = p.relative(testCase.filePath, from: projectRoot).replaceAll('\\', '/');
    final fileUrl = '$remoteUrl/blob/main/$relativePath';
    final fileName = p.basename(relativePath);

    final goldenFilesList = testCase.goldenFiles.map((gf) => '`${gf.filename}`').join(', ');

    buffer.writeln('| `${testCase.id}` | ${testCase.description} | [`$fileName`]($fileUrl) | $goldenFilesList |');
  }

  return buffer.toString();
}
