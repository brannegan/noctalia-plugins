# Niri Windows Icons

A bar widget that shows icons of windows **only the workspace you are on**

Noctalia's built-in workspaces widget renders only workspace information without any
windows. 

## Plugin

| Field | Value |
| --- | --- |
| ID | `zapp/niri-win-icons` |
| Entries | Bar widget: `win-icons` |

## Requirements

- `niri`. The plugin API exposes no compositor state, so all windows data
  comes from niri's own IPC (`niri msg`). The widget is niri-only and will show
  a placeholder under any other compositor.

## Usage

Add it from **Settings → Bar**, choose a section, and pick **Niri Windows Icons** 
from the widget list. 
The widget shows icons of the active workspace windows, falling back to "?" symbol
for all unknown windows.

| Gesture | Action |
| --- | --- |
| Left click | Focus selected window |

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `win_class` | `string_map` | `table` | Maps window class (app_id) to icon |
| `win_title_match` | `string_map` | `table` | Maps window title (some part) to icon |

## Notes

**Processes.** The widget spawns `niri msg` and nothing else:

- `niri msg --json event-stream` — a single long-lived subscription, the source
  of live updates. Every event rerender widget.
- `niri msg --json windows` — for each event, it gets a list of all windows. Then we filters 
  the windows of the active workspace, and uses that list to render widgets.
- `niri msg action focus-window --id` — only in response to a click.

**No network access. No filesystem reads or writes.** The widget keeps its state
in memory and writes nothing to disk.

