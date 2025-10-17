# "Dirty State" Navigation Guard Framework - Checklist

This checklist outlines the actionable tasks required to implement the navigation guard framework.

---

### **Phase 1: Core Framework Implementation**
- [ ] **Task 1.1:** Create the `Preservable<T>` generic wrapper class in `lib/providers/preservable.dart`.
- [ ] **Task 1.2:** Create the `FeatureState<S, T>` abstract base class in `lib/providers/feature_state.dart`.
- [ ] **Task 1.3:** Create the "Smart" `LinksysRoute<S>` class in `lib/route/linksys_route.dart`.

---

### **Phase 2: Framework Unit & Integration Testing**
- [ ] **Task 2.1:** Configure the test environment to run tests using the `'dirty-guard-framework'` tag.
- [ ] **Task 2.2:** Write and tag unit tests for the `Preservable<T>` class.
- [ ] **Task 2.3:** Write and tag integration tests for the `LinksysRoute<S>` class.

---

### **Phase 3: Reference Implementation - Refactor `InstantSafety` Feature**
- [ ] **Task 3.1:** Refactor `InstantSafetyState` to extend `FeatureState`.
- [ ] **Task 3.2:** Refactor `InstantSafetyNotifier` to manage the new state structure.
- [ ] **Task 3.3:** Refactor `InstantSafetyView` to remove `PreservedStateMixin` and rely solely on the provider.
- [ ] **Task 3.4:** Update the router configuration to use `LinksysRoute` for the `/instant-safety` path and enable the dirty check.

---

### **Phase 4: Rollout & Documentation**
- [x] **Task 4.1:** Create the framework specification document.
- [x] **Task 4.2:** Create the framework implementation plan document.
- [ ] **Task 4.3:** Update team development guidelines to incorporate the new framework as a standard pattern.

---

### **Phase 5 (Optional): Wider Refactoring**
- [ ] **Task 5.1:** Identify and list other features in the project (e.g., VPN page) that can be refactored to use this framework.
