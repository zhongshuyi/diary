# Mobile profile workspace design

**Date:** 2026-09-20
**Status:** Implemented and verified.

## Purpose

The mobile **我的** tab is a personal diary workspace: a calm place to return to saved moments, organize them, care for their storage, and adjust the app. It is neither a social profile nor a data-status dashboard.

The redesign fixes two navigation problems without introducing unnecessary screens:

- sync is currently buried in 偏好设置 while backup/restore is elsewhere;
- content tools, data maintenance, and application preferences do not have clear, non-overlapping meanings.

## Scope and constraints

- Mobile profile navigation and the mobile settings grouping only. The desktop workspace remains as it is.
- Existing diary, favorite, media, insight, category/tag, recycle-bin, backup/restore, conflict, sync, theme, reminder, and biometric-lock behavior stays intact.
- Sync, backup, and restore remain explicit user actions. No automatic upload, export, restore, or account requirement is added.
- Keep the original profile banner layout at the top of the page. Its left avatar supports local selection and reset; the stored avatar is device-only and excluded from diary sync and backup.

## Information architecture

The profile page uses purpose-based groups, ordered by everyday frequency rather than technical importance:

```text
头像与个人摘要
├─ 回看
│  ├─ 收藏夹
│  ├─ 媒体库
│  └─ 洞察
├─ 整理
│  ├─ 分类与标签
│  └─ 回收站
├─ 数据
│  ├─ 同步
│  └─ 备份与恢复
├─ 应用
│  └─ 偏好设置
└─ 关于此刻
```

This makes **同步** and **备份与恢复** equally shallow, visible rows in the same group. They are not promoted ahead of reading and organizing diary content.

The former large profile banner and two large count cards are removed. A compact summary in the header replaces them so the first groups are available with less scrolling.

## Profile header and avatar

Keep the original profile header rather than replacing it with a compact identity block:

```text
A QUIET PLACE FOR YOU
我的空间
管理你的记录、偏好与私人边界。

[ rounded avatar ]  写给自己的日记
                   先保存在本机 · 可按设置同步
```

- Keep the original banner's colors, text, spacing, and rounded avatar position. Tapping the avatar offers **从相册选择** and, when a local image is set, **恢复默认头像**.
- Copy a selected image into app-owned profile-avatar storage before saving its local path. A missing or unreadable file falls back to the default icon without crashing the profile page.
- Sync status is not a primary action in the header; the **同步** row in 数据 is the interactive destination. A nickname is out of scope.
- **偏好设置 → 记录与对话** provides a persisted **显示头像** switch. It defaults to on and controls whether the same local avatar appears beside outgoing chat messages; it does not affect the profile banner.

## Group details

### 回看

Contains the existing content-returning tools in this order:

1. **收藏夹** — preserves its live favorite count.
2. **媒体库** — preserves its photo, video, and voice browsing behavior.
3. **洞察** — preserves its local diary and mood summaries.

### 整理

1. **分类与标签** — taxonomy maintenance for existing diary entries.
2. **回收站** — preserves the current pending-item count and recovery flow. It belongs here because it is part of maintaining and restoring diary content, not a general application preference.

### 数据

1. **同步** — a direct row to the existing connection/settings destination. The subtitle reflects the current state: `本地优先 · 未连接服务器`, `同步中`, `已同步`, `待同步`, `同步失败`, or `有同步冲突`. If conflicts exist, include their count in the subtitle and retain the existing conflict-resolution route from that destination.
2. **备份与恢复** — a direct row to the existing JSON export/import destination. Its subtitle remains clear about saving or migrating diary data.

Both rows are always visible and sit at the same navigation depth. There is no immediate-sync button, data-status card, warning banner, or extra data-center page in this iteration. Failure and conflict colors are confined to the sync row; a local-only state remains neutral.

### 应用 and 关于

- **偏好设置** retains only application behavior: theme and color, reading size, editor and chat defaults, quick-capture placement, biometric lock, and daily reminders.
- Remove the current sync/connection entry and temporary-cache operation from mobile 偏好设置. Sync is reached from 数据; cache cleanup moves into the existing sync/settings destination below connection controls.
- **关于此刻** remains a final standalone row with version, design, and privacy information.

## Implementation boundaries

- `ProfilePage` renders the original banner plus the new group ordering. It receives existing callbacks, live sync state, and avatar actions; it does not read repositories or write preferences itself.
- `MobileDiaryShell` forwards the current `SyncState`, sync destination callback, and avatar values/actions from `DiaryShell`.
- `ProfileAvatarStore` copies selected files into app-owned storage and removes only its own prior avatar files. `DiarySettings` persists the nullable local path and the chat-avatar visibility preference with backward-compatible defaults.
- Extract the existing private connection-settings page into a reusable public sync/settings destination, preserving endpoint/token configuration, copy/paste/import behavior, and current error handling.
- Mobile `SettingsPage` is preference-only after the move. Desktop layout is not restructured by this change.

## Errors, privacy, and accessibility

- All rows remain semantic buttons with title, subtitle, and state/count where relevant.
- The avatar exposes an accessible **编辑头像** action; picker or file failures leave the currently saved avatar untouched and show one concise error message.
- The page remains scrollable at large system font sizes; header text and group subtitles wrap rather than overlap or truncate actions.

## Tests

Add or update tests to cover:

1. Mobile group ordering, exact reachable rows, and the removal of the old large count cards.
2. Sync and backup/restore both being direct, visible rows in 数据; sync is absent from mobile 偏好设置.
3. Local-only, syncing, pending, synced, failed, and conflict sync subtitles, including conflict count.
4. Existing favorite/media/insight/category/recycle/settings/about callbacks remaining connected after relocation.
5. Avatar persistence, replacement, reset, and the original banner's avatar action.
6. The visible **显示头像** preference plus enabled/disabled avatar rendering beside chat messages.
7. Narrow and large-text mobile layouts preserving access to all groups.

## Non-goals

- No user account, login, nickname, online profile, avatar sync, avatar backup export, or social features.
- No desktop information-architecture change.
- No new sync provider, automatic backup, or change to the backup format.
