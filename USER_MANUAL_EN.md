# Script Screen — User Manual

## Table of Contents

1. [Overview](#1-overview)
2. [Getting Started](#2-getting-started)
3. [Application Layout](#3-application-layout)
4. [Project Management](#4-project-management)
5. [Script Summary](#5-script-summary)
6. [Cards (Scenes)](#6-cards-scenes)
7. [Roles (Characters)](#7-roles-characters)
8. [Locations](#8-locations)
9. [Details](#9-details)
10. [Action Times](#10-action-times)
11. [The Script Editor](#11-the-script-editor)
12. [Filtering](#12-filtering)
13. [Keyboard Shortcuts & Mouse Controls](#13-keyboard-shortcuts--mouse-controls)
14. [Data & File Storage](#14-data--file-storage)
15. [Application Settings (`app_settings.json`)](#15-application-settings-app_settingsjson)

---

## 1. Overview

**Script Screen** is a screenplay writing and organization tool built around the concept of visual plot cards. Each scene is represented as a card on a board, and its place in the structure is set by the card's own **Index** attribute. Cards are linked to characters, locations, story details, and time periods, giving you a bird's-eye view of your script's structure alongside a full-featured text editor for writing scene content.

**Core concepts:**

| Term | Meaning |
|---|---|
| **Project** | The top-level container holding all script data (name, version, authors) |
| **Script** | The screenplay itself — title page, logline, synopsis, and scene body text |
| **Card (scene)** | A single scene: has an index number, title, description, and tagged attributes |
| **Role** | A character or person who appears in the script |
| **Location** | A place where scenes take place |
| **Detail** | A story element, motif, or prop that connects scenes |
| **Action Time** | A time period or temporal marker (e.g. "Morning", "Three days later") |

---

## 2. Getting Started

### Installation

Script Screen is distributed as a single archive for Linux, Windows and macOS.
Unpack it and run the install script for your platform — the installer also sets
up the components needed for audio transcription (whisper.cpp speech models and
ffmpeg). Everything is installed under your user account; no administrator rights
are required for the application itself.

For full step-by-step installation, uninstallation and troubleshooting
instructions, see **[DISTRIBUTION.md](DISTRIBUTION.md)** (the same guide is also
included inside each archive as `INSTALL.md`, with a Russian version in
`INSTALL.ru.md`).

| Platform | Install command |
|---|---|
| Linux  | `./install.sh` |
| macOS  | double-click `install.command` (or `./install.command`) |
| Windows | right-click `install.ps1` ▸ **Run with PowerShell** |

> **Transcription requirements:** the [Audio Transcription](#audio-transcription)
> feature relies on whisper.cpp and its speech models installed to `~/whisper.cpp`.
> The installer places these for you; if transcription fails, verify that folder
> exists (see the troubleshooting section of DISTRIBUTION.md).

### Creating a New Project

1. Open the app. The **Project** panel is shown by default.
2. Open the menu (top-right) and choose **New Project**.
3. In the dialog, enter:
   - **Name** — alphanumeric characters, underscores (`_`), hyphens (`-`), and dots (`.`) only.
   - **Version** — version string for the project (e.g. `1.0`).
4. Confirm. The new project is created and ready to use.

### Opening an Existing Project

1. In the **Project** panel menu, choose **Open Project**.
2. Browse to and select the project's `.json` file.
3. The project loads, restoring all cards, roles, locations, details, and action times.

> **Tip:** The app remembers the last opened project and reloads it automatically on the next launch.

### Saving

The project is saved automatically at a configurable interval (auto-save). You can also trigger a save by performing any project operation (New, Open, Export). There is no manual "Save" button needed during normal editing.

---

## 3. Application Layout

The bottom navigation bar gives access to seven panels:

| Icon | Panel | Purpose |
|---|---|---|
| Briefcase | **Project** | Project metadata and file operations |
| Summarize | **Script** | Title page, logline, and synopsis |
| Dashboard | **Cards** | Visual board of plot cards |
| Theater mask | **Roles** | List of characters |
| Door/Room | **Locations** | List of locations |
| Bookmark | **Details** | List of story details |
| Clock | **Action Times** | List of time periods |

---

## 4. Project Management

Access from the **Project** panel.

### Fields

| Field | Description |
|---|---|
| **Name** | Unique project identifier (alphanumeric, `_`, `-`, `.`) |
| **Version** | Project version string |
| **Language** | Language setting used for audio transcription |
| **Author(s)** | One or more author names associated with the project |

### Menu Actions

- **New Project** — Create a fresh project (clears current data after save).
- **Open Project…** — Load a project from a `.json` file.
- **Edit Project** — Change the project name, version, language, or authors.
  Changing the **name and/or version** does not overwrite the current project:
  on the next save a **new copy** is created — a new project `.json` file and a
  new directory under the new name/version — and all files from the previous
  project directory are copied into it. The original project is left untouched,
  so each name/version is preserved as a separate version of the script. Changing only the
  **language or authors** updates the existing project in place.
- **Import File…** — Load a marked up text file into the project, see
  "[Importing Marked Up Text](#importing-marked-up-text)".
- **Export Project** — Export the script to PDF format. The descriptions of the
  roles, locations, details and action times are written into the text at the
  first appearance of the object, see "[Object References in the
  Text](#object-references-in-the-text)".
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

> **About** and **Exit** are available from the menu of every panel.

### Importing Marked Up Text

**Import File…** brings a script prepared outside the application into the
current project. Export the text from any editor to a plain text file (`.txt`),
mark it up with the tags below and pick that file in the dialog.

The import creates new cards along with the roles, locations, details and action
times the project is missing; the text of a fragment goes to the content file of
its card. The new cards are appended after the existing ones, nothing is
replaced. On success the project is saved.

#### Markup Tags

| Tag | Meaning |
|---|---|
| `<text> </text>` | The fragment bounds: one fragment makes one card. The other tags are meaningful inside a fragment only, and text outside `<text>` is not imported. |
| `<title> </title>` | The card title. One fragment, one title: the first one wins, the rest are ignored. The title is required. |
| `<desc> </desc>` | The card description. The first one wins, the rest are ignored. |
| `<role> </role>` | A role name. Any number per fragment; the name is the identifier, so a repeated name counts once. |
| `<loc> </loc>` | A location name. See `<role>`. |
| `<det> </det>` | A detail name. See `<role>`. |
| `<time> </time>` | An action time name. See `<role>`. |
| `<role_desc> </role_desc>` | The description of a role. Written **inside** the `<role>` tag; outside it the tag means nothing and is reported as a markup error. One description per object: the first one wins, the rest are ignored. |
| `<loc_desc> </loc_desc>` | The description of a location, inside the `<loc>` tag. See `<role_desc>`. |
| `<det_desc> </det_desc>` | The description of a detail, inside the `<det>` tag. See `<role_desc>`. |
| `<time_desc> </time_desc>` | The description of an action time, inside the `<time>` tag. See `<role_desc>`. |

The title and the description are kept out of the card content: they are already
shown on the card and, when exporting to PDF, in the scene header. The names
marked with `<role>`, `<loc>`, `<det>` and `<time>` stay where they are written,
so the sentences are imported as they are, and become references to the project
objects, see "[Object References in the Text](#object-references-in-the-text)".

The description of an object, on the contrary, is taken out of the card text: it
belongs to the object and goes to its **Description** field:

```text
<role>Kirill<role_desc>33, a failed businessman dressed in crumpled clothes</role_desc></role> enters the room and sits down at the table.
```

makes the role "Kirill" described as "33, a failed businessman dressed in
crumpled clothes" and the card text "Kirill enters the room and sits down at the
table.". Exporting to PDF writes the description back into the text at the first
appearance of the object, see "[Object References in the
Text](#object-references-in-the-text)".

> When the object is already in the project and its description is **filled in**,
> the import keeps it and the description written in the text is ignored. An
> empty description is filled in.

> A name is taken exactly as it stands between the tags, so mark up the form you
> want to see in the list: "in the <loc>kitchens</loc>" adds the location
> "kitchens", not "kitchen", and the same name written differently becomes
> another location.

#### Example

```text
Anything outside the text tag is not imported:
notes, production marks, separators.

<text>
<title>1. Kitchen. Morning</title>
<desc>Anna finds the letter</desc>
<loc>Kitchen<loc_desc>cramped, the window looks into the yard</loc_desc></loc>. <time>Morning</time>.

<role>ANNA<role_desc>28, the daughter of the house owner</role_desc></role> enters and finds a <det>letter</det> on the table.
</text>
```

This fragment makes a card titled "1. Kitchen. Morning", described as "Anna
finds the letter", with the location "Kitchen" (described as "cramped, the
window looks into the yard"), the action time "Morning", the role "ANNA"
(described as "28, the daughter of the house owner"), the detail "letter" and
the content:

```text
Kitchen. Morning.

ANNA enters and finds a letter on the table.
```

#### The Import Is All or Nothing

The file is parsed in full before the project is touched. On any markup error
the project is left exactly as it was before the import and the message points
at the line at fault. These count as errors:

- an unclosed or nested `<text>` tag;
- a closing tag without an opening one;
- a tag left unclosed inside a fragment;
- a fragment without a `<title>`;
- an empty `<title>`, `<role>`, `<loc>`, `<det>` or `<time>` value;
- a description tag (`<role_desc>` and the rest) outside the tag of the object
  it describes.

---

## 5. Script Summary

Access from the **Script** panel.

This panel holds the screenplay's front matter — information that appears before the scenes.

| Field | Description |
|---|---|
| **Title** | Screenplay title (shown on the title page) |
| **Author** | Author name on the title page (inherited from project authors) |
| **Date** | Date on the title page |
| **Place** | Production place or city |
| **Logline** | One-sentence summary of the screenplay (≈ 25 words) |
| **Synopsis** | Longer overview of the screenplay (up to ~5 pages) |

### Menu Actions

- **Edit Script Summary** — Edit the title, author, date, place, logline, and synopsis.
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

---

## 6. Cards (Scenes)

Access from the **Cards** panel. This is the main working panel.

### The Board

The board displays all your scenes as index cards arranged in a grid, four per row, in ascending order of their index. The order of the cards on the board *is* the order of the scenes in the script: to move a scene, change its **Index** in the card form (see "Card Structure") and the board rearranges itself.

### Navigating the Board

- **Zoom in / out** — Scroll the **middle mouse wheel** up to zoom in and down to zoom out.
- **Pan (move the whole board)** — Press and **hold the left mouse button on an empty area** of the board and drag. All cards move together so you can reach any part of it.

> Holding the left button on a **card** moves that card; holding it on **empty space** pans the board.

### Anatomy of a Card

Each card shows:
- **Index** — The scene's position in the script and therefore the card's place on the board (editable).
- **Title / Description** — A brief description of the scene.
- **Attribute chips** — Roles, locations, details, and action times tagged to this scene.

### Creating a Card

**Shift + Click** anywhere on the empty board to create a new scene card at that position.

A form opens on the right (or below the board) where you fill in:

| Field | Description |
|---|---|
| **Index** | Scene number (positive integer ≥ 1). Determines the order of scenes in the script, the card's position on the board and the scene order in the PDF. Changing the index of an existing card moves it to its new place. |
| **Title** | Short name for the scene. |
| **Description** | Brief description shown on the card. |
| **Roles** | Characters present in this scene (multi-select). |
| **Locations** | Where the scene takes place (multi-select). |
| **Details** | Story elements or motifs in this scene (multi-select). |
| **Action Times** | Time period of the scene (multi-select). |

### Editing a Card

- Click the **pencil icon** on a card to open its edit form, **or**
- Click the card to select it — the form appears automatically.

Make changes in the form. Changes are saved when you move to another card or deselect.

### Deleting a Card

Click the **X icon** on a card. The card and its associated scene content file are permanently removed.

### Moving and Resizing Cards

- **Move**: Drag a card by its header/body to reposition it on the board.
- **Resize**: Drag the bottom-right corner handle of a card.

> **This is a temporary change to the view.** Card position and size are not stored
> in the project: on any board refresh (adding or deleting a card, saving the
> project, changing the filter, right-clicking the board, reopening the project)
> cards return to the four-per-row grid in index order. To change the structure for
> good, edit the card's **Index** rather than its position on the board.

### Selecting and Deselecting

- **Select**: Click a card. Its border turns **pink** and its content loads into the editor.
- **Deselect**: Click the selected card again. The border returns to the default color and the editor content is saved and cleared.

Only one card can be selected at a time.

### Filtering Cards

Each card displays attribute chips for its **Roles**, **Details**, **Locations**, and **Action Times**. Clicking a chip turns it into a filter so you can focus on a subset of scenes.

- **Activate a filter** — Click any attribute chip on a card. The chip becomes highlighted and only the matching cards stay visible; all other cards are hidden from the board.
- **Combine filters** — Click additional chips to add more attributes to the filter. A card stays visible if it matches **any** of the active attributes (OR logic), not all of them.
- **Clear a filter** — Click a highlighted chip again to remove that attribute from the filter. When no chips are active, every card is shown.

> The visibility filter matches a card against all of its attributes — **Roles**, **Details**, **Locations**, and **Action Times**.

See [Filtering](#12-filtering) for the full description.

### Audio Transcription

A scene card must be **selected** first — the transcribed text is inserted into that scene's editor content. The project's language setting is used for transcription.

- **Transcript Audio File…** — Transcribe an existing audio file (MP3, WAV, M4A) into the selected scene. (Disabled until a card is selected.)
- **Start Live Transcription** — Begin transcribing speech from the microphone in real time, appending text to the selected scene as you speak.
- **Stop Live Transcription** — Stop an in-progress live transcription. (This menu item replaces *Start Live Transcription* while transcription is running.)

### Menu Actions

- **Transcript Audio File…** — Transcribe an audio file into the selected scene (enabled only when a card is selected).
- **Start / Stop Live Transcription** — Toggle real-time microphone transcription into the selected scene.
- **Show / Hide Editor** — Toggle the rich-text script editor window (see [The Script Editor](#11-the-script-editor)).
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

---

## 7. Roles (Characters)

Access from the **Roles** panel.

### Menu Actions

- **Add Role** — Create a new character (opens the add form).
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

### Adding a Role

1. Open the menu and choose **Add Role**.
2. Fill in:
   - **Name** (required) — Character name.
   - **Description** (optional) — Notes about the character.
3. Confirm.

### Editing and Deleting

The edit and delete buttons are hidden behind the list item — the way they are
in the lists on an iPhone or an iPad.

1. Click the list item to **select** it — its border turns pink and the form
   with its fields opens on the right (read-only for now).
2. **Drag the selected item to the left** with the mouse — two buttons appear
   next to it: **Edit** and **Delete**.
3. **Edit** — the fields of the form on the right side of the panel become
   editable. Make the changes and confirm.
4. **Delete** — the item is removed from the project.

> Only a selected item can be dragged: until it is selected the buttons do not appear.

> Deleting a role removes it from all scene cards that reference it.

---

## 8. Locations

Access from the **Locations** panel.

### Menu Actions

- **Add Location** — Create a new location (opens the add form).
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

### Adding a Location

1. Open the menu and choose **Add Location**.
2. Fill in:
   - **Name** (required) — Location name.
   - **Description** (optional) — Notes about the location.
3. Confirm.

### Editing and Deleting

Same as Roles: select the list item, drag it to the left and press **Edit** or
**Delete**, see "[Roles](#7-roles-characters)".

---

## 9. Details

Access from the **Details** panel.

Details represent recurring story elements, motifs, props, or narrative threads that link scenes together.

### Menu Actions

- **Add Detail** — Create a new detail (opens the add form).
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

### Adding a Detail

1. Open the menu and choose **Add Detail**.
2. Fill in **Name** (required) and **Description** (optional).
3. Confirm.

### Editing and Deleting

Select the list item, drag it to the left and press **Edit** or **Delete**, see
"[Roles](#7-roles-characters)".

---

## 10. Action Times

Access from the **Action Times** panel.

Action times are temporal markers that describe *when* a scene takes place (e.g., "Morning", "Night", "Three days later", "Flashback").

### Menu Actions

- **Add Action Time** — Create a new action time (opens the add form).
- **About** — Show the application version and third-party license information.
- **Exit** — Save and close the application.

### Adding an Action Time

1. Open the menu and choose **Add Action Time**.
2. Fill in **Name** (required) and **Description** (optional).
3. Confirm.

### Editing and Deleting

Select the list item, drag it to the left and press **Edit** or **Delete**, see
"[Roles](#7-roles-characters)".

---

## 11. The Script Editor

The editor is a rich text editor (TinyMCE) that opens in a separate webview window alongside the board.

### Showing and Hiding the Editor

In the **Cards** panel menu, choose **Show Editor** or **Hide Editor** to toggle the editor window.

### Switching Between the Windows

**F2** — or **Ctrl+Shift+E**, on the keyboards where F2 only works together with
**Fn** — moves the focus from the application window to the editor window and
back. When the editor window is hidden, the first press shows it. Both shortcuts
do the same thing and work in either window.

### How the Editor Works

- When a scene card is **selected**, that scene's content loads into the editor.
- Write and format the scene body in the editor.
- When you **select a different card**, the current content is **saved automatically** before the new scene loads.
- When you **deselect** a card, content is saved and the editor clears.
- When you **delete** a card, its content file is deleted permanently.

### Object References in the Text

Roles, locations, details and action times may be marked in the scene text
itself. Such a reference is underlined with a dashed line; point at it and the
description of the object shows up. An object without a description shows
nothing.

The application keeps the marks itself, they follow what the card refers to:

- as soon as an object is attached to a card, its name met in the text of that
  card becomes a reference;
- when the object is taken from the card, the references to it are dropped from
  the text of that card; when the object is deleted from its list, from the text
  of every card;
- when the object is renamed, the chips and the references to it in every card
  take the new name;
- the text is synced with the attached objects when the card is opened in the
  editor and when the project is exported, so a name typed after the object was
  attached becomes a reference as well;
- the import writes the references right away from the `<role>`, `<loc>`,
  `<det>` and `<time>` tags, inflected forms included, see "[Importing Marked Up
  Text](#importing-marked-up-text)".

A name is matched as a whole word, ignoring the case, and the longer of two
matching names wins. An inflected form is not matched this way — the import is
the place for those, and such a reference is kept as long as the object stays
attached to the card.

A reference holds the type and the name of the object only, the description
itself is taken from the project, so an edited description shows up at once. The
text you wrote is left as it is.

Renaming an object reaches the cards it is attached to: the chip of the card and
the references in its text start pointing at the new name. The words you wrote
are left as they are — a reference keeps the word it is written over.

Exporting to PDF drops the markup and writes the description of the object into
the text at its first appearance:

```text
...Kirill (33, a failed businessman dressed in crumpled clothes) enters the
room and sits down at the table...
```

At the next appearances of the same object, in every other scene as well, the
description is not repeated.

### Formatting

The TinyMCE editor provides standard rich text formatting:

- **Bold**, *italic*, underline
- Headings (H1–H6)
- Bulleted and numbered lists
- Paragraph styles

---

## 12. Filtering

On the **Cards** board, you can filter which cards are visible by clicking the attribute chips shown on each card.

### How to Filter

1. Look at the attribute chips displayed on any card (Roles, Details, Locations, Action Times).
2. Click a chip to activate that filter. The chip becomes highlighted.
3. Only cards **tagged with that attribute** remain visible; the rest are hidden.
4. Click the chip again to deactivate the filter.

Multiple filters can be active at once. A card is shown if it matches **any** of the active filters (OR logic).

> The chips on a card are all of one width, so a long name is cut with an ellipsis. To read it in full, hover over the chip — the whole name appears in a tooltip.

> **Which attributes filter:** The visibility filter is applied against all of a card's attributes — **Roles**, **Details**, **Locations**, and **Action Times**.

When no chips are active, all cards are visible.

---

## 13. Keyboard Shortcuts & Mouse Controls

| Action | Control |
|---|---|
| Create new scene card | **Shift + Click** on empty board |
| Select a card | **Click** on card |
| Deselect a card | **Click** on selected card |
| Move a card (temporary, until the board refreshes) | **Drag** card body |
| Resize a card (temporary, until the board refreshes) | **Drag** bottom-right corner |
| Move a scene for good | Change **Index** in the card form |
| Zoom board in / out | **Middle mouse wheel** scroll up / down |
| Pan (move the board) | **Hold left mouse button** on empty board and drag |
| Refresh board view | **Right-click** on board |
| Switch between the application window and the editor window | **F2** or **Ctrl+Shift+E** |
| Reveal the **Edit** / **Delete** buttons of a list item | **Drag the selected list item to the left** |
| Read a chip label that did not fit | **Hover** over the chip |

---

## 14. Data & File Storage

### File Format

Projects are stored as **JSON files** (`.json`). Each project file contains all metadata: cards, roles, locations, details, action times, and script summary.

### Scene Content

The body text of each scene is stored as a separate **HTML file** in the project directory. These files are created and managed automatically.

A reference to an object is kept in that file as `<span class="ref"
data-type="role" data-name="Kirill">Kirill</span>`: the type and the name of the
object only, the description is taken from the project file, see "[Object
References in the Text](#object-references-in-the-text)".

### Project Directory

When a project is created or versioned, a timestamped directory is created to hold all related files. Do not rename or move these files manually.

When you change a project's **name or version** and save, the application creates a new project as a copy: it writes a new `.json` project file under the new name/version and a new directory, then copies every file from the old project's directory into the new one. The previous name/version remains on disk unchanged, so renaming or re-versioning acts as a **"Save As"** rather than an in-place rename.

### Validation Rules

| Field | Rule |
|---|---|
| Project / Script Name | Alphanumeric, `_`, `-`, `.` only |
| Card Index | Positive integer ≥ 1 |
| Name fields (Role, Location, etc.) | Cannot be empty |
| Description fields | Optional |

---

## 15. Application Settings (`app_settings.json`)

Global application settings are stored in **`app_settings.json`**, located in the application's `assets/cfg` directory. The file is read once at startup and a few entries (such as the last opened project) are written back automatically as you use the app. You normally do not need to edit it by hand, but the parameters below let you tune the application's behavior.

> **Note:** Edit this file only while the application is closed, and keep it as valid JSON. An invalid value falls back to a built-in default where one exists.

| Parameter | Type | Example | Description |
|---|---|---|---|
| `app_name` | string | `"scriptscreen"` | Internal application identifier. Used as the logger name and as the prefix for daily log file names. |
| `last_project` | string | `"/home/user/scripts/memoirs_1.0_….json"` | Full path to the most recently opened project. Updated automatically when you create or open a project and reloaded on the next launch. If the file is missing or empty, a new project is created on startup. |
| `language` | string | `"en_US"` | Interface language selected at startup. Resolved to a two-letter code (e.g. `en`, `ru`); an unsupported value falls back to English. |
| `default_autosave` | integer (seconds) | `300` | Interval between automatic saves of the project and scene content. |
| `gui_primary_color` | string | `"green"` | Primary accent color of the interface. Allowed values: `red`, `blue`, `black`, `green`, `yellow`, `amber`, `cyan`, `brown`, `orange`, `purple`, `grey`, `lime`, `pink`. An unknown value falls back to `blue`. |
| `editor_config` | string | `"editor.html"` | File name of the rich-text (TinyMCE) editor configuration loaded for the script editor. |
| `note_header_template` | string | `"header.html"` | HTML template (in `assets/cfg`) used to build scene headers when exporting the script. |
| `log_level` | string | `"INFO"` | Logging verbosity. Allowed values: `ALL`, `OFF`, `FINEST`, `FINER`, `FINE`, `CONFIG`, `INFO`, `WARNING`, `SEVERE`, `SHOUT`. An unrecognized value enables `ALL`. |
| `transcribe_fmt` | string | `"txt"` | Output format produced by the audio transcription service. |
| `whisper_model` | string | `"large-v3-turbo-q8_0"` | whisper.cpp model used for transcribing audio **files**. Must be installed under `~/whisper.cpp`. |
| `whisper_live_model` | string | `"small"` | whisper.cpp model used for **live** microphone transcription. A smaller, faster model is recommended for real-time use. |

---

*Script Screen User Manual — v1.0*
