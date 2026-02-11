---
name: implement-feature-with-checks
description: Automatically enforce constitution compliance, UI Kit usage, testing, and code formatting when implementing features with CLEAR and SPECIFIC requirements. Use AFTER brainstorming or requirements clarification is complete, when user provides concrete implementation details. Do NOT use if requirements are vague or unclear - suggest brainstorming first. Trigger keywords (English) - implement, create, add, build, develop, make, modify, update, change, refactor, fix, repair. Trigger keywords (Chinese) - 實作, 創建, 新增, 開發, 製作, 修改, 更新, 改動, 重構, 修正, 修復, 修好.
---

# Implement Feature with Constitution Checks

## Purpose

This skill ensures ALL code changes in the PrivacyGUI project strictly follow the project constitution (`constitution.md`), prioritize UI Kit Library usage, and include proper testing and formatting. It automatically executes a complete development workflow without requiring manual reminders.

## When to Use This Skill

**CRITICAL**: This skill MUST be automatically invoked when the user requests ANY of the following:

### Feature Implementation
- Creating new features, pages, screens, or components
- Adding new functionality to existing features
- Implementing new business logic or UI elements
- Building new modules or systems

### Code Modifications
- Modifying existing functionality or behavior
- Updating business logic or state management
- Changing UI components or layouts
- Adjusting data models or APIs

### Refactoring
- Restructuring Provider/Service/View layers
- Extracting business logic
- Reorganizing code architecture
- Improving code quality or patterns

### Bug Fixes (Non-Trivial)
- Fixing bugs that require logic changes
- Repairing broken functionality
- Correcting behavioral issues
- Resolving state management problems

### Trigger Keywords

**English Keywords:**
- implement, create, add, build, develop, make, write
- modify, update, change, adjust, edit
- refactor, restructure, reorganize, extract
- fix, repair, resolve, correct

**Traditional Chinese Keywords:**
- 實作, 創建, 新增, 開發, 製作, 寫, 建立
- 修改, 更新, 改動, 調整, 編輯
- 重構, 重整, 重組, 提取
- 修正, 修復, 修好, 解決, 糾正

## When NOT to Use This Skill

Skip this skill ONLY for:
- ❌ **Unclear or vague requirements** (use `superpowers:brainstorming` first)
- ❌ **Requirements need exploration** (user says "不確定", "不知道怎麼做", "不太清楚")
- ❌ Single-line typo fixes
- ❌ Pure documentation updates (README, comments only)
- ❌ Research or exploration tasks (no code changes)
- ❌ Simple configuration changes (no logic involved)

**Important**: If user's request lacks specific details, suggest brainstorming or clarification before invoking this skill.

## Execution Workflow

### Phase 1: Constitution Review and Planning

**Step 1.0: Requirements Clarity Check**

Before proceeding with implementation, assess if requirements are sufficiently clear:

❌ **Unclear Requirements Indicators** (Should use brainstorming first):
- User says: "但不確定", "不知道怎麼做", "不太清楚", "可能需要", "不確定要包含什麼"
- Feature scope is vague: "add a settings page" (which settings?)
- No specific details provided: "create a new feature" (what feature?)
- Multiple possible approaches with no guidance
- User asks questions about what should be included
- No UI/UX details for new screens
- Unclear data models or business logic

✅ **Clear Requirements Indicators** (Can proceed with implementation):
- Specific feature details provided: "add WiFi settings page with SSID list and password input"
- User gives concrete examples: "like the existing DMZ page but for port forwarding"
- After a brainstorming session has completed
- Refactoring with clear target: "extract business logic from Provider to Service"
- Bug fix with identified root cause: "fix null pointer in saveSettings method"
- User confirms: "yes, proceed with this approach"

**Decision Tree**:

```
Requirements unclear?
  ├─ YES → ❌ STOP this skill
  │        ├─ Inform user: "需求還不夠明確，讓我先幫你釐清實作細節..."
  │        ├─ Suggest: "我建議先討論以下問題：[list key questions]"
  │        ├─ Or invoke: `superpowers:brainstorming` skill
  │        └─ Wait for clarity, then re-invoke this skill
  │
  └─ NO → ✅ Proceed to Step 1.1
```

**Step 1.1: Read Constitution**
- Read `constitution.md` from the project root
- Identify relevant principles based on the task scope
- Extract key requirements:
  - Architecture principles (Article V: Layer separation)
  - Naming conventions (Article III)
  - Testing requirements (Article I & VIII)
  - Service layer guidelines (Article VI)
  - Error handling strategy (Article XIII)
  - UI Kit usage (Article XIV)

**Step 1.2: Analyze Task Scope**
- Determine affected layers (View/Provider/Service/Model)
- Identify required components based on constitution
- Plan file structure following naming conventions
- Check if UI components will be needed

**Step 1.3: Communicate Plan to User**
- Summarize the planned approach
- List files to be created or modified
- Mention key constitution principles that will be followed
- Ask for user confirmation before proceeding

### Phase 2: UI Kit Component Verification (If UI Changes)

**CRITICAL**: If the task involves ANY UI components, you MUST:

**Step 2.1: Identify Required UI Components**
- List all UI elements needed (buttons, text, inputs, cards, etc.)
- Specify the exact functionality for each element

**Step 2.2: Search ui_kit_library**
- Check `package:ui_kit_library/ui_kit.dart` for available components
- Common components to check:
  - Buttons: `AppButton.primary()`, `AppButton.text()`, `AppButton.primaryOutline()`
  - Text: `AppText.titleLarge()`, `AppText.bodyMedium()`, `AppText.labelLarge()`
  - Cards: `AppCard()`
  - Input: `AppTextFormField()`
  - Selection: `AppCheckbox()`, `AppSwitch()`
  - Dialogs: `showSimpleAppDialog()`, `showAppSpinnerDialog()`
  - Spacing: `AppGap.md()`, `AppGap.lg()`, `AppSpacing.xl`
  - Colors: `Theme.of(context).extension<AppColorScheme>()`

**Step 2.3: Handle Missing Components**
- **IF component exists in ui_kit**: Use it directly
- **IF component is missing**:
  1. ❌ **STOP implementation immediately**
  2. Use `AskUserQuestion` tool to ask user:
     - "I need [component description] but couldn't find it in ui_kit_library."
     - "How should I proceed?"
     - Options:
       - "Propose adding it to ui_kit_library"
       - "Use an alternative approach"
       - "Create a custom component for this project"
       - "Other (please specify)"
  3. **WAIT for user decision** before continuing

### Phase 3: Implementation

**Step 3.1: Create Required Files**

Following constitution naming conventions (Article III):
- Service files: `lib/page/[feature]/services/[feature]_service.dart`
- Provider files: `lib/page/[feature]/providers/[feature]_provider.dart`
- State files: `lib/page/[feature]/providers/[feature]_state.dart`
- View files: `lib/page/[feature]/views/[feature]_view.dart`
- Model files: `lib/page/[feature]/models/[feature]_ui_model.dart` (if needed)

**Step 3.2: Implement Following Constitution**

**Architecture (Article V & VI)**:
- ✅ Strict layer separation (View → Provider → Service → Data)
- ✅ Services handle business logic and JNAP communication
- ✅ Providers manage state and coordinate services
- ✅ Views only handle UI rendering
- ❌ No JNAP models in Provider or View layers
- ❌ No cross-layer dependencies

**Error Handling (Article XIII)**:
- ✅ Services convert JNAPError to ServiceError
- ✅ Providers only catch ServiceError types
- ❌ No JNAPError handling in Providers

**UI Implementation (Article XIV)**:
- ✅ All UI components from ui_kit_library
- ✅ Use unified import: `import 'package:ui_kit_library/ui_kit.dart';`
- ❌ No custom implementations of existing ui_kit components

**Step 3.3: Implement Tests (MANDATORY)**

Following Article I & VIII requirements:
- Create test files in `test/page/[feature]/` mirroring implementation structure
- Service tests: `test/page/[feature]/services/[feature]_service_test.dart`
- Provider tests: `test/page/[feature]/providers/[feature]_provider_test.dart`
- State tests: `test/page/[feature]/providers/[feature]_state_test.dart` (if separate state class)
- Use Test Data Builders from `test/mocks/test_data/` or create new ones
- Use Mocktail for mocking (Article I Section 1.6.1)

**Test Coverage Requirements**:
- Service Layer: ≥90%
- Provider Layer: ≥85%
- State Layer: ≥90%
- Overall: ≥80%

**Test Organization**:
- Use descriptive test names (no numbering)
- Group tests by feature/category
- Mock dependencies properly (RouterRepository, Services)

### Phase 4: Testing Execution

**Step 4.1: Run Unit Tests**
```bash
./run_tests.sh
```

**Step 4.2: Verify Test Results**
- ✅ All tests must pass
- ✅ Coverage meets requirements
- ❌ If tests fail: Fix issues before proceeding
- ❌ If coverage is low: Add missing tests

**Step 4.3: Run Screenshot Tests (If UI Changes)**
Only if UI components were added/modified:
```bash
./run_generate_loc_snapshots.sh
```

### Phase 5: Code Quality Checks

**Step 5.1: Format Code**
```bash
dart format lib/page/[feature]/ test/page/[feature]/
```

**Step 5.2: Run Static Analysis**
```bash
flutter analyze
```

**Step 5.3: Verify No New Issues**
- ✅ No new lint errors introduced
- ✅ No new warnings introduced
- ❌ If issues found: Fix before completion

### Phase 6: Final Verification

**Step 6.1: Constitution Compliance Check**

Run architecture compliance commands from Article V Section 5.3.3:

```bash
# Check JNAP models not imported in Providers
grep -r "import.*jnap/models" lib/page/*/providers/

# Check JNAP models not imported in Views
grep -r "import.*jnap/models" lib/page/*/views/

# Check Service layer has correct JNAP imports
grep -r "import.*jnap/models" lib/page/*/services/

# Check Provider layer doesn't have JNAPError imports
grep -r "import.*jnap/result" lib/page/*/providers/
grep -r "on JNAPError" lib/page/*/providers/

# Check Service layer imports ServiceError
grep -r "import.*core/errors/service_error" lib/page/*/services/
```

**Expected Results**:
- ✅ Providers: 0 JNAP imports
- ✅ Views: 0 JNAP imports
- ✅ Services: JNAP imports present (correct)
- ✅ Providers: 0 JNAPError usage
- ✅ Services: ServiceError imports present

**Step 6.2: Report Completion**
- Summarize all changes made
- List files created/modified
- Report test results and coverage
- Confirm constitution compliance
- Note any deviations or special considerations

## Success Criteria

Implementation is considered complete when ALL of the following are met:

- ✅ Constitution principles followed (architecture, naming, error handling)
- ✅ UI components use ui_kit_library (or user approved alternatives)
- ✅ All layers properly separated (View/Provider/Service/Model)
- ✅ Unit tests written and passing
- ✅ Test coverage meets requirements (≥80% overall)
- ✅ Screenshot tests generated (if UI changes)
- ✅ Code formatted (dart format)
- ✅ No new lint errors (flutter analyze)
- ✅ Architecture compliance verified

## Examples

### Example 1: Creating a New Feature

**User Request**: "幫我實作一個新的 settings 畫面來管理通知設定"

**Skill Execution**:
1. **Phase 1**: Read constitution, plan architecture (View/Provider/Service/State)
2. **Phase 2**: Check ui_kit for buttons, switches, cards → All found ✅
3. **Phase 3**: Implement files following naming conventions, write tests
4. **Phase 4**: Run `./run_tests.sh` → All pass ✅, coverage 87% ✅
5. **Phase 5**: Run `dart format`, `flutter analyze` → No issues ✅
6. **Phase 6**: Verify architecture compliance → All checks pass ✅

### Example 2: Refactoring with Missing UI Component

**User Request**: "重構 DMZ settings page，需要用新的 Provider 架構"

**Skill Execution**:
1. **Phase 1**: Read constitution, identify refactoring scope
2. **Phase 2**: Check ui_kit for needed components → Custom slider needed ❌
3. **STOP**: Use AskUserQuestion → User decides to propose to ui_kit
4. **Phase 3**: After user decision, continue with refactoring
5. **Phase 4-6**: Tests, format, verify

### Example 3: Bug Fix

**User Request**: "修正 WiFi settings 無法儲存的問題"

**Skill Execution**:
1. **Phase 1**: Read constitution, understand architecture
2. **Phase 2**: No new UI components needed → Skip
3. **Phase 3**: Fix bug in Service layer, update tests
4. **Phase 4**: Run tests → All pass ✅
5. **Phase 5**: Format and analyze → Clean ✅
6. **Phase 6**: Verify compliance → Pass ✅

### Example 4: Unclear Requirements (Requires Brainstorming First)

**User Request**: "我想實作一個新的通知設定頁面，但不確定要包含哪些功能"

**Skill Execution**:
1. **Phase 1 - Step 1.0**: Requirements clarity check
   - Detected: "但不確定要包含哪些功能" ❌
   - **STOP**: Requirements are unclear
   - Inform user: "需求還不夠明確，讓我先幫你釐清實作細節..."
   - Suggest key questions:
     - 需要哪些通知類型？(推送通知/App 內通知)
     - 用戶可以控制哪些設定？(開關/頻率/時間)
     - 是否需要群組設定？
     - UI 參考哪個現有頁面？
   - Or invoke: `superpowers:brainstorming` skill

2. **After Brainstorming**: User clarifies requirements
   - "好，就做推送通知的開關，每個功能模組獨立設定，用 ListView + Switch 排列"
   - Requirements now clear ✅

3. **Re-invoke this skill**: Now proceed with clear requirements
   - **Phase 1**: Read constitution, plan NotificationSettingsView/Provider/Service
   - **Phase 2**: Check ui_kit for ListView, Switch → Found ✅
   - **Phase 3-6**: Implementation, testing, formatting, verification

## Important Notes

- This skill runs automatically - user does not need to explicitly request it
- **Requirements clarity is checked first** - if unclear, this skill will stop and suggest brainstorming
- **Works in tandem with brainstorming**: Use brainstorming → clarify → then invoke this skill
- The skill will STOP and ask questions when:
  - **Requirements are unclear or vague** (suggest brainstorming or clarification)
  - Required UI components are missing from ui_kit
  - Tests fail and cannot be fixed automatically
  - Constitution principles would be violated
- All communication with user should be in Traditional Chinese (Taiwan)
- Always read constitution fresh for each invocation (don't rely on memory)
- Be strict about constitution compliance - no exceptions without user approval
- **Priority order**: Clarity → Constitution → Implementation → Testing → Verification

## References

- Project Constitution: `constitution.md` (root directory)
- UI Kit Library: `package:ui_kit_library/ui_kit.dart`
- Test Data Builders: `test/mocks/test_data/`
- Testing Guidelines: `doc/screenshot_testing_guideline.md`
- Dirty Guard Guide: `doc/dirty_guard/dirty_guard_framework_guide.md`