---
description: Review all screenshot tests and generate analysis report
---

# Screenshot Test Review Workflow

This workflow reviews all screenshot testing files based on the Screenshot Testing Guideline and produces a comprehensive analysis report.

## Prerequisites

- Review the guideline document: `doc/screenshot_test/screenshot_testing_guideline.md`
- Understand the knowledge base: `doc/screenshot_test/screenshot_testing_knowledge_base.md`
- Check existing master report: `doc/screenshot_test/SCREENSHOT_TEST_MASTER_REPORT.md`

## Step 1: Locate All Screenshot Test Files

Find all screenshot test files in the test directory:

```bash
find test -name "*_test.dart" -type f | xargs grep -l "testLocalizations\|testResponsiveWidgets" 2>/dev/null | head -100
```

## Step 2: Extract Test Metadata

For each test file, extract the following information:
1. **View ID**: Look for `// View ID: XXXX` pattern
2. **Reference to Implementation File**: Look for `// Reference:` or the implementation file path
3. **Test ID Table**: Extract the file-level summary table with all Test IDs
4. **Individual Test Cases**: Extract each `// Test ID:` and its description

## Step 3: Guideline Compliance Check

For each test file, check compliance with the Screenshot Testing Guideline:

### 3.1 Structure & Documentation
- [ ] Has View ID (up to 5 uppercase letters, no hyphens/underscores)
- [ ] Has Reference to Implementation File
- [ ] Has File-Level Summary table
- [ ] Test IDs follow format `{ViewID}-{SHORT_DESCRIPTION}`
- [ ] Golden file naming follows `[TestID]-[number]-[description]` pattern
- [ ] Descriptive test titles in clear English

### 3.2 Test Helper Usage
- [ ] Uses centralized `TestHelper`
- [ ] Proper use of `pumpView` vs `pumpShellView`
- [ ] Uses `testHelper.setup()` in setUp block

### 3.3 Test Setup
- [ ] State mocking with `when(...).thenReturn(...)`
- [ ] All required Notifiers are mocked for complex views

### 3.4 Test Execution & Verification
- [ ] Has `expect` assertions (not just screenshots)
- [ ] Handles asynchronicity with `pumpAndSettle()`
- [ ] Uses `preCacheRouterImages` or `precacheImage` for images

## Step 4: Run Tests and Collect Results

Run the screenshot tests and collect results:

```bash
# Run all localization tests
flutter test --tags localization --reporter expanded 2>&1 | tee test_results.txt

# Or run specific test file
flutter test test/path/to/specific_test.dart --reporter expanded
```

## Step 5: Generate Analysis Report

Create a comprehensive report with the following sections:

### Report Structure

```markdown
# Screenshot Test Analysis Report

**Generated**: [Date/Time]
**Total Test Files**: [Count]
**Total Test Cases**: [Count]

## Summary Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| Files with View ID | X | X% |
| Files with Summary Table | X | X% |
| Tests with proper Test ID | X | X% |
| Tests with expect assertions | X | X% |

## Compliance Status by File

| File | View ID | Summary | Test IDs | Assertions | Status |
|------|---------|---------|----------|------------|--------|
| ... | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | PASS/FAIL |

## Issues Found

### Critical Issues
- [List of critical compliance issues]

### Warnings
- [List of minor issues or suggestions]

## Recommendations

1. [Priority 1 fixes]
2. [Priority 2 improvements]
3. [Future enhancements]

## Detailed File Analysis

### [File Name 1]
- **View ID**: ...
- **Implementation**: ...
- **Test Cases**: [count]
- **Compliance Issues**: ...

### [File Name 2]
...
```

## Step 6: Save Report

Save the generated report to:
```
doc/screenshot_test/SCREENSHOT_TEST_ANALYSIS_REPORT.md
```

## Output

After completing this workflow, you will have:
1. A comprehensive analysis of all screenshot test files
2. Compliance status for each file against the guidelines
3. List of issues and recommendations for improvement
4. The report saved in `doc/screenshot_test/SCREENSHOT_TEST_ANALYSIS_REPORT.md`

## Notes

- If you encounter test failures, document them in the report
- For files missing View IDs, suggest appropriate IDs based on the view name
- Prioritize files that need the most attention in the recommendations section
