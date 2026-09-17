# Mobile UX First Round Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the first mobile UX round: a global draggable quick-capture action plus safe, recoverable feedback around editing, privacy lock, deletion, and backup import.

**Architecture:** Keep the existing Flutter mobile shell and repository contracts. Add small reusable UI units for the draggable action and quick-capture sheet, inject a draft store into the editor, and keep navigation/data operations in `DiaryShell`. Use Flutter-native animation primitives and `MediaQuery.disableAnimations`; do not add an animation package.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Material 3, existing `shared_preferences`, `flutter_test`, `flutter_quill`.

**Spec:** `docs/superpowers/specs/2026-09-17-mobile-ux-first-round-design.md`

## Global Constraints

- 第一轮只改造移动端，不改变桌面端壳层和数据模型。
- 新增动画使用 Flutter 原生能力，不新增第三方动画库。
- 动效时长以 150–250ms 为主，并遵守 `MediaQuery.disableAnimations`。
- 本地写入不等待网络；状态反馈明确区分本机保存、失败和可重试动作。
- 每个行为先写一个会失败的测试，确认失败后再写生产代码。
- 完成前运行 `flutter analyze` 和 `flutter test -j 1`。

---

### Task 1: Global draggable quick capture

**Files:**
- Create: `mobile/lib/widgets/draggable_quick_capture.dart`
- Create: `mobile/lib/widgets/quick_capture_sheet.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Modify: `mobile/lib/pages/home/home_page.dart`
- Test: `mobile/test/quick_capture_widget_test.dart`

**Interfaces:**
- `DraggableQuickCaptureFab({required Future<void> Function(String) onSubmit, Offset? initialPosition, ValueChanged<Offset>? onPositionChanged, Key? key})` renders a `Semantics(label: '快速记录')` draggable action and opens the quick-capture sheet.
- `Future<void> showQuickCaptureSheet(BuildContext context, {required Future<void> Function(String) onSubmit})` opens the modal sheet and returns after dismissal.
- `MobileDiaryShell` loads and stores the snapped button position through `SharedPreferences` under a namespaced key; `HomePage` keeps the desktop quick panel but no longer renders the mobile inline `_QuickCaptureBar`.

- [ ] **Step 1: Write the failing widget tests**

Add tests that pump the mobile shell and assert:

```dart
expect(find.byKey(const Key('floating-quick-capture')), findsOneWidget);
expect(find.bySemanticsLabel('快速记录'), findsOneWidget);
await tester.tap(find.byKey(const Key('floating-quick-capture')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('quick-capture-sheet-field')), findsOneWidget);
```

Add a second test that enters `今天的一个瞬间`, taps `记下`, and asserts the injected callback receives that exact text.

- [ ] **Step 2: Run the focused tests and verify they fail for the missing feature**

Run from `mobile`:

```powershell
flutter test test/quick_capture_widget_test.dart -j 1
```

Expected: FAIL because the floating button and sheet keys do not exist yet.

- [ ] **Step 3: Implement the minimal draggable action and sheet**

Use a `Stack`/`LayoutBuilder` in `MobileDiaryShell` to place the button inside the body area above `NavigationBar`. Track the button's top-left `Offset`, clamp it to 16dp margins, and snap it to the nearest side on drag end. Use `AnimatedPositioned` only after the drag ends so the pointer remains responsive. The sheet must use `isScrollControlled: true`, `SafeArea`, and bottom `MediaQuery.viewInsets` padding.

- [ ] **Step 4: Re-run the focused tests and then the existing widget tests**

Run:

```powershell
flutter test test/quick_capture_widget_test.dart -j 1
flutter test test/widget_test.dart -j 1
```

Expected: PASS with no existing mobile shell regressions.

- [ ] **Step 5: Commit the task**

```powershell
git add mobile/lib/app/mobile_diary_shell.dart mobile/lib/pages/home/home_page.dart mobile/lib/widgets/draggable_quick_capture.dart mobile/lib/widgets/quick_capture_sheet.dart mobile/test/quick_capture_widget_test.dart
git commit -m "feat: add draggable mobile quick capture"
```

### Task 2: Editor drafts and navigation continuity

**Files:**
- Create: `mobile/lib/application/diary_draft_store.dart`
- Modify: `mobile/lib/app/diary_shell.dart`
- Modify: `mobile/lib/app/desktop_diary_shell.dart`
- Modify: `mobile/lib/pages/entry/entry_editor_page.dart`
- Modify: `mobile/lib/pages/entry/entry_detail_page.dart`
- Test: `mobile/test/diary_draft_store_test.dart`
- Test: `mobile/test/entry_editor_ux_test.dart`

**Interfaces:**
- `abstract interface class DiaryDraftStore` exposes `Future<Map<String, dynamic>?> load(String key)`, `Future<void> save(String key, Map<String, dynamic> value)`, and `Future<void> clear(String key)`.
- `MemoryDiaryDraftStore` is used by tests; `SharedPreferencesDiaryDraftStore` persists JSON under a namespaced key.
- `EntryEditorPage` accepts optional `DiaryDraftStore? draftStore` and `String? draftKey`; when omitted it uses no persistence, preserving existing desktop call sites until `DiaryShell` injects the store.
- `DiaryShellActions.openEditor` and `EntryDetailPage.onEdit` return `Future<DiaryEntry?>`; the editor pops the saved entry so the detail page can replace its local `_entry` without leaving the detail route.

- [ ] **Step 1: Write failing draft-store and editor tests**

Test that a store round-trips a draft map. Test that editing text calls `save` after the 500ms debounce, reopening with the same key offers `恢复草稿`, choosing it restores the title and body, and saving calls `clear`.

- [ ] **Step 2: Run the focused tests and verify the missing draft behavior**

Run:

```powershell
flutter test test/diary_draft_store_test.dart test/entry_editor_ux_test.dart -j 1
```

Expected: FAIL because the store injection, debounce, and recovery prompt do not exist.

- [ ] **Step 3: Implement draft persistence and close protection**

Serialize title, content, editor type, category, tags, mood, and attachment paths. Debounce all relevant controllers at 500ms, cancel the timer in `dispose`, and clear after a successful save. Route both the AppBar close action and system back through the same async discard confirmation.

- [ ] **Step 4: Preserve detail context after editing**

Change the detail page edit callback flow so the editor returns the saved entry or a success flag; update `_entry` and remain on the detail page. Do not pop the detail page after a successful edit.

- [ ] **Step 5: Re-run focused and full Flutter tests**

Run:

```powershell
flutter test test/diary_draft_store_test.dart test/entry_editor_ux_test.dart test/widget_test.dart -j 1
```

Expected: PASS.

- [ ] **Step 6: Commit the task**

```powershell
git add mobile/lib/application/diary_draft_store.dart mobile/lib/app/diary_shell.dart mobile/lib/app/desktop_diary_shell.dart mobile/lib/pages/entry/entry_editor_page.dart mobile/lib/pages/entry/entry_detail_page.dart mobile/test/diary_draft_store_test.dart mobile/test/entry_editor_ux_test.dart
git commit -m "feat: protect mobile editor drafts"
```

### Task 3: Privacy lock retry and recoverable destructive feedback

**Files:**
- Modify: `mobile/lib/app/diary_lock_gate.dart`
- Modify: `mobile/lib/app/diary_shell.dart`
- Modify: `mobile/lib/pages/recycle/recycle_page.dart`
- Modify: `mobile/lib/pages/settings/backup_page.dart`
- Test: `mobile/test/diary_lock_gate_test.dart`
- Test: `mobile/test/recoverable_actions_test.dart`

**Interfaces:**
- `DiaryLockGate` accepts an optional `Future<bool> Function()? authenticate` callback for tests and keeps the current `LocalAuthentication` path as the default.
- `DiaryShell` exposes the existing restore callback to the SnackBar action for the last trashed entry.
- `BackupPage` shows a confirmation dialog containing the parsed entry count before invoking the existing `onImport` replacement callback.
- `RecyclePage` accepts an optional `ValueChanged<DiaryEntry>? onRestore` path unchanged and includes attachment count in the permanent-delete confirmation.

- [ ] **Step 1: Write failing tests**

Test a cancelled/failed authentication leaves the lock gate visible with `验证未完成，请重试` and allows a second attempt. Test that permanent deletion confirmation includes the attachment count. Test that backup import confirmation includes the parsed record count before import.

- [ ] **Step 2: Run focused tests and confirm current failure**

Run:

```powershell
flutter test test/diary_lock_gate_test.dart test/recoverable_actions_test.dart -j 1
```

Expected: FAIL because cancellation currently exits the app and destructive flows have no required context.

- [ ] **Step 3: Implement lock retry**

Replace `_exitApp` on authentication failure/cancel with an error state, reset the attempt guard, and keep the lock screen active. The retry button must be enabled after the failed attempt.

- [ ] **Step 4: Implement undo and confirmation context**

After moving an entry to trash, show a SnackBar with `撤销` for 5 seconds and restore only that entry when pressed. Include the title and total attachment count in the permanent-delete confirmation. Before backup replacement, display the decoded entry count and require explicit confirmation; while busy, disable both import and export actions.

- [ ] **Step 5: Run focused and full tests**

Run:

```powershell
flutter test test/diary_lock_gate_test.dart test/recoverable_actions_test.dart test/widget_test.dart -j 1
```

Expected: PASS.

- [ ] **Step 6: Commit the task**

```powershell
git add mobile/lib/app/diary_lock_gate.dart mobile/lib/app/diary_shell.dart mobile/lib/pages/recycle/recycle_page.dart mobile/lib/pages/settings/backup_page.dart mobile/test/diary_lock_gate_test.dart mobile/test/recoverable_actions_test.dart
git commit -m "feat: make private actions recoverable"
```

### Task 4: Motion foundation and feedback polish

**Files:**
- Create: `mobile/lib/app/diary_motion.dart`
- Modify: `mobile/lib/widgets/entry_card.dart`
- Modify: `mobile/lib/app/diary_shell.dart`
- Modify: `mobile/lib/app/mobile_diary_shell.dart`
- Modify: `mobile/lib/pages/calendar/calendar_page.dart`
- Modify: `mobile/lib/pages/insights/insights_page.dart`
- Test: `mobile/test/diary_motion_test.dart`

**Interfaces:**
- `DiaryMotion.duration(BuildContext context, Duration normal)` returns `Duration.zero` when `MediaQuery.disableAnimations` is true, otherwise returns `normal`.
- `DiaryMotion.curve(BuildContext context, Curve normal)` returns `Curves.linear` when animations are disabled, otherwise returns `normal`.
- `CalendarPage` accepts an optional `VoidCallback? onOpenEditor` for its empty-state writing CTA.

- [ ] **Step 1: Write failing motion tests**

Test both normal and disabled animation media configurations. Add a widget assertion that an entry card changes its favorite icon through `AnimatedSwitcher` rather than replacing it without a keyed transition.

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```powershell
flutter test test/diary_motion_test.dart -j 1
```

Expected: FAIL because the motion helper and keyed favorite transition do not exist.

- [ ] **Step 3: Implement motion helper and targeted feedback**

Use the helper for quick-capture snap, favorite icon changes, and lightweight tab/page content transitions. Keep all animated properties to opacity, transform, size, or color; do not animate layout positions via repeated rebuilds outside the draggable control.

- [ ] **Step 4: Add calendar and insights affordances without changing data contracts**

Mark days with entries visibly, add a direct empty-state writing CTA where a callback is available, and make insight bars show a tooltip on touch. Keep existing query/data behavior unchanged in this task.

- [ ] **Step 5: Run full verification**

Run:

```powershell
flutter analyze
flutter test -j 1
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 6: Commit the task**

```powershell
git add mobile/lib/app/diary_motion.dart mobile/lib/app/diary_shell.dart mobile/lib/app/mobile_diary_shell.dart mobile/lib/widgets/entry_card.dart mobile/lib/pages/calendar/calendar_page.dart mobile/lib/pages/insights/insights_page.dart mobile/test/diary_motion_test.dart
git commit -m "feat: add mobile motion feedback"
```

### Task 5: Whole-branch review and finish

**Files:**
- Review: all files changed by Tasks 1–4

- [ ] **Step 1: Inspect the complete diff against the starting commit**

Run:

```powershell
git diff f189321..HEAD --stat
git diff f189321..HEAD -- mobile/lib mobile/test
```

Check that desktop behavior, data contracts, and existing tests remain unchanged except for the planned mobile UX hooks.

- [ ] **Step 2: Run the final verification suite**

Run:

```powershell
flutter analyze
flutter test -j 1
git diff --check
```

- [ ] **Step 3: Report the final commit set and any deferred visual work**

List the changed files, test evidence, and the next-round items intentionally left out: full record filtering, media health states, taxonomy persistence, and comprehensive surface/typography redesign.
