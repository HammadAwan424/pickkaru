# Pickkaru Architecture & Style Guidelines

This document outlines the UI architecture and code organization established for the Pickkaru Flutter application. It is based heavily on a "Screens + Hooks + Styles" philosophy (adapted for Flutter and Riverpod) to keep the codebase clean, modular, and highly maintainable.

## 1. The Core Architecture Pattern

Our UI layer is strictly separated into three distinct domains. Files should be organized into subdirectories (e.g., `widgets/`, `styles/`, `controllers/`) reflecting these responsibilities.

### A. Screens & Views (The Blueprint)
**Responsibility:** Structural composition and routing. 
- Screens should be "dumb." They compose structural layouts (e.g., `Scaffold`, `Column`, `Expanded`).
- **No raw styles:** They should not contain hardcoded `BoxDecoration`, `TextStyle`, or complex padding metrics.
- **No raw logic:** They should not contain complex calculations, transformations, or direct riverpod state mutations (e.g., calling `ref.read(...).update(...)`).
- Instead, Screens instantiate a **Controller** (for logic) and compose **Styles** (for UI).

### B. Styles / Component Wrappers (The Paint)
**Responsibility:** Visual presentation and encapsulation.
- Extracted into a `styles/` subdirectory.
- **Widget Composition (Design System approach):** Rather than creating static style classes (like `AppStyles.boxDecoration`), we extract the entire styled container into a reusable wrapper widget (e.g., `PollBottomPanel`, `PollRowSurface`).
- These widgets encapsulate all container-specific visual details: `BoxDecoration`, colors, shadows, borders, and paddings. 
- The parent Screen just calls the wrapper and passes `child` elements, keeping the UI tree clean.

### C. Controllers / Hooks (The Brains)
**Responsibility:** Calculations, state derivations, and event handlers.
- Extracted into a pure Dart class (e.g., `StudentControlsController`), or a specific Riverpod ViewModel provider.
- Controllers take in the raw data (like `WidgetRef`, raw `PollResponse`, etc.) and compute all derived boolean states (e.g., `isSaving`, `canMarkBoarded`).
- Controllers also encapsulate the UI event callbacks (e.g., `handleAnswerChanged`, `handleMarkBoarded`).
- This allows the UI Widget to be completely stateless and purely declarative.

## 2. Naming Conventions & Visibility

### Do not use private `_` prefixes for major structural widgets
By default, Dart encourages prefixing classes with `_` to make them library-private. However, in this project:
- **Major structural components** (e.g., `PollPeriodView`, `CustomChoiceButton`, `PollStatusPill`) should **not** use the `_` prefix, even if they currently only live in one file.
- **Why?** Making them public increases discoverability. It clearly signals that they are major components of the screen, makes them easier to search in the IDE, and drastically simplifies extracting them into their own files as the app grows.
- Only truly trivial helper functions or private local state classes should use the `_` prefix.

## 3. Example Workflow: Refactoring a Monolithic Widget

When breaking down a large Screen widget:
1. Identify large chunks of raw styling (`Container` with `decoration`, custom `InkWell` behaviors) and extract them into `lib/feature/widgets/styles/my_styled_component.dart`.
2. Identify all derived calculations (e.g., `final isLocked = state.isLoading || status == completed`) and event callbacks and extract them into a vanilla Dart class `lib/feature/controllers/my_feature_controller.dart`.
3. The remaining Screen widget should now cleanly read:
   ```dart
   Widget build(BuildContext context, WidgetRef ref) {
     final controller = MyFeatureController(ref, ...);
     
     return MyStyledComponent(
       onTap: controller.handleSubmit,
       isLocked: controller.isLocked,
       child: Text(controller.displayTitle),
     );
   }
   ```
