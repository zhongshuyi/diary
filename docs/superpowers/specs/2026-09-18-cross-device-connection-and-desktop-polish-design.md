# Cross-device Connection Transfer and Desktop Polish Design

## Goal

Let an owner move the private diary connection settings between Windows and
Android with one clipboard operation, correct the packaged Windows taskbar
icon, and make the desktop system-level quick-capture window usable at its
supported sizes.

## Scope

The connection transfer contains exactly three values:

- `syncEndpoint`
- `syncToken`
- `updateEndpoint`

It does not include diary entries, attachments, device identifiers, window
bounds, editor preferences, reminders, or biometric-lock settings. Existing
backup and restore behavior is unchanged.

## Portable Connection Package

The canonical clipboard value is a single line:

```text
DIARY-CONNECTION:v1:<base64url-encoded UTF-8 JSON>
```

The JSON payload is an object with `version: 1` and the three connection
fields. Endpoint values are trimmed and have trailing slashes removed before
encoding and when importing. The token is preserved exactly except for outer
whitespace removed by the settings form.

Both clients will accept the canonical value. They will also accept the raw
JSON object to make recovery and inspection practical. Unsupported versions,
bad Base64URL, invalid JSON, non-string fields, and malformed endpoint values
show an import error and leave the current settings unchanged.

Base64URL is an encoding, not encryption. The package contains the sync token,
so the UI explicitly warns that it is for the owner's trusted devices only.
The package is never sent to the update server, sync server, telemetry, or
application logs.

## Desktop Client

The desktop settings page will show a connection-transfer action beside the
three existing connection fields:

1. **Copy connection configuration** saves the values currently displayed in
   the form, copies the canonical package to the system clipboard, and reports
   success.
2. **Paste and import** reads the system clipboard, validates the package, and
   fills all three form fields. It does not persist or start a sync until the
   user chooses the existing **Save settings** action.

Keeping import as a form-level change prevents a corrupt or accidental paste
from silently changing an active connection. The encoder/decoder will be a
small testable module, and Electron's clipboard access will be exposed through
the existing preload boundary rather than enabling Node access in the renderer.

The Windows taskbar issue is a packaging issue, not a tray issue. A
multi-resolution `.ico` generated from the existing Diary brand logo will be
used as the Windows build icon. Electron Builder will embed it in `Diary.exe`
and its shortcuts, and the main/quick-capture windows retain the same brand
icon at runtime. The tray implementation and its current image are unchanged.

The quick-capture window will receive a `windowed` layout variant. It will use
a 720x600 default and 560x440 minimum size; restored bounds will remain
supported. Its heading stays on one line, the mode/date controls remain
compact, the content editor flexes to fill the available middle region, and
the footer stays visible. The normal modal and inline composer styles are not
changed.

## Android Client

Android's Sync Settings section will add matching **Copy connection
configuration** and **Paste and import** controls. They use Flutter's system
clipboard and exactly the same `DIARY-CONNECTION:v1:` payload. A valid import
updates the three text fields first; the existing **Save connection** button
is still the explicit persistence step. Clipboard errors and validation
failures show a snack bar without overwriting the fields.

## Testing and Verification

- Desktop Node tests cover canonical encoding, raw-JSON import compatibility,
  normalization, rejection of invalid values, and use of the intended Windows
  icon path/build option.
- Flutter unit tests cover encoding and decoding against the same fixtures,
  plus controller-level atomic application of imported connection settings.
- Flutter widget tests cover copy/import affordances and invalid-import
  feedback.
- Desktop tests cover the quick-capture size constraints and the renderer
  build; the Windows installer is inspected after packaging to confirm it
  embeds the branded `.ico` rather than Electron's default icon.

## Non-goals

- Password-encrypting the clipboard payload. Without a shared password or
  account key this would only add false security; a future encrypted format
  can use a new version prefix.
- Changing server APIs, public update behavior, sync authentication, or the
  existing tray menu.
