---
name: flutter-code-review
description: Comprehensive code review checklist for Flutter Clean Architecture, Cubit state management, screen lifecycles, and widget rendering performance.
---

# Flutter Code Review Standards & Checklist

## Overview

This skill defines the technical review criteria for the Flutter application (`app/lib/`), targeting architectural compliance, memory safety, async lifecycle correctness, and rendering performance.

---

## 1. Clean Architecture & Layer Boundaries

### Checklist

- [ ] **No DTO Leaks**: `presentation/` (screens, widgets, cubits) and `domain/` must never import `data/api/models/`. Only `domain/entities/` may be referenced.
- [ ] **Repository Encapsulation**: Presentation and Cubit code must only interact with `domain/interfaces/i_*_repository.dart`. Direct calls to `RemoteDataSource` or HTTP clients are prohibited.
- [ ] **Type-Safe Deserialization**: No manual `json['key']` map lookups in application code; all deserialization must use Freezed `fromJson` models.
- [ ] **Business Logic in Domain**: Mathematical computations, business validations, and domain rules must reside in `domain/entities/` or `domain/services/`, not inside Cubits or Widget build methods.

```dart
// ❌ Incorrect: Presentation importing API DTO
import 'package:app/data/api/models/trip_dto.dart';

// ✅ Correct: Presentation uses Domain entity
import 'package:app/domain/entities/trip.dart';
```

---

## 2. Cubit & State Management Safety

### Checklist

- [ ] **Resource Disposal in `close()`**: Any `StreamSubscription`, `Timer`, `TextEditingController`, or `ScrollController` held by a Cubit must be properly cancelled or disposed in its `close()` override.
- [ ] **Emit After Closed Protection**: Every asynchronous operation (`await`) inside a Cubit method must check `if (isClosed) return;` before invoking `emit()`.
- [ ] **Distinct State Emissions**: State classes must be immutable (using Freezed or Equatable) to avoid silent failures in `BlocBuilder` state comparison.
- [ ] **Error Handling Completeness**: Async repository calls must handle domain failures explicitly without leaving the Cubit in an unrecoverable loading state.

```dart
// ❌ Incorrect: Potential emit after Cubit closed
Future<void> loadTrip(String id) async {
  emit(const TripState.loading());
  final result = await _repo.getTrip(id);
  emit(TripState.loaded(result)); // May throw if closed during await
}

// ✅ Correct: Guarded by isClosed
Future<void> loadTrip(String id) async {
  emit(const TripState.loading());
  final result = await _repo.getTrip(id);
  if (isClosed) return;
  emit(TripState.loaded(result));
}
```

---

## 3. Screen Lifecycle & BuildContext Safety

### Checklist

- [ ] **Async Context Gap**: Never use `BuildContext` across an `await` boundary without verifying `if (!mounted) return;`.
- [ ] **Controller Lifecycle**: `TextEditingController`, `AnimationController`, and focus nodes must be initialized in `initState()` and disposed in `dispose()`, never created in `build()`.
- [ ] **Granular Rebuilds**: Avoid triggering full-screen rebuilds with `setState()` when localized state management (`BlocBuilder` / `ValueNotifier`) suffices.
- [ ] **Design System Compliance**: Replace hardcoded hex colors and text styles with `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`.

```dart
// ❌ Incorrect: Using context across async gap without mounted check
Future<void> _onSubmit(BuildContext context) async {
  await doAsyncWork();
  Navigator.of(context).pop(); // Unsafe if widget unmounted
}

// ✅ Correct: Mounted guard
Future<void> _onSubmit(BuildContext context) async {
  await doAsyncWork();
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

---

## 4. Widget Performance & Layout Safety

### Checklist

- [ ] **List Virtualization**: Dynamic collections must use `ListView.builder` or `SliverList` rather than `ListView(children: ...)` or `Column` wrapped in `SingleChildScrollView`.
- [ ] **Object Allocation in Build**: Avoid instantiating expensive objects (`DateFormat`, `RegExp`, complex `BoxDecoration`) inside `Widget.build()`. Define them as static constants or top-level utilities.
- [ ] **Flex Overflow Prevention**: Any unconstrained child within a `Row` or `Column` containing text or dynamic widgets must be wrapped in `Expanded` or `Flexible` to prevent `RenderFlex overflowed` errors.
- [ ] **Const Constructors**: Use `const` constructors wherever possible to enable Flutter element tree reuse.

---

## Review Output Format

When providing code review findings, structure items by severity:

```markdown
### [Severity: High/Medium/Low] File:LineRange - Short Title
- **Problem**: Objective explanation of the defect or architectural violation.
- **Risk**: Concrete impact (crash, memory leak, UI glitch, layer violation).
- **Remediation**: Recommended fix with a concise code example.
```
