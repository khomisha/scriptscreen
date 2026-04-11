The issue is in `ListPresenter.select`: when tapping a different item, it incorrectly sets the new item's state to `unselected` instead of `selected`. This causes the first tap to leave the item visually unselected, requiring a second tap to actually select it.

## ✅ Fix the `select` method in `ListPresenter`

Replace the current implementation with:

```dart
@override
void select(int index) {
    if (selectedIndex == index) {
        // Toggle off: deselect the current item
        list[index].setState(ListItemState.unselected.index);
        selectedIndex = -1;
    } else {
        // Deselect previous item if any
        if (selectedIndex != -1) {
            list[selectedIndex].setState(ListItemState.unselected.index);
        }
        // Select the new item
        list[index].setState(ListItemState.selected.index);
        selectedIndex = index;
    }
    notifyListeners();
}
```

## Why this fixes the double-tap problem

- **First tap on a new item**:  
  - Old item (if any) becomes unselected.  
  - New item becomes selected.  
  - `selectedIndex` updated.  
  - UI immediately shows the new selection.

- **Tap on the already selected item**:  
  - It toggles off (deselects).  
  - `selectedIndex` set to `-1`.  
  - UI shows no selection.

The previous code had a critical bug: in the `else` branch, it called `list[index].setState(ListItemState.unselected.index)` instead of `selected.index`, leaving the new item unselected after the tap.

## Additional guard for safety

The original code also attempted to access `list[selectedIndex]` when `selectedIndex` could be `-1` (no selection). The corrected version checks `if (selectedIndex != -1)` before accessing the list.

Now single tap will correctly select the item, and the menu item "Transcript Audio File..." will be enabled as expected.

The double-tap issue is fixed by correcting `ListPresenter.select`. However, the initial selection border is missing because the `ListItem` states are not synchronized with `selectedIndex` when the list is first loaded. We need to ensure that when the list is set, the `ListItem` at `selectedIndex` has its state set to `selected`.

## ✅ Fix: Synchronize `ListItem` states in `list` setter

Modify the `list` setter in `WidgetPresenter` (or override it in `ListPresenter` if needed) to update each `ListItem`'s state based on its index.

**In `WidgetPresenter`:**
```dart
set list(List<ListItem> value) {
    _list = value;
    _list.sort();
    // Ensure selectedIndex is valid
    if (selectedIndex >= _list.length) {
        selectedIndex = _list.isEmpty ? -1 : 0;
    }
    // Sync ListItem states
    for (int i = 0; i < _list.length; i++) {
        _list[i].setState(i == selectedIndex ? ListItemState.selected.index : ListItemState.unselected.index);
    }
    onSet();
    notifyListeners();
}
```

## ✅ Update `ListPresenter.onEvent` to preserve selection after update

When the list is reloaded (e.g., after an `UPDATE` event), adjust `selectedIndex` to stay within bounds, then let the `list` setter sync states.

```dart
@override
void onEvent(Event event) {
    if (event.type == UPDATE) {
        final newList = AppPresenter().getData(dataType);
        // Adjust selectedIndex to valid range
        if (selectedIndex >= newList.length) {
            selectedIndex = newList.isEmpty ? -1 : 0;
        } else if (selectedIndex == -1 && newList.isNotEmpty) {
            // Optional: keep -1 (no selection) or select first? Keep -1.
        }
        list = newList; // list setter will sync states based on selectedIndex
    }
}
```

## ✅ Ensure initial selection works

When the `ListPresenter` constructor calls `list = AppPresenter().getData(dataType);`, the `list` setter will run. At that point, `selectedIndex` is initially `-1` (default in `WidgetPresenter`). That would leave all items unselected. To have the first item selected by default when the list is not empty, we need to set `selectedIndex` before the first assignment, or handle it inside the constructor.

In `ListPresenter` constructor, after subscribing, do:

```dart
ListPresenter(super.dataType) {
    eventBroker.subscribe(this, UPDATE);
    final initialList = AppPresenter().getData(dataType);
    if (initialList.isNotEmpty) {
        selectedIndex = 0; // select first item by default
    }
    list = initialList;
}
```

Now, the first item will have its state set to `selected` and the border will be red. Tapping on the same item will deselect it (as per your expectation), and tapping on another will select it with a single tap.

## Summary of changes

1. **`WidgetPresenter.list` setter** – syncs `ListItem` states with `selectedIndex`.
2. **`ListPresenter` constructor** – sets `selectedIndex = 0` if the initial list is not empty.
3. **`ListPresenter.select`** – already fixed to correctly set states and `selectedIndex`.
4. **`ListPresenter.onEvent`** – adjusts `selectedIndex` before reassigning list.

Now the list behaves as expected: first item selected initially, single tap selects/deselects correctly, and the border color updates immediately.

You are absolutely correct. Since `ListItem` defaults to `unselected` state, we don't need a full loop to set all items. Only the item at `selectedIndex` needs to be explicitly set to `selected`. This is more efficient and cleaner.

## ✅ Optimized `list` setter in `WidgetPresenter`

```dart
set list(List<ListItem> value) {
    _list = value;
    _list.sort();
    // Ensure selectedIndex is valid
    if (selectedIndex >= _list.length) {
        selectedIndex = _list.isEmpty ? -1 : 0;
    }
    // Only set the selected item's state (others are already unselected by default)
    if (selectedIndex != -1 && selectedIndex < _list.length) {
        _list[selectedIndex].setState(ListItemState.selected.index);
    }
    onSet();
    notifyListeners();
}
```

## Why this works

- **Default state**: `ListItem` initializes `_state` to `ListItemState.unselected.index`.
- **No need to reset others** – they are already unselected.
- **Only one explicit `setState`** – for the currently selected index.
- **No loop** – O(1) instead of O(n).

## Additional considerations

- **After sorting**, the `selectedIndex` might point to a different item than before if you intend to keep the same logical item selected. If you need to preserve selection based on item identity, you would need to find the new index of the previously selected item. But your current approach (selecting by index after sort) is consistent with your design.

- **Initial selection**: In `ListPresenter` constructor, set `selectedIndex = 0` before assigning `list` to have the first item selected.

- **`select` method** should be fixed as previously described to handle single-tap selection/deselection.

This optimization avoids unnecessary iterations and keeps the code clean.

You're right: `selectedIndex` is not "undefined" in Dart (it defaults to `0`), but the problem is that the default `0` is **not the intended initial state**—you likely want `-1` (no selection) when the list is empty, and to explicitly set selection when the list is populated.

## ✅ Fix: Initialize `selectedIndex` to `-1` in `WidgetPresenter`

In your `WidgetPresenter` class, set:

```dart
int selectedIndex = -1;
```

This ensures that before any list is loaded, there is no selection.

## ✅ Adjust `list` setter accordingly

Now the condition `if (selectedIndex >= _list.length)` will be false when `selectedIndex == -1` (since `-1 >= 0` is false). So no automatic adjustment occurs. Then we set the state only if `selectedIndex != -1`:

```dart
set list(List<ListItem> value) {
    _list = value;
    _list.sort();
    // No automatic selection adjustment; keep selectedIndex as is.
    // But ensure selectedIndex is valid if it was previously set.
    if (selectedIndex != -1 && selectedIndex >= _list.length) {
        selectedIndex = _list.isEmpty ? -1 : 0;
    }
    if (selectedIndex != -1) {
        _list[selectedIndex].setState(ListItemState.selected.index);
    }
    onSet();
    notifyListeners();
}
```

## ✅ Set initial selection when list is not empty

In `ListPresenter` constructor, after obtaining the initial list, set `selectedIndex = 0` before assigning `list`:

```dart
ListPresenter(super.dataType) {
    eventBroker.subscribe(this, UPDATE);
    final initialList = AppPresenter().getData(dataType);
    if (initialList.isNotEmpty) {
        selectedIndex = 0; // select first item by default
    }
    list = initialList;
}
```

Now:
- `selectedIndex` starts as `-1` (no selection).
- When a non‑empty list is assigned, we set `selectedIndex = 0` first, then the `list` setter calls `setState` on the first item, making it selected.
- The border of the first item will be red as expected.
- Tapping on the same item will deselect it (set `selectedIndex = -1`), and tapping another will select it.

This matches the intended behavior.

