# Project Conventions and Guidelines

This document outlines the general conventions and guidelines for development within this project. Adhering to these guidelines ensures consistency, maintainability, and quality across the codebase.

## 1. General Principles

*   **Consistency:** Follow existing code style, naming conventions, and architectural patterns.
*   **Readability:** Write clear, concise, and self-documenting code.
*   **Modularity:** Design components with clear responsibilities and minimal coupling.
*   **Testing:** Ensure adequate test coverage for all new features and bug fixes.

## 2. Test Data Conventions

When working with test data, especially within the `test/test_data/` directory, the following conventions apply:

### 2.1 FeatureState Test Data Structure

For test states that represent `FeatureState` (or its `Settings` and `Status` components), ensure they are correctly structured to align with the latest `FeatureState` definition. This typically involves wrapping settings within a `Preservable` object if the feature utilizes dirty checking.

### 2.2 `fromMap` Constructor Requirement

Before running tests, verify that any `FeatureState` (or its `Settings` and `Status` components) used in `test/test_data/**` has a `fromMap` constructor. If a `fromMap` constructor is missing, it **must** be added to enable proper deserialization and reconstruction of test data. This is crucial for consistent test setup and data manipulation.

## 3. Code Style and Formatting

*   Adhere to Dart's official style guide (`Effective Dart`).
*   Use `dart format` to automatically format code.

## 4. OpenSpec Usage

*   Follow the guidelines in `openspec/AGENTS.md` for creating and implementing change proposals.
*   Ensure `tasks.md` files are kept up-to-date with the status of implementation tasks.
