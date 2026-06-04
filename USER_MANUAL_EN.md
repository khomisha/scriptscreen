# Script Screen — User Manual

## Table of Contents

1. [Overview](#1-overview)
2. [Getting Started](#2-getting-started)
3. [Application Layout](#3-application-layout)
4. [Project Management](#4-project-management)
5. [Script Summary](#5-script-summary)
6. [Notes (Scene Cards)](#6-notes-scene-cards)
7. [Roles (Characters)](#7-roles-characters)
8. [Locations](#8-locations)
9. [Details](#9-details)
10. [Action Times](#10-action-times)
11. [The Script Editor](#11-the-script-editor)
12. [Filtering](#12-filtering)
13. [Keyboard Shortcuts & Mouse Controls](#13-keyboard-shortcuts--mouse-controls)
14. [Data & File Storage](#14-data--file-storage)

---

## 1. Overview

**Script Screen** is a screenplay writing and organization tool built around the concept of visual index cards (Notes). Each scene is represented as a draggable card on a canvas. Cards are linked to characters, locations, story details, and time periods, giving you a bird's-eye view of your script's structure alongside a full-featured text editor for writing scene content.

**Core concepts:**

| Term | Meaning |
|---|---|
| **Project** | The top-level container holding all script data (name, version, authors) |
| **Script** | The screenplay itself — title page, logline, synopsis, and scene body text |
| **Note (Scene Card)** | A single scene: has an index number, title, description, and tagged attributes |
| **Role** | A character or person who appears in the script |
| **Location** | A place where scenes take place |
| **Detail** | A story element, motif, or prop that connects scenes |
| **Action Time** | A time period or temporal marker (e.g. "Morning", "Three days later") |

---

## 2. Getting Started

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
3. The project loads, restoring all notes, roles, locations, details, and action times.

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
| Dashboard | **Notes** | Visual canvas of scene cards |
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
- **Open Project** — Load a project from a `.json` file.
- **Edit Project** — Change the project name, version, language, or authors.
- **Export Project** — Export the script to PDF format.
- **Exit** — Save and close the application.

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

Open the menu and choose **Edit** to modify any of these fields.

---

## 6. Notes (Scene Cards)

Access from the **Notes** panel. This is the main working panel.

### The Canvas

The canvas displays all your scenes as draggable index cards arranged in a grid. You can freely move cards to create a visual structure that mirrors your script's flow.

### Anatomy of a Card

Each card shows:
- **Index number** — The scene's position in the script (editable).
- **Title / Description** — A brief description of the scene.
- **Attribute chips** — Roles, locations, details, and action times tagged to this scene.

### Creating a Note

**Shift + Click** anywhere on the empty canvas to create a new scene card at that position.

A form opens on the right (or below the canvas) where you fill in:

| Field | Description |
|---|---|
| **Index** | Scene number (positive integer ≥ 1). Determines order in the script. |
| **Title** | Short name for the scene. |
| **Description** | Brief description shown on the card. |
| **Roles** | Characters present in this scene (multi-select). |
| **Locations** | Where the scene takes place (multi-select). |
| **Details** | Story elements or motifs in this scene (multi-select). |
| **Action Times** | Time period of the scene (multi-select). |

### Editing a Note

- Click the **pencil icon** on a card to open its edit form, **or**
- Click the card to select it — the form appears automatically.

Make changes in the form. Changes are saved when you move to another card or deselect.

### Deleting a Note

Click the **X icon** on a card. The card and its associated scene content file are permanently removed.

### Moving and Resizing Cards

- **Move**: Drag a card by its header/body to reposition it on the canvas.
- **Resize**: Drag the bottom-right corner handle of a card.

### Selecting and Deselecting

- **Select**: Click a card. Its border turns **pink** and its content loads into the editor.
- **Deselect**: Click the selected card again. The border returns to the default color and the editor content is saved and cleared.

Only one card can be selected at a time.

### Audio Transcription

In the Notes panel menu, choose **Transcript Audio File** to transcribe an audio file (MP3, WAV, M4A) into the selected scene's editor content. The project's language setting is used for transcription.

---

## 7. Roles (Characters)

Access from the **Roles** panel.

### Adding a Role

1. Open the menu and choose **Add Role**.
2. Fill in:
   - **Name** (required) — Character name.
   - **Description** (optional) — Notes about the character.
3. Confirm.

### Editing a Role

Click on a role in the list to open its edit form. Modify the fields and confirm.

### Deleting a Role

Open a role's edit form and use the **Delete** button.

> Deleting a role removes it from all scene cards that reference it.

---

## 8. Locations

Access from the **Locations** panel.

### Adding a Location

1. Open the menu and choose **Add Location**.
2. Fill in:
   - **Name** (required) — Location name.
   - **Description** (optional) — Notes about the location.
3. Confirm.

### Editing / Deleting

Same as Roles: click the item in the list to edit, use **Delete** to remove.

---

## 9. Details

Access from the **Details** panel.

Details represent recurring story elements, motifs, props, or narrative threads that link scenes together.

### Adding a Detail

1. Open the menu and choose **Add Detail**.
2. Fill in **Name** (required) and **Description** (optional).
3. Confirm.

### Editing / Deleting

Click the item in the list to edit or delete.

---

## 10. Action Times

Access from the **Action Times** panel.

Action times are temporal markers that describe *when* a scene takes place (e.g., "Morning", "Night", "Three days later", "Flashback").

### Adding an Action Time

1. Open the menu and choose **Add Action Time**.
2. Fill in **Name** (required) and **Description** (optional).
3. Confirm.

### Editing / Deleting

Click the item in the list to edit or delete.

---

## 11. The Script Editor

The editor is a rich text editor (TinyMCE) that opens in a separate webview window alongside the canvas.

### Showing and Hiding the Editor

In the **Notes** panel menu, choose **Show Editor** or **Hide Editor** to toggle the editor window.

### How the Editor Works

- When a scene card is **selected**, that scene's content loads into the editor.
- Write and format the scene body in the editor.
- When you **select a different card**, the current content is **saved automatically** before the new scene loads.
- When you **deselect** a card, content is saved and the editor clears.
- When you **delete** a card, its content file is deleted permanently.

### Formatting

The TinyMCE editor provides standard rich text formatting:

- **Bold**, *italic*, underline
- Headings (H1–H6)
- Bulleted and numbered lists
- Paragraph styles

---

## 12. Filtering

On the **Notes** canvas, you can filter which cards are visible by clicking attribute chips.

### How to Filter

1. Look at the attribute chips displayed at the top of the Notes panel or on any card.
2. Click a chip (role, location, detail, or action time) to activate that filter.
3. Only cards **tagged with that attribute** remain fully visible.
4. Click the chip again to deactivate the filter.

Multiple filters can be active at once. A card is shown if it matches **any** of the active filters.

---

## 13. Keyboard Shortcuts & Mouse Controls

| Action | Control |
|---|---|
| Create new scene card | **Shift + Click** on empty canvas |
| Select a card | **Click** on card |
| Deselect a card | **Click** on selected card |
| Move a card | **Drag** card body |
| Resize a card | **Drag** bottom-right corner |
| Refresh canvas view | **Right-click** on canvas |

---

## 14. Data & File Storage

### File Format

Projects are stored as **JSON files** (`.json`). Each project file contains all metadata: notes, roles, locations, details, action times, and script summary.

### Scene Content

The body text of each scene is stored as a separate **HTML file** in the project directory. These files are created and managed automatically.

### Project Directory

When a project is created or versioned, a timestamped directory is created to hold all related files. Do not rename or move these files manually.

### Validation Rules

| Field | Rule |
|---|---|
| Project / Script Name | Alphanumeric, `_`, `-`, `.` only |
| Note Index | Positive integer ≥ 1 |
| Name fields (Role, Location, etc.) | Cannot be empty |
| Description fields | Optional |

---

*Script Screen User Manual — v1.0*
