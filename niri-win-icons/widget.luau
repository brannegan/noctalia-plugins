--!nonstrict
-- Niri Windows Icons — a bar widget that shows predefined icons 
-- for active workspace windows.
--
-- Workspace data comes from niri's own IPC:
--   * `niri msg --json event-stream` for live niri events
--   * `niri msg --json windows` for every niri event get opened windows on all workspaces,
--   filter only active workspace windows, then try to map window title or class to icon
--
-- Left click  → focus selected window

local WIN_CLASS: string_map = noctalia.getConfig("win_class") or {}
local WIN_TITLE_MATCH: string_map = noctalia.getConfig("win_title_match") or {}
local RESYNC_MS: number = 60000
local ACTIVE_WS_ID: number = 1

local function pos_compare(a, b)
    local ap = a.layout.pos_in_scrolling_layout
    local bp = b.layout.pos_in_scrolling_layout
    if ap == nil or bp == nil then
        return false 
    end
    if ap[1] ~= bp[1] then
       return ap[1] < bp[1]
    end
    return ap[2] < bp[2]
end

local function title_icon(title: string)
    for pat, icon in pairs(WIN_TITLE_MATCH) do
        if string.find(title, pat, 1, true) ~= nil then
           return icon
        end
    end
    return nil
end

local function render(windows: table)
    local container = barWidget.isVertical() and ui.column or ui.row
    local icons = {}
    for _, window in ipairs(windows) do
        local icon = title_icon(window.title) or WIN_CLASS[window.app_id] or "?"
        table.insert(icons, 
                     ui.button({ text = icon, 
                                 variant = window.is_focused and "default" or "ghost",
                                 tooltip = window.title,
                                 onClick = function() onClick(window.id) end,
                     }))
    end
    barWidget.render(container({ align = "center" }, icons))
end

local function activeWsWindows(id: number)
	noctalia.runAsync("niri msg --json windows", function(res)
		if res.exitCode ~= 0 then
			return
		end
		local all_windows = noctalia.json.decode(res.stdout)
		if type(all_windows) == "table" then
            local ws_windows = {}
            for _, window in ipairs(all_windows) do
                if window.workspace_id == id then
                    table.insert(ws_windows, window)
                    table.sort(ws_windows, pos_compare)
                end
            end
            render(ws_windows)
		end
	end, 3000)
end

local function onNiriEvent(line: string)
	local ev = noctalia.json.decode(line)
	if type(ev) ~= "table" then
		return
	end
	if ev.WorkspaceActivated ~= nil then
		local active_ws = ev.WorkspaceActivated
        ACTIVE_WS_ID = active_ws.id
	end
    activeWsWindows(ACTIVE_WS_ID)
end

noctalia.runStream("niri msg --json event-stream", onNiriEvent)

function update()
	noctalia.setUpdateInterval(RESYNC_MS)
    activeWsWindows(ACTIVE_WS_ID)
end

function onClick(window_id: number)
	noctalia.runAsync("niri msg action focus-window --id "..window_id)
end
