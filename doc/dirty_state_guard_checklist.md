# "Dirty State" Navigation Guard Framework - Checklist

This checklist outlines the actionable tasks required to implement the navigation guard framework.

---

### **Phase 1: Core Framework Implementation**
- [x] **Task 1.1:** Create the `Preservable<T>` generic wrapper class.
- [x] **Task 1.2:** Update the `FeatureState<S, T>` abstract base class to include the `copyWith` contract.
- [x] **Task 1.3:** Create the `PreservableContract` interface and the `PreservableNotifierMixin`.
- [x] **Task 1.4:** Update the `LinksysRoute` class to check for `PreservableContract` and call `revert()`.

---

### **Phase 2: Framework Unit & Integration Testing**
- [x] **Task 2.1:** Configure the test environment to run tests using the `'dirty-guard-framework'` tag.
- [x] **Task 2.2:** Write unit tests for `Preservable<T>` and `PreservableNotifierMixin`.
- [x] **Task 2.3:** Write an integration test for the updated `LinksysRoute` logic.

---

### **Phase 3: Reference Implementation - Refactor `InstantSafety` Feature**
- [x] **Task 3.1:** Refactor `InstantSafetyState` to extend the updated `FeatureState`.
- [x] **Task 3.2:** Refactor `InstantSafetyNotifier` to use `with PreservableNotifierMixin`.
- [x] **Task 3.3:** Refactor `InstantSafetyView` to rely on the provider for state and actions.
- [x] **Task 3.4:** Ensure the `LinksysRoute` for `/instant-safety` is correctly configured.

---

### **Phase 4: Rollout & Documentation**
- [x] **Task 4.1:** Create/Update the framework specification document.
- [x] **Task 4.2:** Create/Update the framework implementation plan and checklist.
- [ ] **Task 4.3:** Update team development guidelines to incorporate the new framework.

---

### **Phase 5 (Optional): Wider Refactoring**
- [ ] **Task 5.1:** Identify and list other features (e.g., VPN page) that can be refactored to use this framework.