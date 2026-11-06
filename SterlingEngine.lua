--[[
    STERLING ENGINE EXCLUSIVE   (v7)
    LocalScript. Только интерфейс - никаких Aimbot/Cheat функций.

    ЧТО НОВОГО В v7
      * Panel: Owners принимает UserId (число или строка) И username. Вкладка Panel
        создаётся всегда и показывается только владельцу (Window:SetOwner(true) - принудительно).
      * Owner Announcement: сообщение показывается в меню И по центру сверху экрана
        ("Sterling Engine | Owner Message", аватар, ник, OWNER + EXCLUSIVE, время).
        Длительность: секунды / минуты / часы / "Until next hour" (ровно до XX:00).
      * Темы: Smoky Dark, Obsidian, Frost Gray, Crimson, SPOOKY (Halloween).
        У каждой темы своя палитра и своё переливание рамки с пульсацией (всегда с белым).
      * Иконки: Lucide (чёрно-белые, красятся под тему) вместо символов. Если иконки не
        загрузились - используются запасные символы.
      * Finder: Egg Finder по всем серверам (Ethereal / Admin). Модель, название, Rarity,
        Mutation, Traits, вес, время спавна и кнопка Join. Яйцо исчезло - пропало из списка.
      * Scripters Chat -> Global Live Chat. Copy Join Script удалён.
      * Forum сохраняется (SterlingEngine/forum.json, либо память, если нет writefile).

    ОБЪЕДИНЁННАЯ ВЕРСИЯ: меню (v7) + функции из SterlingEngineFunctions.
      Main        - Speed, Auto Volcanic Dip, World ESP, список яиц (Fly / Instant / Steal)
      Automation  - Safe Steal, Auto Collect Egg, Auto Sky Race, Halloween Event
      Pets        - Ride Best Pet, Go to Heaven Area
      Misc        - Instant PickUp, Notification, Steal History
      Performance - Low Graphics / Reduce Effects (бывшие FPS Boost / Anti Lag) + уровни 1-5
      Функции стартуют выключенными. Код функций - в блоке InstallFunctions в конце файла.

    ПК:      RightShift - показать/скрыть (меняется во вкладке Keybind)
    Телефон: окно масштабируется под экран, кнопка "SE" открывает меню
    "-" и "X" только СКРЫВАЮТ меню (ничего не удаляется)

    ДЛЯ EGG FINDER НУЖЕН ИСТОЧНИК ДАННЫХ (клиент Roblox сам не видит другие серверы):
      Options.EggFeedUrl = "https://your-api/eggs"   -- JSON: { "eggs": [ {...}, {...} ] }
      Options.FetchEggs  = function() return { {...} } end   -- или свой Lua-источник
      Формат яйца: { id, jobId, placeId, name, rarity, mutation, traits = {"A","B"},
                     weight (кг), spawnedAt (unix, сек) }
      Яйца текущего сервера сканируются сами (Model с "egg" в имени и атрибутом Rarity).
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sterling = {}

-- ============================================================================
-- ТЕМЫ
-- ============================================================================
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local function mkTheme(name, top, mid, bot, accent, g1, g2, o)
	o = o or {}
	local text = o.Text or Color3.fromRGB(245, 245, 247)
	return {
		Name = name, Top = top, Mid = mid, Bot = bot,
		Black = bot:Lerp(BLACK, 0.7),
		Card = bot:Lerp(BLACK, 0.65),
		CardLine = mid:Lerp(WHITE, 0.1):Lerp(accent, 0.12),
		Item = mid:Lerp(BLACK, 0.4),
		ItemOn = mid:Lerp(accent, 0.2),
		ItemHover = mid:Lerp(WHITE, 0.06),
		DropBg = bot:Lerp(BLACK, 0.35),
		DropBorder = mid:Lerp(WHITE, 0.14):Lerp(accent, 0.2),
		TabOff = bot:Lerp(BLACK, 0.4),
		TabOn = mid:Lerp(accent, 0.14),
		TabLine = bot:Lerp(mid, 0.5),
		TabLineOn = mid:Lerp(accent, 0.35),
		Divider = bot:Lerp(BLACK, 0.6),
		Bar = mid:Lerp(WHITE, 0.12),
		SwOff = mid:Lerp(BLACK, 0.2),
		KnobOff = mid:Lerp(WHITE, 0.4),
		Text = text, Sub = text:Lerp(mid, 0.38), Dim = text:Lerp(mid, 0.62),
		Accent = accent, OnAccent = bot:Lerp(BLACK, 0.55),
		Glow = { g1, g2 },
		GlowSpeed = o.Speed or 40,   -- градусов в секунду (вращение переливания)
		PulseSpeed = o.Pulse or 2,   -- скорость пульсации
		GlowStyle = o.Style or "sweep",
		TitleFont = o.TitleFont,
	}
end

local Themes = {
	["Smoky Dark"] = mkTheme("Smoky Dark", Color3.fromRGB(50, 50, 56), Color3.fromRGB(32, 32, 37), Color3.fromRGB(18, 18, 22),
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 154, 160), Color3.fromRGB(220, 220, 230), { Speed = 40, Pulse = 2, Style = "sweep" }),
	["Obsidian"] = mkTheme("Obsidian", Color3.fromRGB(30, 26, 40), Color3.fromRGB(18, 16, 26), Color3.fromRGB(8, 8, 12),
		Color3.fromRGB(226, 214, 255), Color3.fromRGB(120, 90, 220), Color3.fromRGB(190, 170, 255), { Speed = 18, Pulse = 1.2, Style = "breath" }),
	["Frost Gray"] = mkTheme("Frost Gray", Color3.fromRGB(76, 86, 98), Color3.fromRGB(46, 54, 64), Color3.fromRGB(24, 30, 38),
		Color3.fromRGB(235, 246, 255), Color3.fromRGB(110, 200, 255), Color3.fromRGB(190, 235, 255), { Speed = 70, Pulse = 3, Style = "sparkle" }),
	["Crimson"] = mkTheme("Crimson", Color3.fromRGB(58, 22, 26), Color3.fromRGB(34, 14, 17), Color3.fromRGB(16, 8, 10),
		Color3.fromRGB(255, 96, 96), Color3.fromRGB(220, 40, 50), Color3.fromRGB(255, 120, 120), { Speed = 32, Pulse = 3.2, Style = "beat" }),
	["Spooky"] = mkTheme("Spooky", Color3.fromRGB(58, 30, 10), Color3.fromRGB(32, 17, 9), Color3.fromRGB(13, 8, 8),
		Color3.fromRGB(255, 122, 26), Color3.fromRGB(255, 106, 0), Color3.fromRGB(255, 172, 64),
		{ Speed = 50, Pulse = 2.6, Style = "flicker", Text = Color3.fromRGB(255, 240, 226), TitleFont = Font.fromEnum(Enum.Font.Creepster) }),
}
local ThemeNames = { "Smoky Dark", "Obsidian", "Frost Gray", "Crimson", "Spooky" }

-- Пульсации (возвращают 0..1). У каждой темы своя.
local Pulse = {
	sweep = function(t, p) return (math.sin(t * p) + 1) / 2 end,
	breath = function(t, p) local s = (math.sin(t * p) + 1) / 2 return s * s end,
	sparkle = function(t, p) return math.clamp(0.55 + 0.45 * math.sin(t * p) * math.sin(t * p * 2.3), 0, 1) end,
	beat = function(t, p)
		local a = math.max(0, math.sin(t * p))
		local b = math.max(0, math.sin(t * p - 0.9))
		return math.clamp(a ^ 3 + b ^ 3 * 0.6, 0, 1)
	end,
	flicker = function(t, p)
		local base = (math.sin(t * p) + 1) / 2
		return math.clamp(base * 0.6 + (math.noise(t * 9, 0.3) + 0.5) * 0.55, 0, 1)
	end,
}

-- Текущая тема (T). Все элементы читают цвета отсюда и перекрашиваются через hooks.
local T = {}
local hooks, themeListeners = {}, {}
local staticMode = false

local function setT(theme)
	for k, v in pairs(theme) do T[k] = v end
end
setT(Themes["Smoky Dark"])

local function themed(fn)
	fn()
	if not staticMode then table.insert(hooks, fn) end
end
local function th(obj, prop, key)
	if staticMode then
		obj[prop] = T[key]
	else
		themed(function() obj[prop] = T[key] end)
	end
end
-- динамические элементы (строки логов, яйца, посты) создаём в static-режиме: без хуков
local function static(fn, ...)
	local old = staticMode
	staticMode = true
	local ok, res = pcall(fn, ...)
	staticMode = old
	if not ok then warn("[Sterling] " .. tostring(res)) end
	return res
end

-- ШРИФТ: Gotham через FontFace ------------------------------------------------
local GOTHAM = "rbxasset://fonts/families/GothamSSm.json"
local F = {
	Regular = Font.new(GOTHAM, Enum.FontWeight.Regular),
	Medium = Font.new(GOTHAM, Enum.FontWeight.Medium),
	SemiBold = Font.new(GOTHAM, Enum.FontWeight.SemiBold),
	Bold = Font.new(GOTHAM, Enum.FontWeight.Bold),
	Heavy = Font.new(GOTHAM, Enum.FontWeight.Heavy),
}

-- ИКОНКИ: Lucide (чёрно-белые, красятся ImageColor3) -----------------------------
local ICON_URL = "https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua"
local TabIcons = {
	["Features"] = { "sparkles" }, ["Main"] = { "layout-dashboard", "house" }, ["Automation"] = { "repeat", "refresh-cw" },
	["Misc"] = { "shapes", "ellipsis" }, ["Pets"] = { "paw-print" }, ["Server"] = { "server" }, ["Finder"] = { "egg", "search" },
	["Events"] = { "calendar-days", "calendar" }, ["Live Chat"] = { "message-circle" }, ["Forum"] = { "messages-square", "message-square" },
	["Windows"] = { "app-window" }, ["Statistics"] = { "chart-column", "bar-chart-3" }, ["Performance"] = { "gauge" },
	["Config"] = { "settings" }, ["Keybind"] = { "keyboard" }, ["Panel"] = { "crown" },
}
-- запасные символы, если Lucide не загрузился
local Glyphs = {
	["Features"] = "✦", ["Main"] = "◆", ["Automation"] = "↻", ["Misc"] = "●", ["Pets"] = "♥", ["Server"] = "≡",
	["Finder"] = "◎", ["Events"] = "★", ["Live Chat"] = "◉", ["Forum"] = "¶", ["Windows"] = "▣", ["Statistics"] = "▲",
	["Performance"] = "◐", ["Config"] = "⚙", ["Keybind"] = "◧", ["Panel"] = "♛",
}

local IconLib, iconQueue, iconLoading = nil, {}, false
local function loadIcons()
	if iconLoading then return end
	iconLoading = true
	task.spawn(function()
		local ok, res = pcall(function()
			return loadstring(game:HttpGet(ICON_URL))()
		end)
		IconLib = (ok and typeof(res) == "table") and res or false
		for _, fn in ipairs(iconQueue) do pcall(fn) end
		iconQueue = {}
	end)
end

-- ХЕЛПЕРЫ ---------------------------------------------------------------------
local function create(class, props, parent)
	local obj = Instance.new(class)
	local map = props.Th
	props.Th = nil
	for k, v in pairs(props) do
		obj[k] = v
	end
	if parent then obj.Parent = parent end
	if map then
		for p, key in pairs(map) do th(obj, p, key) end
	end
	return obj
end

local function text(parent, props)
	local col = props.Col or (props.TextColor3 == nil and "Text" or nil)
	props.Col = nil
	local p = {
		BackgroundTransparency = 1, FontFace = F.Medium, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "",
	}
	for k, v in pairs(props) do p[k] = v end
	local l = create("TextLabel", p, parent)
	if col then th(l, "TextColor3", col) end
	return l
end

local function icon(parent, names, o)
	o = o or {}
	local common = {
		Size = o.Size or UDim2.fromScale(1, 1), Position = o.Position or UDim2.new(),
		AnchorPoint = o.AnchorPoint or Vector2.zero,
	}
	local img = create("ImageLabel", {
		BackgroundTransparency = 1, Visible = false, ScaleType = Enum.ScaleType.Fit,
		Size = common.Size, Position = common.Position, AnchorPoint = common.AnchorPoint,
	}, parent)
	local fb = text(parent, {
		Size = common.Size, Position = common.Position, AnchorPoint = common.AnchorPoint,
		Text = o.Glyph or "•", FontFace = F.Bold, TextSize = o.TextSize or 14,
		TextXAlignment = Enum.TextXAlignment.Center, Col = o.Col == false and "Text" or (o.Col or "Text"),
	})
	if o.Col ~= false then th(img, "ImageColor3", o.Col or "Text") end
	local function apply()
		if IconLib then
			for _, n in ipairs(names) do
				local id = IconLib[n]
				if id then
					img.Image = id
					img.Visible = true
					fb.Visible = false
					return
				end
			end
		end
	end
	if IconLib == nil then
		table.insert(iconQueue, apply)
		loadIcons()
	else
		apply()
	end
	return img, fb
end

local function tween(obj, props, time, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end
local function set(obj, props, time, style)
	if time then
		tween(obj, props, time, style)
	else
		for k, v in pairs(props) do obj[k] = v end
	end
end

local function corner(obj, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r) }, obj)
end

local function stroke(obj, color, thickness)
	local s = create("UIStroke", { Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
	if typeof(color) == "string" then th(s, "Color", color) else s.Color = color or T.CardLine end
	return s
end

local function padding(obj, l, t, r, b)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
	}, obj)
end

local function safe(callback, ...)
	if typeof(callback) ~= "function" then return end
	local ok, err = pcall(callback, ...)
	if not ok then warn("[Sterling] callback error: " .. tostring(err)) end
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
end

local function fmtTime(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
end

local function fmtDur(s)
	s = math.max(0, math.floor(s))
	if s < 60 then return s .. " sec" end
	if s < 3600 then return string.format("%d min %02d sec", s // 60, s % 60) end
	return string.format("%d h %02d min", s // 3600, (s % 3600) // 60)
end

local function fmtAgo(s)
	s = math.max(0, math.floor(s))
	if s < 5 then return "just now" end
	if s < 60 then return s .. " sec ago" end
	if s < 3600 then return (s // 60) .. " min ago" end
	return (s // 3600) .. " h ago"
end

local function secondsToNextHour()
	local d = os.date("*t")
	return (59 - d.min) * 60 + (60 - d.sec)
end

local function copyText(s)
	if typeof(setclipboard) == "function" then
		pcall(setclipboard, s)
		return true
	end
	return false
end

local function executorName()
	if typeof(identifyexecutor) == "function" then
		local ok, n = pcall(identifyexecutor)
		if ok and n then return tostring(n) end
	end
	return "Unknown"
end

local function deviceName()
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then
		return "Mobile"
	elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then
		return "Console"
	end
	return "PC"
end

local hasFiles = typeof(writefile) == "function" and typeof(readfile) == "function"
local memoryConfigs = {}
local CONFIG_DIR = "SterlingEngine"

local function ensureDir()
	if hasFiles and typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(CONFIG_DIR) then
		pcall(makefolder, CONFIG_DIR)
	end
end

-- ФОРУМ: сохранение ----------------------------------------------------------------
local FORUM_FILE = CONFIG_DIR .. "/forum.json"
local memoryForum = "[]"
local function readForum()
	local raw = memoryForum
	if hasFiles then
		local ok, res = pcall(readfile, FORUM_FILE)
		if ok and res and res ~= "" then raw = res end
	end
	local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
	return (ok and typeof(data) == "table") and data or {}
end
local function writeForum(list)
	local ok, json = pcall(function() return HttpService:JSONEncode(list) end)
	if not ok then return end
	memoryForum = json
	if hasFiles then
		pcall(function()
			ensureDir()
			writefile(FORUM_FILE, json)
		end)
	end
end

-- ============================================================================
-- СЕРВЕРНЫЕ ИНСТРУМЕНТЫ
-- ============================================================================
local ServerTools = {}

local function httpGet(url)
	local req = (syn and syn.request) or request or http_request or (http and http.request)
	if req then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and res and res.Body then return res.Body end
	end
	local ok, body = pcall(function() return game:HttpGet(url) end)
	return ok and body or nil
end
ServerTools.HttpGet = httpGet

local function fetchServers(cursor)
	local url = string.format(
		"https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
		game.PlaceId, cursor and ("&cursor=" .. cursor) or ""
	)
	local body = httpGet(url)
	if not body then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
	return ok and data or nil
end

function ServerTools.Rejoin()
	local lp = Players.LocalPlayer
	return pcall(function()
		if #Players:GetPlayers() <= 1 then
			lp:Kick("\nRejoining...")
			task.wait()
			TeleportService:Teleport(game.PlaceId, lp)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
		end
	end)
end

function ServerTools.Find(mode) -- "smallest" | "random"
	local data = fetchServers()
	if not data or not data.data then return nil, "Server list is unavailable" end
	local pool = {}
	for _, s in ipairs(data.data) do
		if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
			table.insert(pool, s)
		end
	end
	if #pool == 0 then return nil, "No servers found" end
	if mode == "smallest" then
		table.sort(pool, function(a, b) return a.playing < b.playing end)
		return pool[1]
	end
	return pool[math.random(#pool)]
end

-- server = { id = JobId, placeId = (необязательно) }
function ServerTools.Join(server)
	return pcall(function()
		TeleportService:TeleportToPlaceInstance(server.placeId or game.PlaceId, server.id, Players.LocalPlayer)
	end)
end

Sterling.Server = ServerTools

-- ============================================================================
-- ОКНО
-- ============================================================================
function Sterling.new(options)
	options = options or {}
	Sterling.Options = options
	table.clear(hooks)
	table.clear(themeListeners)

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local toggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	local wallpaperId = options.Wallpaper
	local iconId = options.Icon
	local userScale = 1

	setT(Themes[options.Theme or "Smoky Dark"] or Themes["Smoky Dark"])

	-- ВЛАДЕЛЕЦ: UserId (число/строка) ИЛИ username --------------------------------
	local function matchOwner(list)
		for _, v in ipairs(list or {}) do
			local s = tostring(v):lower():gsub("%s", "")
			if tonumber(s) == player.UserId or s == player.Name:lower() then
				return true
			end
		end
		return false
	end
	local isOwner = matchOwner(options.Owners)

	local old = playerGui:FindFirstChild("SterlingEngineExclusive")
	if old then old:Destroy() end

	local W, H = 840, 460
	local SB, RT = 160, 150

	local connections = {}
	local function connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(connections, c)
		return c
	end

	local gui = create("ScreenGui", {
		Name = "SterlingEngineExclusive", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local api = { Flags = {}, Notifications = true, IsOwner = isOwner, PlaceInfo = nil }
	local tickers = {}
	function api:OnTick(fn) table.insert(tickers, fn) end

	local function viewport()
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	local function computeK()
		local vp = viewport()
		local v = math.clamp(math.min(vp.X * 0.92 / W, vp.Y * 0.9 / H), 0.45, 1.15) * userScale
		return math.floor(v * 100 + 0.5) / 100
	end
	local k = computeK()

	-- ПЕРЕЛИВАЮЩАЯСЯ РАМКА (UIStroke + вращающийся UIGradient, пульсация) -----------
	local glows = {}
	local function glowSeq()
		local a, b = T.Glow[1], T.Glow[2]
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.18, b), ColorSequenceKeypoint.new(0.32, WHITE),
			ColorSequenceKeypoint.new(0.5, a), ColorSequenceKeypoint.new(0.68, b), ColorSequenceKeypoint.new(0.82, WHITE),
			ColorSequenceKeypoint.new(1, a),
		})
	end
	local function addGlow(parent, thick, trans, amp, trAmp)
		local s = create("UIStroke", {
			Thickness = thick, Transparency = trans, Color = WHITE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, parent)
		local g = create("UIGradient", {}, s)
		themed(function() g.Color = glowSeq() end)
		table.insert(glows, { s = s, g = g, th = thick, tr = trans, amp = amp, trAmp = trAmp })
	end
	connect(RunService.Heartbeat, function()
		if not gui.Enabled then return end
		local t = os.clock()
		local gp = (Pulse[T.GlowStyle] or Pulse.sweep)(t, T.PulseSpeed)
		local rot = (t * T.GlowSpeed) % 360
		for _, e in ipairs(glows) do
			e.s.Thickness = e.th + gp * e.amp
			e.s.Transparency = math.clamp(e.tr - gp * e.trAmp, 0, 1)
			e.g.Rotation = rot
		end
	end)

	local function buildIcon(parent, textSize, radius)
		if iconId and iconId ~= "" and iconId ~= "rbxassetid://0" then
			local img = create("ImageLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = iconId, ScaleType = Enum.ScaleType.Crop,
			}, parent)
			corner(img, radius or 999)
		else
			text(parent, {
				Size = UDim2.fromScale(1, 1), FontFace = F.Heavy, Text = "SE", TextSize = textSize,
				TextXAlignment = Enum.TextXAlignment.Center,
			})
		end
	end

	-- Данные плейса
	local placeInfo
	local infoWaiters = {}
	task.spawn(function()
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
		placeInfo = {
			Name = (ok and info and info.Name) or options.PlaceName or "Unknown Place",
			Description = (ok and info and info.Description) or "",
			Creator = (ok and info and info.Creator and info.Creator.Name) or "Unknown",
			Created = (ok and info and info.Created) and string.sub(info.Created, 1, 10) or "-",
			Updated = (ok and info and info.Updated) and string.sub(info.Updated, 1, 10) or "-",
		}
		api.PlaceInfo = placeInfo
		for _, fn in ipairs(infoWaiters) do task.spawn(fn, placeInfo) end
	end)
	local function whenInfo(fn)
		if placeInfo then task.spawn(fn, placeInfo) else table.insert(infoWaiters, fn) end
	end
	api.WhenPlaceInfo = whenInfo

	-- КОРНЕВОЕ ОКНО ---------------------------------------------------------------
	local root = create("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
	}, gui)
	corner(root, 16)
	local scale = create("UIScale", { Scale = k * 0.92 }, root)
	local bgGrad = create("UIGradient", { Rotation = 35 }, root)
	themed(function()
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, T.Top), ColorSequenceKeypoint.new(0.5, T.Mid), ColorSequenceKeypoint.new(1, T.Bot),
		})
	end)

	local sheen = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, root)
	create("UIGradient", {
		Rotation = 115,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(0.5, 0.985), NumberSequenceKeypoint.new(1, 0.9),
		}),
	}, sheen)

	if wallpaperId and wallpaperId ~= "" then
		create("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = wallpaperId,
			ImageTransparency = 0.55, ScaleType = Enum.ScaleType.Crop,
		}, root)
	end

	-- рамка: тёмная подложка + переливание + мягкое свечение внутрь
	local edge = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 198 }, root)
	corner(edge, 16)
	stroke(edge, "Black", 3)
	local halo = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 199 }, root)
	corner(halo, 16)
	addGlow(halo, 9, 0.88, 9, 0.28)
	local outer = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 200 }, root)
	corner(outer, 16)
	addGlow(outer, 3, 0.35, 2.5, 0.3)

	local function vDivider(x)
		local line = create("Frame", {
			Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, 0, 0, 0), BorderSizePixel = 0, ZIndex = 15,
			Th = { BackgroundColor3 = "Divider" },
		}, root)
		line.Size = UDim2.new(0, 1, 1, 0)
		create("Frame", {
			Position = UDim2.fromOffset(1, 0), Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = WHITE, BackgroundTransparency = 0.93, BorderSizePixel = 0,
		}, line)
	end
	vDivider(SB)
	vDivider(W - RT)

	-- Перетаскивание окна
	local dragging, dragStart, startPos = false, nil, nil
	local function makeDragZone(frame)
		connect(frame.InputBegan, function(input)
			if isPress(input) then
				dragging = true
				dragStart = input.Position
				startPos = Vector2.new(root.Position.X.Scale, root.Position.Y.Scale)
				local c
				c = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						c:Disconnect()
					end
				end)
			end
		end)
	end
	connect(UIS.InputChanged, function(input)
		if dragging and isMove(input) then
			local vp = viewport()
			local d = input.Position - dragStart
			root.Position = UDim2.fromScale(
				math.clamp(startPos.X + d.X / vp.X, 0.05, 0.95),
				math.clamp(startPos.Y + d.Y / vp.Y, 0.08, 0.92)
			)
		end
	end)

	local function dragFrame(handle, target)
		connect(handle.InputBegan, function(input)
			if isPress(input) then
				local m0, p0 = input.Position, target.Position
				local move = UIS.InputChanged:Connect(function(i)
					if isMove(i) then
						local d = i.Position - m0
						target.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
					end
				end)
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then move:Disconnect() end
				end)
			end
		end)
	end

	-- САЙДБАР -----------------------------------------------------------------------
	local sidebar = create("Frame", { Size = UDim2.fromOffset(SB, H), BackgroundTransparency = 1 }, root)
	local logoZone = create("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundTransparency = 1, Active = true }, sidebar)
	makeDragZone(logoZone)

	local avatarOuter = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(90, 90),
		BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
	}, logoZone)
	corner(avatarOuter, 999)
	stroke(avatarOuter, "Text", 2)
	local avatarInner = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(80, 80),
		BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
	}, avatarOuter)
	corner(avatarInner, 999)
	stroke(avatarInner, "Dim", 1)
	buildIcon(avatarInner, 30, 999)

	local titleLbl = text(logoZone, {
		Position = UDim2.fromOffset(6, 106), Size = UDim2.new(1, -12, 0, 22), FontFace = F.Bold, Text = "STERLING ENGINE",
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center,
	})
	themed(function()
		titleLbl.FontFace = T.TitleFont or F.Bold
		titleLbl.TextSize = T.TitleFont and 18 or 14
	end)
	local placeLabel = text(logoZone, {
		Position = UDim2.fromOffset(8, 128), Size = UDim2.new(1, -16, 0, 16), Text = "EXCLUSIVE", TextSize = 11, Col = "Sub",
		TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	whenInfo(function(info) placeLabel.Text = "EXCLUSIVE | " .. info.Name end)

	local tabList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 1, -150), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Th = { ScrollBarImageColor3 = "Dim" },
	}, sidebar)
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
	padding(tabList, 10, 2, 10, 10)

	-- ПРАВАЯ ПАНЕЛЬ -------------------------------------------------------------------
	local right = create("Frame", {
		Position = UDim2.fromOffset(W - RT, 0), Size = UDim2.fromOffset(RT, H), BackgroundTransparency = 1,
	}, root)
	local rightTop = create("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Active = true }, right)
	makeDragZone(rightTop)

	local function topButton(txt, x)
		return create("TextButton", {
			Position = UDim2.fromOffset(x, 6), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
			FontFace = F.Heavy, Text = txt, TextSize = 19, Th = { TextColor3 = "Text" },
		}, right)
	end
	local hideBtn = topButton("-", RT - 76)
	local closeBtn = topButton("X", RT - 40)

	local pill = create("Frame", {
		Position = UDim2.fromOffset(10, 44), Size = UDim2.fromOffset(RT - 20, 34), BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
	}, right)
	corner(pill, 10)
	stroke(pill, "CardLine", 1)
	local pillLabel = text(pill, {
		Size = UDim2.fromScale(1, 1), FontFace = F.Bold, Text = "... FPS", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
	})

	local hudBtn = create("TextButton", {
		Position = UDim2.fromOffset(10, 84), Size = UDim2.fromOffset(RT - 20, 30), BackgroundTransparency = 1,
		FontFace = F.Medium, Text = "Change Hud", TextSize = 14, Th = { TextColor3 = "Text" },
	}, right)

	local logList = create("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 120), Size = UDim2.fromOffset(RT - 18, H - 128), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, right)
	create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, logList)

	local logLines = {}
	function api:Log(msg)
		static(function()
			local l = text(logList, {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "- " .. tostring(msg),
				Col = "Sub", TextSize = 12, TextWrapped = true, LayoutOrder = #logLines + 1,
			})
			table.insert(logLines, l)
			if #logLines > 60 then table.remove(logLines, 1):Destroy() end
		end)
		task.spawn(function()
			RunService.Heartbeat:Wait()
			logList.CanvasPosition = Vector2.new(0, math.max(0, logList.AbsoluteCanvasSize.Y - logList.AbsoluteWindowSize.Y))
		end)
	end

	-- ТЕМЫ ---------------------------------------------------------------------------
	local hudIndex = 1
	api.OnHudChanged = nil
	local function applyTheme(name)
		local theme = Themes[name]
		if not theme then return false end
		setT(theme)
		for _, fn in ipairs(hooks) do pcall(fn) end
		for _, fn in ipairs(themeListeners) do pcall(fn) end
		return true
	end
	function api:SetHud(name, silent)
		for i, n in ipairs(ThemeNames) do
			if n == name and applyTheme(name) then
				hudIndex = i
				api:Log("[HUD] " .. name)
				if not silent then safe(api.OnHudChanged, name) end
			end
		end
	end
	hudBtn.Activated:Connect(function()
		local nextName = ThemeNames[(hudIndex % #ThemeNames) + 1]
		api:SetHud(nextName)
	end)
	function api:ThemeNames() return ThemeNames end

	-- ЦЕНТР: меню-объявление + страницы -------------------------------------------------
	local center = create("Frame", {
		Position = UDim2.fromOffset(SB + 1, 8), Size = UDim2.fromOffset(W - SB - RT - 2, H - 16), BackgroundTransparency = 1,
	}, root)

	local annBar = create("Frame", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 0, 40), BorderSizePixel = 0, Visible = false,
		Th = { BackgroundColor3 = "Black" },
	}, center)
	corner(annBar, 10)
	stroke(annBar, "TabLineOn", 1)
	local annText = text(annBar, {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0), TextSize = 12, TextWrapped = true, RichText = true,
	})
	local annClose = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1, FontFace = F.Bold, Text = "x", TextSize = 14, Th = { TextColor3 = "Sub" },
	}, annBar)

	local pages = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, center)
	local function layoutPages()
		if annBar.Visible then
			pages.Position = UDim2.fromOffset(0, 48)
			pages.Size = UDim2.new(1, 0, 1, -48)
		else
			pages.Position = UDim2.fromOffset(0, 0)
			pages.Size = UDim2.fromScale(1, 1)
		end
	end
	annClose.Activated:Connect(function()
		annBar.Visible = false
		layoutPages()
	end)

	-- ВЫПАДАЮЩИЙ СПИСОК ---------------------------------------------------------------------
	local blocker = create("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 90,
	}, root)
	local popup = create("Frame", { BorderSizePixel = 0, Visible = false, ZIndex = 100, Th = { BackgroundColor3 = "DropBg" } }, root)
	corner(popup, 10)
	stroke(popup, "DropBorder", 1)
	local popupList = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Th = { ScrollBarImageColor3 = "Text" },
	}, popup)
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, popupList)
	padding(popupList, 4, 4, 4, 4)

	local function closePopup()
		popup.Visible = false
		blocker.Visible = false
	end
	blocker.Activated:Connect(closePopup)

	local function openPopup(item, list, current, onPick)
		for _, child in ipairs(popupList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for i, opt in ipairs(list) do
			local sel = (opt == current)
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = sel and T.Accent or T.ItemHover, BackgroundTransparency = sel and 0 or 1,
				AutoButtonColor = false, FontFace = F.SemiBold, Text = tostring(opt), TextColor3 = sel and T.OnAccent or T.Text,
				TextSize = 14, LayoutOrder = i,
			}, popupList)
			corner(b, 7)
			b.MouseEnter:Connect(function() if not sel then tween(b, { BackgroundTransparency = 0 }, 0.1) end end)
			b.MouseLeave:Connect(function() if not sel then tween(b, { BackgroundTransparency = 1 }, 0.1) end end)
			b.Activated:Connect(function()
				closePopup()
				onPick(opt)
			end)
		end
		local rel = (item.AbsolutePosition - root.AbsolutePosition) / scale.Scale
		local iw, ih = math.max(item.AbsoluteSize.X / scale.Scale, 150), item.AbsoluteSize.Y / scale.Scale
		local height = math.min(#list * 34 + 8, 4 * 34 + 8)
		local x = math.min(rel.X, W - iw - 6)
		local y = rel.Y + ih + 4
		if y + height > H - 6 then y = rel.Y - height - 4 end
		popup.Size = UDim2.fromOffset(iw, height)
		popup.Position = UDim2.fromOffset(x, y)
		blocker.Visible = true
		popup.Visible = true
	end

	-- УВЕДОМЛЕНИЯ -----------------------------------------------------------------------------
	local toastHolder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 500,
	}, gui)
	create("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, toastHolder)

	function api:Notify(msg, duration)
		api:Log("[!] " .. tostring(msg))
		if not api.Notifications then return end
		static(function()
			local t = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Black,
				BackgroundTransparency = 1, BorderSizePixel = 0,
			}, toastHolder)
			corner(t, 10)
			local st = stroke(t, "TabLineOn", 1)
			st.Transparency = 1
			padding(t, 12, 9, 12, 9)
			create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, t)
			local a = text(t, {
				Size = UDim2.new(1, 0, 0, 12), FontFace = F.Heavy, Text = "STERLING ENGINE", Col = "Dim", TextSize = 10,
				TextTransparency = 1, LayoutOrder = 1,
			})
			local b = text(t, {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(msg), TextSize = 13,
				TextWrapped = true, TextTransparency = 1, LayoutOrder = 2,
			})
			local function fade(v)
				tween(t, { BackgroundTransparency = v == 0 and 0.04 or 1 }, 0.25)
				tween(st, { Transparency = v }, 0.25)
				tween(a, { TextTransparency = v }, 0.25)
				tween(b, { TextTransparency = v }, 0.25)
			end
			fade(0)
			task.delay(duration or 3, function()
				if t.Parent then
					fade(1)
					task.wait(0.3)
					t:Destroy()
				end
			end)
		end)
	end

	-- OWNER ANNOUNCEMENT: баннер сверху по центру экрана + полоса в меню ---------------------------
	local banner = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -220), Size = UDim2.fromOffset(430, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, Visible = false, ZIndex = 600, Th = { BackgroundColor3 = "Black" },
	}, gui)
	corner(banner, 14)
	addGlow(banner, 2, 0.3, 1.5, 0.25)
	padding(banner, 13, 10, 13, 11)
	create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, banner)
	local bannerScale = create("UIScale", { Scale = math.min(1, viewport().X * 0.94 / 430) }, banner)

	local bHead = create("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 1 }, banner)
	text(bHead, {
		Size = UDim2.new(1, -24, 1, 0), FontFace = F.Heavy, Text = "STERLING ENGINE  |  OWNER MESSAGE", TextSize = 10, Col = "Dim",
	})
	local bClose = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1, FontFace = F.Bold, Text = "x", TextSize = 14, Th = { TextColor3 = "Sub" },
	}, bHead)

	local bBody = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2,
	}, banner)
	local bRing = create("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(46, 46), BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" } }, bBody)
	corner(bRing, 999)
	stroke(bRing, "Text", 2)
	local bAvatar = create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -6, 1, -6),
		BorderSizePixel = 0, Image = "", Th = { BackgroundColor3 = "Item" },
	}, bRing)
	corner(bAvatar, 999)
	local bCol = create("Frame", {
		Position = UDim2.fromOffset(58, 0), Size = UDim2.new(1, -58, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
	}, bBody)
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, bCol)
	local bNameRow = create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1 }, bCol)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, bNameRow)
	local bName = text(bNameRow, { Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, FontFace = F.Bold, Text = "", TextSize = 15, LayoutOrder = 1 })
	local function pill(parent, txt, bgKey, fgKey, order)
		local f = create("Frame", { Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, LayoutOrder = order, Th = { BackgroundColor3 = bgKey } }, parent)
		corner(f, 6)
		padding(f, 7, 0, 7, 0)
		text(f, {
			Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, FontFace = F.Heavy, Text = txt, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Center, Col = fgKey,
		})
	end
	pill(bNameRow, "OWNER", "Text", "Black", 2)
	pill(bNameRow, "EXCLUSIVE", "Accent", "OnAccent", 3)
	local bMsg = text(bCol, {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", TextSize = 13, TextWrapped = true,
		FontFace = F.Medium, LayoutOrder = 2,
	})
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = 3, Th = { BackgroundColor3 = "CardLine" } }, banner)
	local bFoot = create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 4 }, banner)
	local bAgo = text(bFoot, { Size = UDim2.new(0.4, 0, 1, 0), TextSize = 11, FontFace = F.SemiBold, Col = "Dim" })
	local bEnd = text(bFoot, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.6, 0, 1, 0), TextSize = 11,
		FontFace = F.SemiBold, Col = "Sub", TextXAlignment = Enum.TextXAlignment.Right,
	})

	local currentAnn
	local function hideBanner()
		tween(banner, { Position = UDim2.new(0.5, 0, 0, -220) }, 0.3)
		task.delay(0.32, function()
			if not currentAnn or banner.Position.Y.Offset <= -200 then banner.Visible = false end
		end)
	end
	local function updateAnn()
		if not currentAnn then return end
		local now = os.time()
		if now >= currentAnn.endsAt then
			currentAnn = nil
			hideBanner()
			annBar.Visible = false
			layoutPages()
			return
		end
		bAgo.Text = "Sent " .. fmtAgo(now - currentAnn.sentAt)
		bEnd.Text = string.format("Ends in %s  ·  %s", fmtDur(currentAnn.endsAt - now), os.date("%H:%M", currentAnn.endsAt))
	end
	bClose.Activated:Connect(hideBanner)
	table.insert(tickers, updateAnn)

	-- data = { userId, name, display, text, sentAt, endsAt }
	function api:Announce(data)
		if typeof(data) == "string" then
			data = { userId = player.UserId, name = player.Name, display = player.DisplayName, text = data, sentAt = os.time(), endsAt = os.time() + 300 }
		end
		data.sentAt = data.sentAt or os.time()
		data.endsAt = data.endsAt or (os.time() + 300)
		currentAnn = data
		bName.Text = tostring(data.display or data.name or "Owner")
		bMsg.Text = tostring(data.text or "")
		bAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(data.userId or player.UserId) .. "&w=150&h=150"
		banner.Position = UDim2.new(0.5, 0, 0, -220)
		banner.Visible = true
		tween(banner, { Position = UDim2.new(0.5, 0, 0, 14) }, 0.5, Enum.EasingStyle.Back)
		annText.Text = string.format("<b>OWNER</b>  %s: %s", esc(data.name or "Owner"), esc(data.text or ""))
		annBar.Visible = true
		layoutPages()
		updateAnn()
		api:Notify("New owner message")
	end

	-- ЛАУНЧЕР ----------------------------------------------------------------------------------------
	local launcher = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.32, 0), Size = UDim2.fromOffset(54, 54),
		BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
	}, gui)
	corner(launcher, 14)
	addGlow(launcher, 2, 0.3, 1.5, 0.25)
	buildIcon(launcher, 20, 14)
	local launchBtn = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, launcher)

	local open = false
	local selected = nil
	local tabs = {}
	local bindingActive = false

	local function setOpen(state)
		if state == open then return end
		open = state
		if state then
			root.Visible = true
			scale.Scale = k * 0.92
			tween(scale, { Scale = k }, 0.3, Enum.EasingStyle.Back)
		else
			closePopup()
			tween(scale, { Scale = k * 0.92 }, 0.14)
			task.delay(0.15, function() if not open then root.Visible = false end end)
		end
	end

	local lDrag, lMoved, lStart, lPos = false, false, nil, nil
	connect(launchBtn.InputBegan, function(input)
		if isPress(input) then
			lDrag, lMoved = true, false
			lStart, lPos = input.Position, launcher.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					lDrag = false
					c:Disconnect()
					if not lMoved then setOpen(not open) end
				end
			end)
		end
	end)
	connect(UIS.InputChanged, function(input)
		if lDrag and isMove(input) then
			local d = input.Position - lStart
			if d.Magnitude > 6 then lMoved = true end
			if lMoved then
				launcher.Position = UDim2.new(lPos.X.Scale, lPos.X.Offset + d.X, lPos.Y.Scale, lPos.Y.Offset + d.Y)
			end
		end
	end)

	if workspace.CurrentCamera then
		connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
			k = computeK()
			bannerScale.Scale = math.min(1, viewport().X * 0.94 / 430)
			if open then scale.Scale = k end
		end)
	end

	connect(hideBtn.Activated, function() setOpen(false) end)
	connect(closeBtn.Activated, function() setOpen(false) end)

	connect(UIS.InputBegan, function(input, processed)
		if not processed and not bindingActive and input.KeyCode == toggleKey then setOpen(not open) end
	end)

	function api:Toggle() setOpen(not open) end
	function api:SetToggleKey(key) if key then toggleKey = key end end
	function api:SetLauncherVisible(v) launcher.Visible = v end
	function api:SetLogVisible(v) logList.Visible = v end
	function api:SetScale(v)
		userScale = math.clamp(v, 0.5, 1.4)
		k = computeK()
		if open then tween(scale, { Scale = k }, 0.15) end
	end
	function api:PanicToggle() gui.Enabled = not gui.Enabled end

	-- ПРОИЗВОДИТЕЛЬНОСТЬ (раз в секунду) -------------------------------------------------------------------
	local perf = {
		fps = 60, ping = 0, memory = 0, minFps = math.huge, avgFps = 0, avgPing = 0,
		peakPlayers = #Players:GetPlayers(), start = os.clock(), samples = 0, fpsSum = 0, pingSum = 0,
	}
	api.Perf = perf

	local function readPing()
		local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return ok and math.floor(v + 0.5) or 0
	end

	local frames, acc = 0, 0
	connect(RunService.Heartbeat, function(dt)
		frames += 1
		acc += dt
		if acc >= 1 then
			perf.fps = math.floor(frames / acc + 0.5)
			frames, acc = 0, 0
			perf.ping = readPing()
			perf.memory = math.floor(StatsService:GetTotalMemoryUsageMb() + 0.5)
			perf.samples += 1
			perf.fpsSum += perf.fps
			perf.pingSum += perf.ping
			perf.avgFps = math.floor(perf.fpsSum / perf.samples + 0.5)
			perf.avgPing = math.floor(perf.pingSum / perf.samples + 0.5)
			perf.minFps = math.min(perf.minFps, perf.fps)
			perf.peakPlayers = math.max(perf.peakPlayers, #Players:GetPlayers())
			pillLabel.Text = string.format("%d FPS  ·  %d ms", perf.fps, perf.ping)
			for _, fn in ipairs(tickers) do pcall(fn) end
		end
	end)

	-- КОНФИГИ ---------------------------------------------------------------------------------------------------
	local registry = {}
	local function register(key, getter, setter)
		registry[key] = { get = getter, set = setter, default = getter() }
	end

	function api:SaveConfig(name)
		name = name or "default"
		local data = {}
		for key, e in pairs(registry) do data[key] = e.get() end
		local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
		if not ok then return false end
		memoryConfigs[name] = json
		if hasFiles then
			pcall(function()
				ensureDir()
				writefile(CONFIG_DIR .. "/" .. name .. ".json", json)
			end)
		end
		return true
	end

	function api:LoadConfig(name)
		name = name or "default"
		local json = memoryConfigs[name]
		if hasFiles then
			local ok, res = pcall(function() return readfile(CONFIG_DIR .. "/" .. name .. ".json") end)
			if ok and res then json = res end
		end
		if not json then return false end
		local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
		if not ok or typeof(data) ~= "table" then return false end
		for key, v in pairs(data) do
			if registry[key] then pcall(registry[key].set, v) end
		end
		return true
	end

	function api:ResetConfig()
		for _, e in pairs(registry) do pcall(e.set, e.default) end
	end

	-- GLOBAL LIVE CHAT (WebSocket, если есть) --------------------------------------------------------------------------
	local chatList, chatCount, lastSend = nil, 0, 0
	local ws
	function api:ChatReceive(user, msg, role)
		if not chatList then return end
		chatCount += 1
		static(function()
			local line
			if role == "system" then
				line = '<font color="#' .. T.Dim:ToHex() .. '"><i>' .. esc(msg) .. "</i></font>"
			else
				local tag = role == "owner" and ('<font color="#' .. T.Accent:ToHex() .. '"><b>[OWNER]</b></font> ') or ""
				line = tag .. '<font color="#' .. T.Text:ToHex() .. '"><b>' .. esc(user) .. "</b></font>  " .. esc(msg)
			end
			text(chatList, {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, RichText = true, Text = line,
				Col = "Sub", TextSize = 13, TextWrapped = true, LayoutOrder = chatCount,
			})
			local kids = {}
			for _, c in ipairs(chatList:GetChildren()) do
				if c:IsA("TextLabel") then table.insert(kids, c) end
			end
			if #kids > 120 then kids[1]:Destroy() end
		end)
		task.spawn(function()
			RunService.Heartbeat:Wait()
			chatList.CanvasPosition = Vector2.new(0, math.max(0, chatList.AbsoluteCanvasSize.Y - chatList.AbsoluteWindowSize.Y))
		end)
	end
	api.ChatCount = function() return chatCount end

	-- seconds: сколько показывать объявление
	function api:SendAnnouncement(msg, seconds)
		seconds = math.clamp(tonumber(seconds) or 300, 1, 86400)
		local data = {
			type = "announce", userId = player.UserId, name = player.Name, display = player.DisplayName,
			text = msg, sentAt = os.time(), endsAt = os.time() + seconds,
		}
		if ws then
			pcall(function() ws:Send(HttpService:JSONEncode(data)) end)
		end
		api:Announce(data)
	end

	if options.ChatUrl and typeof(WebSocket) == "table" and WebSocket.connect then
		local ok, sock = pcall(WebSocket.connect, options.ChatUrl)
		if ok and sock then
			ws = sock
			sock.OnMessage:Connect(function(m)
				local ok2, d = pcall(function() return HttpService:JSONDecode(m) end)
				if ok2 and typeof(d) == "table" then
					if d.type == "announce" then
						api:Announce(d)
					else
						api:ChatReceive(d.user or "?", d.text or "", d.role)
					end
				end
			end)
		end
	end

	-- ФОРУМ (сохраняется) ---------------------------------------------------------------------------------------------------
	local forumPosts = readForum()
	local forumList, forumCards = nil, {}
	local function renderForum()
		if not forumList then return end
		for _, c in ipairs(forumCards) do c:Destroy() end
		forumCards = {}
		static(function()
			if #forumPosts == 0 then
				table.insert(forumCards, text(forumList, {
					Size = UDim2.new(1, 0, 0, 40), Text = "No posts yet. Be the first!", Col = "Dim", TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 0,
				}))
				return
			end
			for i, p in ipairs(forumPosts) do
				local card = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = -i,
					Th = { BackgroundColor3 = "DropBg" },
				}, forumList)
				corner(card, 10)
				stroke(card, "CardLine", 1)
				padding(card, 10, 8, 10, 8)
				create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, card)
				text(card, { Size = UDim2.new(1, 0, 0, 18), FontFace = F.Bold, Text = tostring(p.title), TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1 })
				text(card, {
					Size = UDim2.new(1, 0, 0, 14), FontFace = F.SemiBold, TextSize = 11, Col = "Dim", LayoutOrder = 2,
					Text = tostring(p.author) .. "  ·  " .. os.date("%d.%m.%Y %H:%M", tonumber(p.time) or os.time()),
				})
				text(card, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = tostring(p.body), TextSize = 13, Col = "Sub", TextWrapped = true, LayoutOrder = 3 })
				table.insert(forumCards, card)
			end
		end)
	end
	table.insert(themeListeners, renderForum)

	function api:ForumAdd(title, author, body, when)
		table.insert(forumPosts, { title = title, author = author, body = body, time = tonumber(when) or os.time() })
		while #forumPosts > 200 do table.remove(forumPosts, 1) end
		writeForum(forumPosts)
		renderForum()
	end
	function api:ForumClear()
		forumPosts = {}
		writeForum(forumPosts)
		renderForum()
	end

	-- ПЛАВАЮЩИЕ ОКНА -----------------------------------------------------------------------------------------------------------
	local widgetCount = 0
	function api:Widget(title, lines)
		widgetCount += 1
		local defaultPos = UDim2.new(0, 16, 0.5, (widgetCount - 1) * 100 - 40)
		local f = create("Frame", {
			Position = defaultPos, Size = UDim2.fromOffset(180, 34 + #lines * 20 + 8), BackgroundTransparency = 0.12,
			BorderSizePixel = 0, Active = true, Visible = false, Th = { BackgroundColor3 = "Black" },
		}, gui)
		corner(f, 10)
		stroke(f, "TabLineOn", 1)
		text(f, {
			Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 18), FontFace = F.Heavy,
			Text = string.upper(title), TextSize = 11, Col = "Dim",
		})
		dragFrame(f, f)
		for i, line in ipairs(lines) do
			local y = 28 + (i - 1) * 20
			text(f, { Position = UDim2.fromOffset(12, y), Size = UDim2.new(0.5, -12, 0, 18), Text = line[1], TextSize = 12, Col = "Sub" })
			local v = text(f, {
				Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.new(0.5, -12, 0, 18), FontFace = F.Bold, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
			})
			local function refresh()
				local ok, val = pcall(line[2])
				v.Text = ok and tostring(val) or "-"
			end
			refresh()
			table.insert(tickers, refresh)
		end
		return {
			Frame = f,
			SetVisible = function(_, s) f.Visible = s end,
			Reset = function() f.Position = defaultPos end,
		}
	end

	-- ВКЛАДКИ -----------------------------------------------------------------------------------------------------------------------
	local function paintTab(t, anim)
		local active = (selected == t)
		local col = active and T.Text or T.Sub
		t.Indicator.Visible = active
		t.Indicator.BackgroundColor3 = T.Accent
		set(t.Button, { BackgroundColor3 = active and T.TabOn or T.TabOff }, anim and 0.15)
		set(t.Label, { TextColor3 = col }, anim and 0.15)
		set(t.Glyph, { TextColor3 = col }, anim and 0.15)
		set(t.Img, { ImageColor3 = col }, anim and 0.15)
		set(t.Stroke, { Color = active and T.TabLineOn or T.TabLine }, anim and 0.15)
	end

	local function selectTab(entry, silent)
		selected = entry
		closePopup()
		for _, t in ipairs(tabs) do
			t.Page.Visible = (t == entry)
			paintTab(t, true)
		end
		if not silent then api:Log("[TAB] " .. entry.Name) end
	end

	function api:Tab(name, iconNames)
		local names = iconNames or TabIcons[name] or { "circle" }
		local btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 36), AutoButtonColor = false, Text = "", LayoutOrder = #tabs + 1,
		}, tabList)
		corner(btn, 10)
		local btnStroke = stroke(btn, "TabLine", 1)
		local indicator = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.fromOffset(3, 18),
			BorderSizePixel = 0, Visible = false,
		}, btn)
		corner(indicator, 99)
		local img, glyphLbl = icon(btn, names, {
			Position = UDim2.new(0, 14, 0.5, -9), Size = UDim2.fromOffset(18, 18), Glyph = Glyphs[name] or "•", TextSize = 15, Col = false,
		})
		local lbl = text(btn, {
			Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0), Text = name, FontFace = F.SemiBold,
			TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, Col = "Sub",
		})

		local page = create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false, Th = { ScrollBarImageColor3 = "Dim" },
		}, pages)
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, page)
		padding(page, 8, 8, 8, 8)

		local entry = { Name = name, Button = btn, Label = lbl, Glyph = glyphLbl, Img = img, Stroke = btnStroke, Page = page, Indicator = indicator }
		table.insert(tabs, entry)
		themed(function() paintTab(entry, false) end)
		btn.Activated:Connect(function() selectTab(entry) end)
		btn.MouseEnter:Connect(function()
			if selected ~= entry then tween(btn, { BackgroundColor3 = T.ItemHover }, 0.12) end
		end)
		btn.MouseLeave:Connect(function()
			if selected ~= entry then tween(btn, { BackgroundColor3 = T.TabOff }, 0.15) end
		end)
		if #tabs == 1 then selectTab(entry, true) end

		local tab = {}
		local cardOrder = 0

		function tab:SetVisible(v)
			btn.Visible = v
			if not v and selected == entry then selectTab(tabs[1], true) end
		end

		function tab:Section(title, sectionIcon)
			cardOrder += 1
			local base = name .. "/" .. title .. "/"
			local card = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = cardOrder,
				Th = { BackgroundColor3 = "Card" },
			}, page)
			corner(card, 14)
			stroke(card, "CardLine", 1)
			padding(card, 12, 10, 12, 12)
			create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, card)

			local head = create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1 }, card)
			local ic = create("Frame", {
				Position = UDim2.fromOffset(0, 2), Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
			}, head)
			corner(ic, 999)
			stroke(ic, "Sub", 1)
			icon(ic, sectionIcon and { sectionIcon } or names, {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
				Glyph = Glyphs[name] or "•", TextSize = 12,
			})
			text(head, {
				Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -32, 0, 26), FontFace = F.Bold, Text = title, TextSize = 15,
			})
			create("Frame", {
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
				Th = { BackgroundColor3 = "TabLineOn" },
			}, head)

			local grid = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Visible = false,
			}, card)
			create("UIGridLayout", {
				CellSize = UDim2.new(1 / 3, -6, 0, 44), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder,
			}, grid)

			local section = {}
			local n, blockOrder = 0, 2

			local function newItem(isBoxed)
				n += 1
				grid.Visible = true
				local item = create("Frame", {
					BorderSizePixel = 0, LayoutOrder = n, Th = { BackgroundColor3 = isBoxed and "DropBg" or "Item" },
				}, grid)
				corner(item, 10)
				if isBoxed then stroke(item, "DropBorder", 1.5) end
				return item
			end
			local function itemLabel(item, txt, rightPad)
				return text(item, {
					Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -(12 + rightPad), 1, 0), FontFace = F.SemiBold,
					Text = txt, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd,
				})
			end
			local function itemHit(item)
				return create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }, item)
			end

			function section:Block(height)
				blockOrder += 1
				return create("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = blockOrder }, card)
			end

			function section:Label(txt)
				blockOrder += 1
				local l = text(card, {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = txt, Col = "Sub", TextSize = 13,
					TextWrapped = true, LayoutOrder = blockOrder,
				})
				padding(l, 2, 2, 2, 2)
				return { Set = function(_, t) l.Text = t end }
			end

			-- Toggle -----------------------------------------------------------------------
			function section:Toggle(txt, default, callback)
				local state = default and true or false
				local item = newItem(false)
				itemLabel(item, txt, 54)
				local sw = create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(42, 22), BorderSizePixel = 0,
				}, item)
				corner(sw, 999)
				stroke(sw, "DropBorder", 1)
				local knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0 }, sw)
				corner(knob, 999)
				local function paint(anim)
					set(item, { BackgroundColor3 = state and T.ItemOn or T.Item }, anim and 0.15)
					set(sw, { BackgroundColor3 = state and T.Accent or T.SwOff }, anim and 0.18)
					set(knob, {
						Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
						BackgroundColor3 = state and T.OnAccent or T.KnobOff,
					}, anim and 0.2, Enum.EasingStyle.Back)
				end
				themed(function() paint(false) end)
				local hit = itemHit(item)
				hit.MouseEnter:Connect(function() if not state then tween(item, { BackgroundColor3 = T.ItemHover }, 0.12) end end)
				hit.MouseLeave:Connect(function() tween(item, { BackgroundColor3 = state and T.ItemOn or T.Item }, 0.15) end)
				local obj = {}
				local function apply(v, fire)
					state = v
					paint(true)
					if fire then
						api:Log(string.format("[+] %s: %s", txt, v and "ENABLED" or "DISABLED"))
						safe(callback, v)
					end
				end
				function obj:Set(v) apply(v and true or false, true) end
				function obj:Get() return state end
				hit.Activated:Connect(function() apply(not state, true) end)
				register(base .. txt, function() return state end, function(v) apply(v == true, true) end)
				return obj
			end

			-- Dropdown ----------------------------------------------------------------------
			function section:Dropdown(txt, list, default, callback)
				local current = default or list[1]
				local item = newItem(true)
				local lbl = itemLabel(item, "", 30)
				local function refresh() lbl.Text = txt .. ": " .. tostring(current) end
				refresh()
				icon(item, { "chevron-down" }, {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(14, 14),
					Glyph = "v", TextSize = 12, Col = "Sub",
				})
				local hit = itemHit(item)
				hit.MouseEnter:Connect(function() tween(item, { BackgroundColor3 = T.ItemHover }, 0.12) end)
				hit.MouseLeave:Connect(function() tween(item, { BackgroundColor3 = T.DropBg }, 0.15) end)
				hit.Activated:Connect(function()
					openPopup(item, list, current, function(opt)
						current = opt
						refresh()
						api:Log(string.format("[+] %s: %s", txt, tostring(opt)))
						safe(callback, opt)
					end)
				end)
				local obj = {}
				function obj:Get() return current end
				function obj:Set(v, silent)
					current = v
					refresh()
					if not silent then safe(callback, v) end
				end
				register(base .. txt, function() return current end, function(v) obj:Set(v) end)
				return obj
			end

			-- Button -------------------------------------------------------------------------
			function section:Button(txt, callback)
				local item = newItem(false)
				local lbl = text(item, {
					Size = UDim2.fromScale(1, 1), FontFace = F.Bold, Text = txt, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
				})
				local hit = itemHit(item)
				hit.MouseEnter:Connect(function() tween(item, { BackgroundColor3 = T.ItemHover }, 0.12) end)
				hit.MouseLeave:Connect(function() tween(item, { BackgroundColor3 = T.Item }, 0.15) end)
				hit.InputBegan:Connect(function(input)
					if isPress(input) then
						tween(item, { BackgroundColor3 = T.Accent }, 0.08)
						tween(lbl, { TextColor3 = T.OnAccent }, 0.08)
					end
				end)
				hit.InputEnded:Connect(function(input)
					if isPress(input) then
						tween(item, { BackgroundColor3 = T.Item }, 0.2)
						tween(lbl, { TextColor3 = T.Text }, 0.2)
					end
				end)
				hit.Activated:Connect(function()
					api:Log("[+] " .. txt)
					safe(callback)
				end)
			end

			-- Slider ---------------------------------------------------------------------------
			function section:Slider(txt, min, max, default, callback, step)
				step = step or 1
				local value = math.clamp(default or min, min, max)
				local item = newItem(false)
				local lbl = text(item, {
					Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -24, 0, 18), FontFace = F.SemiBold,
					Text = txt .. ": " .. tostring(value), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
				})
				local bar = create("Frame", {
					Position = UDim2.new(0, 12, 1, -13), Size = UDim2.new(1, -24, 0, 5), BorderSizePixel = 0, Th = { BackgroundColor3 = "Bar" },
				}, item)
				corner(bar, 99)
				local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Accent" } }, bar)
				corner(fill, 99)
				local function render()
					fill.Size = UDim2.fromScale((value - min) / math.max(1, max - min), 1)
					lbl.Text = txt .. ": " .. tostring(value)
				end
				render()
				local function setValue(v, fire)
					v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
					if v == value then return end
					value = v
					render()
					if fire then safe(callback, value) end
				end
				local sliding = false
				local hit = itemHit(item)
				local function fromX(x)
					local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
					setValue(min + (max - min) * a, true)
				end
				hit.InputBegan:Connect(function(input)
					if isPress(input) then
						sliding = true
						fromX(input.Position.X)
						local c
						c = input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								sliding = false
								c:Disconnect()
								api:Log(string.format("[+] %s: %s", txt, tostring(value)))
							end
						end)
					end
				end)
				connect(UIS.InputChanged, function(input)
					if sliding and isMove(input) then fromX(input.Position.X) end
				end)
				local obj = {}
				function obj:Get() return value end
				function obj:Set(v) setValue(v, true) end
				register(base .. txt, function() return value end, function(v)
					if typeof(v) == "number" then setValue(v, true) end
				end)
				return obj
			end

			-- Input ------------------------------------------------------------------------------
			function section:Input(txt, placeholder, callback, default)
				local item = newItem(true)
				local box = create("TextBox", {
					Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, ClearTextOnFocus = false,
					FontFace = F.SemiBold, PlaceholderText = placeholder or txt, Text = default or "", TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Th = { TextColor3 = "Text", PlaceholderColor3 = "Dim" },
				}, item)
				box.FocusLost:Connect(function(enter) safe(callback, box.Text, enter) end)
				local obj = {}
				function obj:Get() return box.Text end
				function obj:Set(v) box.Text = tostring(v) end
				register(base .. txt, function() return box.Text end, function(v) box.Text = tostring(v) end)
				return obj
			end

			-- Keybind -----------------------------------------------------------------------------
			function section:Keybind(txt, default, onPress, onChange)
				local key = default
				local binding = false
				local item = newItem(false)
				itemLabel(item, txt, 74)
				local btn2 = create("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(64, 26),
					AutoButtonColor = false, FontFace = F.Bold, Text = "", TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
					Th = { BackgroundColor3 = "DropBg", TextColor3 = "Text" },
				}, item)
				corner(btn2, 8)
				stroke(btn2, "DropBorder", 1)
				local function refresh() btn2.Text = key and key.Name or "None" end
				refresh()
				btn2.Activated:Connect(function()
					binding = true
					bindingActive = true
					btn2.Text = "..."
				end)
				connect(UIS.InputBegan, function(input, processed)
					if binding then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							binding = false
							bindingActive = false
							key = (input.KeyCode ~= Enum.KeyCode.Escape) and input.KeyCode or nil
							refresh()
							api:Log(string.format("[+] %s: %s", txt, key and key.Name or "None"))
							safe(onChange, key)
						end
						return
					end
					if not processed and not bindingActive and key and input.KeyCode == key then safe(onPress) end
				end)
				local obj = {}
				function obj:Get() return key end
				function obj:Set(k2) key = k2 refresh() safe(onChange, key) end
				register(base .. txt, function() return key and key.Name or "" end, function(v)
					local ok, kc = pcall(function() return Enum.KeyCode[v] end)
					obj:Set(ok and kc or nil)
				end)
				return obj
			end

			-- Stat (живая строка) ---------------------------------------------------------------------
			function section:Stat(txt, getter, copyable)
				local item = newItem(false)
				text(item, {
					Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -24, 0, 14), FontFace = F.SemiBold, Text = txt, TextSize = 11, Col = "Dim",
				})
				local val = text(item, {
					Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -24, 0, 18), FontFace = F.Bold, Text = "...", TextSize = 14,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
				local function refresh()
					local ok, v = pcall(getter)
					val.Text = ok and tostring(v) or "-"
				end
				refresh()
				table.insert(tickers, refresh)
				if copyable then
					local hit = itemHit(item)
					hit.MouseEnter:Connect(function() tween(item, { BackgroundColor3 = T.ItemHover }, 0.12) end)
					hit.MouseLeave:Connect(function() tween(item, { BackgroundColor3 = T.Item }, 0.15) end)
					hit.Activated:Connect(function()
						api:Notify(copyText(val.Text) and (txt .. " copied") or "Clipboard is not available")
					end)
				end
				return { Refresh = refresh }
			end

			-- Карточка плейса ------------------------------------------------------------------------------
			function section:PlaceCard()
				local b = self:Block(96)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 12)
				local iconImg = create("ImageLabel", {
					Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(72, 72), ScaleType = Enum.ScaleType.Crop,
					Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Th = { BackgroundColor3 = "Black" },
				}, box)
				corner(iconImg, 14)
				stroke(iconImg, "TabLineOn", 1)
				local nm = text(box, { Position = UDim2.fromOffset(94, 10), Size = UDim2.new(1, -104, 0, 24), FontFace = F.Bold, Text = "Loading...", TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd })
				local cr = text(box, { Position = UDim2.fromOffset(94, 35), Size = UDim2.new(1, -104, 0, 16), FontFace = F.SemiBold, TextSize = 13, Col = "Sub" })
				local ds = text(box, { Position = UDim2.fromOffset(94, 54), Size = UDim2.new(1, -104, 0, 34), TextSize = 12, Col = "Dim", TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd })
				whenInfo(function(info)
					nm.Text = info.Name
					cr.Text = "by " .. info.Creator
					ds.Text = info.Description ~= "" and info.Description or "No description."
				end)
			end

			-- Карточка пользователя ------------------------------------------------------------------------------
			function section:UserCard()
				local b = self:Block(96)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 12)
				local ring = create("Frame", {
					Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(72, 72), BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" },
				}, box)
				corner(ring, 999)
				stroke(ring, "Text", 2)
				local av = create("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BorderSizePixel = 0,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150", Th = { BackgroundColor3 = "Black" },
				}, ring)
				corner(av, 999)
				text(box, { Position = UDim2.fromOffset(94, 12), Size = UDim2.new(1, -104, 0, 24), FontFace = F.Bold, Text = player.DisplayName, TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd })
				text(box, { Position = UDim2.fromOffset(94, 38), Size = UDim2.new(1, -104, 0, 16), FontFace = F.SemiBold, Text = "@" .. player.Name .. "  ·  ID " .. player.UserId, TextSize = 13, Col = "Sub", TextTruncate = Enum.TextTruncate.AtEnd })
				local prem = player.MembershipType == Enum.MembershipType.Premium and "Premium" or "No Premium"
				text(box, { Position = UDim2.fromOffset(94, 58), Size = UDim2.new(1, -104, 0, 16), Text = player.AccountAge .. " days on Roblox  ·  " .. prem, TextSize = 12, Col = "Dim" })
			end

			-- График -------------------------------------------------------------------------------------------------
			function section:Graph(title, getter, maxValue, unit)
				local b = self:Block(80)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 10)
				text(box, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.5, 0, 0, 18), FontFace = F.SemiBold, Text = title, TextSize = 13, Col = "Sub" })
				local cur = text(box, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0.5, 0, 0, 18), FontFace = F.Bold, Text = "-", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right })
				local area = create("Frame", { Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 1, -38), BackgroundTransparency = 1 }, box)
				local N = 48
				local bars, hist = {}, {}
				for i = 1, N do
					hist[i] = 0
					bars[i] = create("Frame", {
						AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / N, 0, 1, 0), Size = UDim2.new(1 / N, -1, 0, 2),
						BackgroundTransparency = 0.12, BorderSizePixel = 0, Th = { BackgroundColor3 = "Accent" },
					}, area)
				end
				table.insert(tickers, function()
					local v = getter()
					table.remove(hist, 1)
					table.insert(hist, v)
					for i = 1, N do
						bars[i].Size = UDim2.new(1 / N, -1, math.clamp(hist[i] / maxValue, 0.04, 1), 0)
					end
					cur.Text = tostring(v) .. (unit or "")
				end)
			end

			-- Global Live Chat ------------------------------------------------------------------------------------------
			function section:Chat(height)
				local b = self:Block(height or 300)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 12)
				chatList = create("ScrollingFrame", {
					Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0,
					ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Th = { ScrollBarImageColor3 = "Dim" },
				}, box)
				create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chatList)
				local row = create("Frame", {
					AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 34), BorderSizePixel = 0,
					Th = { BackgroundColor3 = "DropBg" },
				}, box)
				corner(row, 9)
				stroke(row, "DropBorder", 1.5)
				local input = create("TextBox", {
					Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -86, 1, 0), BackgroundTransparency = 1, ClearTextOnFocus = false,
					FontFace = F.SemiBold, PlaceholderText = "Message everyone...", Text = "", TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
					Th = { TextColor3 = "Text", PlaceholderColor3 = "Dim" },
				}, row)
				local send = create("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(68, 26),
					AutoButtonColor = false, FontFace = F.Bold, Text = "Send", TextSize = 13,
					Th = { BackgroundColor3 = "Accent", TextColor3 = "OnAccent" },
				}, row)
				corner(send, 7)

				local function sendChat()
					local msg = string.match(input.Text, "^%s*(.-)%s*$")
					if msg == "" or #msg > 200 then return end
					if os.clock() - lastSend < 1.2 then
						api:Notify("Slow down a little")
						return
					end
					lastSend = os.clock()
					input.Text = ""
					if ws then
						pcall(function()
							ws:Send(HttpService:JSONEncode({
								user = player.DisplayName, userId = player.UserId, text = msg, role = api.IsOwner and "owner" or nil,
							}))
						end)
					else
						api:ChatReceive(player.DisplayName, msg, api.IsOwner and "owner" or nil)
					end
					safe(options.OnChatSend, msg)
				end
				send.Activated:Connect(sendChat)
				input.FocusLost:Connect(function(enter) if enter then sendChat() end end)

				if ws then
					api:ChatReceive("", "Connected to Global Live Chat.", "system")
				else
					api:ChatReceive("", "Local mode. Set Options.ChatUrl (WebSocket) to talk with everyone in Global Live Chat.", "system")
				end
			end

			-- Форум (сохраняется) --------------------------------------------------------------------------------------------
			function section:Forum(height)
				local b = self:Block(height or 320)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 12)
				forumList = create("ScrollingFrame", {
					Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -96), BackgroundTransparency = 1, BorderSizePixel = 0,
					ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Th = { ScrollBarImageColor3 = "Dim" },
				}, box)
				create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, forumList)

				local function field(y, h, w, placeholder)
					local f = create("Frame", {
						AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, y), Size = UDim2.new(w, w == 1 and -16 or -96, 0, h),
						BorderSizePixel = 0, Th = { BackgroundColor3 = "DropBg" },
					}, box)
					corner(f, 9)
					stroke(f, "DropBorder", 1.5)
					return create("TextBox", {
						Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, ClearTextOnFocus = false,
						FontFace = F.SemiBold, PlaceholderText = placeholder, Text = "", TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						Th = { TextColor3 = "Text", PlaceholderColor3 = "Dim" },
					}, f)
				end
				local titleBox = field(-48, 32, 1, "Post title")
				local bodyBox = field(-8, 34, 0, "Write something...")
				bodyBox.Parent.Size = UDim2.new(1, -96, 0, 34)
				local post = create("TextButton", {
					AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(70, 30),
					AutoButtonColor = false, FontFace = F.Bold, Text = "Post", TextSize = 13, ZIndex = 3,
					Th = { BackgroundColor3 = "Accent", TextColor3 = "OnAccent" },
				}, box)
				corner(post, 7)

				post.Activated:Connect(function()
					local t = string.match(titleBox.Text, "^%s*(.-)%s*$")
					local body = string.match(bodyBox.Text, "^%s*(.-)%s*$")
					if t == "" or body == "" then
						api:Notify("Fill in the title and text")
						return
					end
					titleBox.Text, bodyBox.Text = "", ""
					if options.OnForumPost then
						safe(options.OnForumPost, t, body)
					else
						api:ForumAdd(t, player.DisplayName, body)
					end
				end)
				renderForum()
			end

			-- Список яиц (Egg Finder) ---------------------------------------------------------------------------------------------
			local RarityColors = {
				ethereal = Color3.fromRGB(120, 220, 255), admin = Color3.fromRGB(255, 80, 80), mythic = Color3.fromRGB(210, 140, 255),
				legendary = Color3.fromRGB(255, 200, 80), rare = Color3.fromRGB(106, 168, 255),
			}
			local templateCache = {}
			local function findTemplate(name)
				if templateCache[name] ~= nil then return templateCache[name] or nil end
				local found
				pcall(function()
					local inst = ReplicatedStorage:FindFirstChild(name, true) or workspace:FindFirstChild(name, true)
					if inst and (inst:IsA("Model") or inst:IsA("BasePart")) then found = inst end
				end)
				templateCache[name] = found or false
				return found
			end

			local function buildEggModel(parent, egg)
				local tpl = findTemplate(egg.name)
				if tpl then
					local vp = create("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 170, 170) }, parent)
					local ok = pcall(function()
						local m = tpl:Clone()
						local cf, size
						if m:IsA("Model") then cf, size = m:GetBoundingBox() else cf, size = m.CFrame, m.Size end
						m.Parent = vp
						local cam = Instance.new("Camera")
						local dist = math.max(size.X, size.Y, size.Z) * 1.9
						cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.2, dist), cf.Position)
						cam.Parent = vp
						vp.CurrentCamera = cam
					end)
					if ok then return end
					vp:Destroy()
				end
				local img = Sterling.Options and Sterling.Options.EggImages and Sterling.Options.EggImages[egg.name]
				if img then
					create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit }, parent)
				else
					icon(parent, { "egg" }, {
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34),
						Glyph = "◎", TextSize = 26, Col = false,
					})
					for _, c in ipairs(parent:GetChildren()) do
						if c:IsA("ImageLabel") then c.ImageColor3 = RarityColors[string.lower(egg.rarity)] or WHITE end
						if c:IsA("TextLabel") then c.TextColor3 = RarityColors[string.lower(egg.rarity)] or WHITE end
					end
				end
			end

			function section:EggList(height)
				local b = self:Block(height or 340)
				local box = create("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Th = { BackgroundColor3 = "Item" } }, b)
				corner(box, 12)
				local empty = text(box, {
					Position = UDim2.fromOffset(10, 16), Size = UDim2.new(1, -20, 0, 50), TextWrapped = true, Col = "Dim", TextSize = 13,
					Text = "No Ethereal / Admin eggs found right now.\nEggs that disappear from a server vanish from this list automatically.",
					TextXAlignment = Enum.TextXAlignment.Center,
				})
				local scroll = create("ScrollingFrame", {
					Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1, BorderSizePixel = 0,
					ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Th = { ScrollBarImageColor3 = "Dim" },
				}, box)
				create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

				local rows, lastList = {}, {}
				local obj = { OnJoin = nil }

				local function updateRow(r)
					local e = r.egg
					local col = RarityColors[string.lower(e.rarity)] or T.Text
					r.line2.Text = string.format('Rarity: <font color="#%s"><b>%s</b></font>  ·  Mutation: <b>%s</b>', col:ToHex(), esc(e.rarity), esc(e.mutation))
					r.line3.Text = "Traits: <b>" .. (#e.traits > 0 and esc(table.concat(e.traits, ", ")) or "-") .. "</b>"
					local age = os.time() - e.spawnedAt
					r.line4.Text = string.format("<b>%.2f kg</b>  ·  Score <b>%s</b>  ·  Spawned %s ago (%s)", e.weight, tostring(e.score or 0), fmtDur(age), os.date("%H:%M:%S", e.spawnedAt))
					r.join.Text = (e.jobId == game.JobId) and "Here" or "Join"
				end

				local function buildRow(egg)
					return static(function()
						local col = RarityColors[string.lower(egg.rarity)] or T.DropBorder
						local row = create("Frame", { Size = UDim2.new(1, 0, 0, 82), BorderSizePixel = 0, Th = { BackgroundColor3 = "DropBg" } }, scroll)
						corner(row, 12)
						local st = create("UIStroke", { Color = col, Thickness = 1.2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, row)
						local mdl = create("Frame", { Position = UDim2.fromOffset(9, 11), Size = UDim2.fromOffset(60, 60), BorderSizePixel = 0, Th = { BackgroundColor3 = "Black" } }, row)
						corner(mdl, 10)
						stroke(mdl, "CardLine", 1)
						buildEggModel(mdl, egg)
						text(row, { Position = UDim2.fromOffset(80, 5), Size = UDim2.new(1, -160, 0, 20), FontFace = F.Bold, Text = egg.name, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd })
						local function line(y, col2)
							return text(row, { Position = UDim2.fromOffset(80, y), Size = UDim2.new(1, -150, 0, 16), TextSize = 11, RichText = true, Col = col2 or "Sub", TextTruncate = Enum.TextTruncate.AtEnd })
						end
						local r = { frame = row, egg = egg, stroke = st }
						r.line2, r.line3, r.line4 = line(24), line(41), line(58)
						r.join = create("TextButton", {
							AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(60, 30), AutoButtonColor = false,
							FontFace = F.Bold, Text = "Join", TextSize = 13, BackgroundColor3 = T.Accent, TextColor3 = T.OnAccent,
						}, row)
						corner(r.join, 8)
						r.join.Activated:Connect(function() safe(obj.OnJoin, r.egg) end)
						return r
					end)
				end

				function obj:Set(eggs)
					lastList = eggs
					local seen = {}
					for i, egg in ipairs(eggs) do
						seen[egg.key] = true
						local r = rows[egg.key]
						if not r then
							r = buildRow(egg)
							rows[egg.key] = r
						end
						if r then
							r.egg = egg
							r.frame.LayoutOrder = i
							updateRow(r)
						end
					end
					for key, r in pairs(rows) do
						if not seen[key] then -- яйца больше нет на сервере -> убираем из списка
							r.frame:Destroy()
							rows[key] = nil
						end
					end
					empty.Visible = (#eggs == 0)
				end

				local function rebuild()
					for key, r in pairs(rows) do r.frame:Destroy() rows[key] = nil end
					obj:Set(lastList)
				end
				table.insert(themeListeners, rebuild)
				table.insert(tickers, function()
					for _, r in pairs(rows) do updateRow(r) end
				end)
				return obj
			end

			return section
		end

		return tab
	end

	-- Принудительно выдать/забрать доступ владельца (например, после своей проверки)
	local ownerTabs = {}
	function api:RegisterOwnerTab(tab) table.insert(ownerTabs, tab) tab:SetVisible(api.IsOwner) end
	function api:SetOwner(v)
		api.IsOwner = v and true or false
		for _, t in ipairs(ownerTabs) do t:SetVisible(api.IsOwner) end
		api:Log(api.IsOwner and "[OWNER] access granted" or "[OWNER] access removed")
	end

	api:Log("Sterling Engine Ready")
	api:Log(isOwner and "[OWNER] access granted" or ("[OWNER] no access (" .. player.Name .. " / " .. player.UserId .. ")"))
	setOpen(true)
	return api
end

-- ============================================================================
-- НАСТРОЙКИ И СОЗДАНИЕ МЕНЮ
-- ============================================================================
local Options = {
	-- Theme = "Spooky",                      -- стартовая тема
	-- Icon = "rbxassetid://0",               -- твоя иконка
	-- Wallpaper = "rbxassetid://0",
	-- ВЛАДЕЛЬЦЫ: можно UserId (число или строка) и/или username. Строка НЕ должна быть закомментирована!
	Owners = { 1234567890, "YourUsername" },
	-- ChatUrl = "wss://your-server/chat",    -- Global Live Chat (WebSocket)
	-- OnChatSend = function(msg) end,
	-- OnForumPost = function(title, body) end,
	-- GetOnlineUsers = function() return 0 end,

	-- EGG FINDER ---------------------------------------------------------------
	-- EggFeedUrl = "https://your-api/eggs",   -- JSON: { "eggs": [ { id, jobId, placeId, name, rarity, mutation, traits, weight, spawnedAt } ] }
	-- FetchEggs = function() return {} end,   -- или свой источник (таблица яиц)
	-- EggImages = { ["Dragon Egg"] = "rbxassetid://0" },  -- картинки, если модели нет в ReplicatedStorage
	-- EggScore = function(egg) return egg.weight end,     -- своя формула "лучшего" яйца
}

local Window = Sterling.new(Options)

-- 1. FEATURES -------------------------------------------------------------------
local Features = Window:Tab("Features")
local place = Features:Section("Place Info")
place:PlaceCard()
place:Stat("Place ID", function() return game.PlaceId end, true)
place:Stat("Game ID", function() return game.GameId end, true)
place:Stat("Players", function() return #Players:GetPlayers() .. " / " .. Players.MaxPlayers end)
place:Stat("Created", function() return Window.PlaceInfo and Window.PlaceInfo.Created or "..." end)
place:Stat("Updated", function() return Window.PlaceInfo and Window.PlaceInfo.Updated or "..." end)
place:Stat("Job ID", function() return game.JobId ~= "" and string.sub(game.JobId, 1, 13) or "Studio" end, true)

local me = Features:Section("User Info", "user")
local lp = Players.LocalPlayer
me:UserCard()
me:Stat("Username", function() return lp.Name end, true)
me:Stat("User ID", function() return lp.UserId end, true)
me:Stat("Account Age", function() return lp.AccountAge .. " days" end)
me:Stat("Membership", function() return lp.MembershipType == Enum.MembershipType.Premium and "Premium" or "Standard" end)
me:Stat("Device", deviceName)
me:Stat("Executor", executorName)

-- 2. MAIN / AUTOMATION / MISC / PETS ------------------------------------------------------
-- Вкладки создаются здесь (порядок в меню сохраняется), а наполняются функциями
-- в блоке InstallFunctions в самом конце файла.
local FTabs = {}
local FuncHooks = {}   -- связь вкладки Performance с функциями (Low Graphics / Reduce Effects)
for _, name in ipairs({ "Main", "Automation", "Misc", "Pets" }) do
	FTabs[name] = Window:Tab(name)
end

-- 3. SERVER ----------------------------------------------------------------------------
local Server = Window:Tab("Server")
local sstat = Server:Section("Server Statistics")
sstat:Stat("Players", function() return #Players:GetPlayers() .. " / " .. Players.MaxPlayers end)
sstat:Stat("Ping", function() return Window.Perf.ping .. " ms" end)
sstat:Stat("FPS", function() return Window.Perf.fps end)
sstat:Stat("Server Uptime", function() return fmtTime(workspace.DistributedGameTime) end)
sstat:Stat("Place Version", function() return game.PlaceVersion end)
sstat:Stat("Job ID", function() return game.JobId ~= "" and string.sub(game.JobId, 1, 13) or "Studio" end, true)

local sact = Server:Section("Server Actions", "zap")
local function hop(mode, label)
	Window:Notify("Searching: " .. label .. "...")
	task.spawn(function()
		local s, err = ServerTools.Find(mode)
		if not s then
			Window:Notify(err or "Failed")
			return
		end
		Window:Notify(string.format("Joining server (%d players)", s.playing))
		ServerTools.Join(s)
	end)
end
sact:Button("Server Hop", function() hop("random", "random server") end)
sact:Button("Rejoin", function() Window:Notify("Rejoining...") ServerTools.Rejoin() end)
sact:Button("Join 1 Player Server", function() hop("smallest", "smallest server") end)

-- 4. FINDER: лучшие яйца со всех серверов (только Ethereal / Admin) ---------------------------
local Finder = Window:Tab("Finder")
local fsec = Finder:Section("Egg Finder")
local refreshEggs

local fRarity = fsec:Dropdown("Rarity", { "Ethereal + Admin", "Ethereal", "Admin" }, "Ethereal + Admin", function() refreshEggs() end)
local fSort = fsec:Dropdown("Sort", { "Best Score", "Heaviest", "Newest" }, "Best Score", function() refreshEggs() end)
local fMinW = fsec:Slider("Min Weight kg", 0, 100, 0, function() refreshEggs() end, 1)
local fMut = fsec:Toggle("Only Mutated", false, function() refreshEggs() end)
local fAuto = fsec:Toggle("Auto Refresh", true)
local fEvery = fsec:Slider("Refresh Every s", 3, 60, 5, nil, 1)
local fAJ = fsec:Toggle("Auto Join Best", false)
local fLocal = fsec:Toggle("Scan This Server", true)
fsec:Button("Refresh Now", function() task.spawn(refreshEggs) end)
local eggsShown, lastEggUpdate = 0, 0
fsec:Stat("Eggs Listed", function() return eggsShown end)
fsec:Stat("Last Update", function() return lastEggUpdate > 0 and os.date("%H:%M:%S", lastEggUpdate) or "-" end)
local eggList = fsec:EggList(330)

local function normalizeEgg(e)
	local traits = e.traits or e.Traits or {}
	if typeof(traits) == "string" then
		local t = {}
		for part in string.gmatch(traits, "[^,]+") do
			table.insert(t, (part:gsub("^%s+", ""):gsub("%s+$", "")))
		end
		traits = t
	end
	local mut = e.mutation or e.Mutation or e.EggMutation or "None"
	if mut == "" then mut = "None" end
	local egg = {
		id = e.id or e.Id,
		jobId = tostring(e.jobId or e.JobId or game.JobId),
		placeId = tonumber(e.placeId or e.PlaceId) or game.PlaceId,
		name = tostring(e.name or e.Name or "Egg"),
		rarity = tostring(e.rarity or e.Rarity or "Unknown"),
		mutation = tostring(mut),
		traits = traits,
		weight = tonumber(e.weight or e.Weight) or 0,
		spawnedAt = tonumber(e.spawnedAt or e.SpawnedAt or e.spawnTime) or os.time(),
	}
	egg.key = tostring(egg.id or (egg.jobId .. ":" .. egg.name .. ":" .. egg.spawnedAt .. ":" .. egg.weight))
	return egg
end

local function eggScore(e)
	if typeof(Options.EggScore) == "function" then
		local ok, v = pcall(Options.EggScore, e)
		if ok and tonumber(v) then return tonumber(v) end
	end
	local s = e.weight > 0 and e.weight or 1
	if e.mutation ~= "None" then s *= 1.5 end
	s *= 1 + 0.2 * #e.traits
	if string.lower(e.rarity) == "admin" then s *= 1.25 end
	return math.floor(s * 10 + 0.5) / 10
end

-- Яйца текущего сервера: Model с "egg" в имени и атрибутом Rarity (подстрой под свою игру)
local localIds, localCounter, localCache, localCacheAt = setmetatable({}, { __mode = "k" }), 0, {}, 0
local function scanLocalEggs()
	if os.clock() - localCacheAt < 15 then return localCache end
	local out = {}
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Model") and string.find(string.lower(inst.Name), "egg") and inst:GetAttribute("Rarity") then
			local info = localIds[inst]
			if not info then
				localCounter += 1
				info = { id = game.JobId .. ":L" .. localCounter, seen = os.time() }
				localIds[inst] = info
			end
			table.insert(out, {
				id = info.id, jobId = game.JobId, placeId = game.PlaceId,
				name = inst:GetAttribute("EggName") or inst.Name, rarity = inst:GetAttribute("Rarity"),
				mutation = inst:GetAttribute("Mutation") or inst:GetAttribute("EggMutation") or "None",
				traits = inst:GetAttribute("Traits") or {}, weight = inst:GetAttribute("Weight") or inst:GetAttribute("Size") or 0,
				spawnedAt = inst:GetAttribute("SpawnTime") or info.seen,
			})
		end
	end
	localCache, localCacheAt = out, os.clock()
	return out
end

local function fetchEggs()
	local out = {}
	local function add(list)
		if typeof(list) ~= "table" then return end
		for _, e in ipairs(list) do
			if typeof(e) == "table" then table.insert(out, normalizeEgg(e)) end
		end
	end
	if typeof(Options.FetchEggs) == "function" then
		local ok, res = pcall(Options.FetchEggs)
		if ok then add(res) end
	end
	if Options.EggFeedUrl then
		local body = ServerTools.HttpGet(Options.EggFeedUrl)
		if body then
			local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
			if ok and typeof(data) == "table" then add(data.eggs or data) end
		end
	end
	if fLocal:Get() then
		local ok, res = pcall(scanLocalEggs)
		if ok then add(res) end
	end
	return out
end

local refreshing = false
refreshEggs = function()
	if refreshing then return end
	refreshing = true
	local all = fetchEggs()
	local mode, minW, onlyMut = fRarity:Get(), fMinW:Get(), fMut:Get()
	local list = {}
	for _, e in ipairs(all) do
		local r = string.lower(e.rarity)
		local okRarity = (mode == "Ethereal + Admin" and (r == "ethereal" or r == "admin")) or r == string.lower(mode)
		if okRarity and e.weight >= minW and (not onlyMut or e.mutation ~= "None") then
			e.score = eggScore(e)
			table.insert(list, e)
		end
	end
	local sortMode = fSort:Get()
	table.sort(list, function(a, b)
		if sortMode == "Heaviest" then return a.weight > b.weight end
		if sortMode == "Newest" then return a.spawnedAt > b.spawnedAt end
		return a.score > b.score
	end)
	eggsShown, lastEggUpdate = #list, os.time()
	eggList:Set(list) -- яйца, которых нет в свежем списке, исчезают автоматически
	if fAJ:Get() and list[1] and list[1].jobId ~= game.JobId then
		local best = list[1]
		fAJ:Set(false)
		Window:Notify(string.format("Auto Join: %s (%s pts)", best.name, tostring(best.score)))
		ServerTools.Join({ id = best.jobId, placeId = best.placeId })
	end
	refreshing = false
end

eggList.OnJoin = function(egg)
	if egg.jobId == game.JobId then
		Window:Notify("You are already on this server")
		return
	end
	Window:Notify(string.format("Joining %s (%.2f kg)...", egg.name, egg.weight))
	ServerTools.Join({ id = egg.jobId, placeId = egg.placeId })
end

local eggTimer = 0
Window:OnTick(function()
	if not fAuto:Get() then return end
	eggTimer += 1
	if eggTimer >= fEvery:Get() then
		eggTimer = 0
		task.spawn(refreshEggs)
	end
end)
task.spawn(refreshEggs)

-- 5. Events ---------------------------------------------------------------------------------
local Events = Window:Tab("Events")
Events:Section("Events"):Label("Empty for now. Event timers and notifications will live here.")

-- 6. GLOBAL LIVE CHAT ------------------------------------------------------------------------
local Chat = Window:Tab("Live Chat")
Chat:Section("Global Live Chat"):Chat(310)

-- 7. FORUM (сохраняется) -----------------------------------------------------------------------
local Forum = Window:Tab("Forum")
Forum:Section("Community Forum"):Forum(340)

-- 8. WINDOWS -----------------------------------------------------------------------------------------
local Windows = Window:Tab("Windows")
local wsec = Windows:Section("Floating Windows")
local wFps = Window:Widget("Performance", {
	{ "FPS", function() return Window.Perf.fps end },
	{ "Ping", function() return Window.Perf.ping .. " ms" end },
})
local wServer = Window:Widget("Server", {
	{ "Players", function() return #Players:GetPlayers() .. "/" .. Players.MaxPlayers end },
	{ "Uptime", function() return fmtTime(workspace.DistributedGameTime) end },
})
local wSession = Window:Widget("Session", {
	{ "Time", function() return fmtTime(os.clock() - Window.Perf.start) end },
	{ "Avg FPS", function() return Window.Perf.avgFps end },
})
wsec:Toggle("Performance", false, function(v) wFps:SetVisible(v) end)
wsec:Toggle("Server Info", false, function(v) wServer:SetVisible(v) end)
wsec:Toggle("Session", false, function(v) wSession:SetVisible(v) end)
wsec:Button("Reset Positions", function() wFps.Reset() wServer.Reset() wSession.Reset() end)
wsec:Label("Floating windows can be dragged anywhere on the screen.")

-- 9. STATISTICS ------------------------------------------------------------------------------------------
local Statistics = Window:Tab("Statistics")
local sess = Statistics:Section("Session")
sess:Stat("Session Time", function() return fmtTime(os.clock() - Window.Perf.start) end)
sess:Stat("Average FPS", function() return Window.Perf.avgFps end)
sess:Stat("Lowest FPS", function() return Window.Perf.minFps == math.huge and "-" or Window.Perf.minFps end)
sess:Stat("Average Ping", function() return Window.Perf.avgPing .. " ms" end)
sess:Stat("Peak Players", function() return Window.Perf.peakPlayers end)
sess:Stat("Chat Messages", function() return Window.ChatCount() end)

-- 10. PERFORMANCE ------------------------------------------------------------------------------------------
local Performance = Window:Tab("Performance")
local live = Performance:Section("Live Monitor")
live:Stat("FPS", function() return Window.Perf.fps end)
live:Stat("Ping", function() return Window.Perf.ping .. " ms" end)
live:Stat("Memory", function() return Window.Perf.memory .. " MB" end)
live:Graph("FPS", function() return Window.Perf.fps end, 120, " FPS")
live:Graph("Ping", function() return Window.Perf.ping end, 300, " ms")
local popt = Performance:Section("Options", "sliders-horizontal")
popt:Toggle("Low Graphics", false, function(v) if FuncHooks.FPSBoost then FuncHooks.FPSBoost(v) end end)
popt:Dropdown("Low Graphics Lv", { "1", "2", "3", "4", "5" }, "1", function(v) if FuncHooks.FPSBoostLevel then FuncHooks.FPSBoostLevel(tonumber(v)) end end)
popt:Dropdown("FPS Limit", { "Off", "30", "60", "120" }, "Off", function(v) --[[ твоя логика ]] end)
popt:Toggle("Reduce Effects", false, function(v) if FuncHooks.AntiLag then FuncHooks.AntiLag(v) end end)
popt:Dropdown("Reduce Effects Lv", { "1", "2", "3", "4", "5" }, "1", function(v) if FuncHooks.AntiLagLevel then FuncHooks.AntiLagLevel(tonumber(v)) end end)

-- 11. CONFIG --------------------------------------------------------------------------------------------------
local Config = Window:Tab("Config")
local ui = Config:Section("Interface")
ui:Slider("UI Scale %", 60, 130, 100, function(v) Window:SetScale(v / 100) end, 5)
local hudDd = ui:Dropdown("HUD Style", Window:ThemeNames(), Options.Theme or "Smoky Dark", function(v) Window:SetHud(v, true) end)
Window.OnHudChanged = function(name) hudDd:Set(name, true) end -- кнопка Change Hud синхронизирует выпадающий список
ui:Toggle("Notifications", true, function(v) Window.Notifications = v end)
ui:Toggle("Activity Log", true, function(v) Window:SetLogVisible(v) end)
ui:Toggle("Show Launcher", true, function(v) Window:SetLauncherVisible(v) end)
local prof = Config:Section("Profile", "user-cog")
local cfgName = prof:Input("Config Name", "Config name", nil, "default")
prof:Button("Save Config", function()
	Window:Notify(Window:SaveConfig(cfgName:Get()) and "Config saved" or "Save failed")
end)
prof:Button("Load Config", function()
	Window:Notify(Window:LoadConfig(cfgName:Get()) and "Config loaded" or "Config not found")
end)
prof:Button("Reset Config", function()
	Window:ResetConfig()
	Window:Notify("Settings reset")
end)

-- 12. KEYBIND ------------------------------------------------------------------------------------------------------
local Keybind = Window:Tab("Keybind")
local kb = Keybind:Section("Menu Keys")
kb:Keybind("Toggle Menu", Enum.KeyCode.RightShift, nil, function(key) Window:SetToggleKey(key) end)
kb:Keybind("Panic Hide", Enum.KeyCode.Delete, function() Window:PanicToggle() end)
kb:Label("Click a key button, then press the new key. Escape clears the bind. Panic Hide hides everything, including the launcher.")
local custom = Keybind:Section("Your Keybinds")
custom:Label("Add your own with section:Keybind(name, KeyCode, onPress, onChange).")

-- 13. PANEL (только owner; вкладка создаётся всегда и прячется, если ты не владелец) ----------------------------------------
local Panel = Window:Tab("Panel")
Window:RegisterOwnerTab(Panel)

local ann = Panel:Section("Owner Announcement")
local annBox = ann:Input("Announcement", "Write an announcement...")
local annAmount = ann:Input("Duration", "Amount, e.g. 10", nil, "10")
local annUnit = ann:Dropdown("Unit", { "Seconds", "Minutes", "Hours", "Until next hour" }, "Minutes")
ann:Button("Send", function()
	local msg = annBox:Get()
	if msg == "" then
		Window:Notify("Write a message first")
		return
	end
	local unit, secs = annUnit:Get(), nil
	if unit == "Until next hour" then
		secs = secondsToNextHour() -- ровно до следующего XX:00
	else
		local n = tonumber(annAmount:Get())
		if not n or n <= 0 then
			Window:Notify("Enter a valid duration")
			return
		end
		secs = n * (unit == "Seconds" and 1 or unit == "Minutes" and 60 or 3600)
	end
	Window:SendAnnouncement(msg, secs)
	annBox:Set("")
end)
ann:Stat("Next XX:00 In", function() return fmtDur(secondsToNextHour()) end)
ann:Button("Clear Forum", function()
	Window:ForumClear()
	Window:Notify("Forum cleared")
end)

local ostat = Panel:Section("Owner Statistics", "chart-column")
ostat:Stat("Users Online", function()
	return typeof(Options.GetOnlineUsers) == "function" and Options.GetOnlineUsers() or "-"
end)
ostat:Stat("Chat Messages", function() return Window.ChatCount() end)
ostat:Stat("Server Players", function() return #Players:GetPlayers() end)


-- ============================================================================
-- ФУНКЦИИ (перенесены из SterlingEngineFunctions: без его меню и разделов)
-- ============================================================================
local function InstallFunctions(Window, FTabs, FuncHooks)
local UserInputService = UIS
local LocalPlayer = Players.LocalPlayer
local Runtime = { Remotes = {} }
-- ScreenGui: окно этого меню (логика кликов по GUI игры его пропускает)
local ScreenGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("SterlingEngineExclusive") or Instance.new("Folder")

local function notify(msg)
    pcall(function() Window:Notify(msg) end)
end

-- Выгружаем предыдущую копию функций, если скрипт запущен повторно
if _G.SterlingEngine and _G.SterlingEngine.Unload then
    pcall(_G.SterlingEngine.Unload)
end

local Alive = true
local Connections = {}
local function on(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Connections, conn)
    return conn
end

-- Обёртка: присваивание proxy.Text = "..." обновляет строку (Label) в меню
local function labelProxy(label)
    return setmetatable({}, { __newindex = function(_, key, value)
        if key == "Text" then label:Set(tostring(value)) end
    end })
end

--========================= SAVE (только история краж) =========================--
local Storage = { Dir = "Sterling Engine" }
Storage.History = Storage.Dir .. "/steal-history.json"


function Storage.hasFileApi()
    return writefile ~= nil and readfile ~= nil and isfile ~= nil
end

function Storage.ensureDir()
    if not Storage.hasFileApi() then return end
    if isfolder and makefolder then
        pcall(function()
            if not isfolder(Storage.Dir) then
                makefolder(Storage.Dir)
            end
        end)
    end
end

function Storage.readJson(path)
    if not Storage.hasFileApi() or not isfile(path) then return nil end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

function Storage.writeJson(path, data)
    if not Storage.hasFileApi() then return end
    Storage.ensureDir()
    pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
end

function Storage.loadHistory()
    local history = Storage.readJson(Storage.History) or {}
    local now = os.time and os.time() or math.floor(workspace:GetServerTimeNow())
    local fresh = {}
    for _, entry in ipairs(history) do
        if type(entry) == "table" and now - (tonumber(entry.timestamp) or 0) <= 432000 then
            table.insert(fresh, entry)
        end
    end
    if #fresh ~= #history then
        Storage.writeJson(Storage.History, fresh)
    end
    return fresh
end

function Storage.saveHistory(history)
    Storage.writeJson(Storage.History, history)
end


--========================= EGG DATA =========================--
local EGG_DB = {
    ["White Egg"]    = { Rarity = "Common",    Luck = 1 },
    ["Brown Egg"]    = { Rarity = "Common",    Luck = 5 },
    ["Cracked Egg"]  = { Rarity = "Rare",      Luck = 30 },
    ["Easter Egg"]   = { Rarity = "Rare",      Luck = 50 },
    ["Stone Egg"]    = { Rarity = "Rare",      Luck = 100 },
    ["Leaf Egg"]     = { Rarity = "Rare",      Luck = 200 },
    ["Mushroom Egg"] = { Rarity = "Epic",      Luck = 500 },
    ["Flower Egg"]   = { Rarity = "Epic",      Luck = 750 },
    ["Slime Egg"]    = { Rarity = "Epic",      Luck = 1000 },
    ["Ice Egg"]      = { Rarity = "Epic",      Luck = 3000 },
    ["Glass Egg"]    = { Rarity = "Legendary", Luck = 10000 },
    ["Golden Egg"]   = { Rarity = "Legendary", Luck = 30000 },
    ["Diamond Egg"]  = { Rarity = "Mythic",    Luck = 90000 },
    ["Crystal Egg"]  = { Rarity = "Mythic",    Luck = 150000 },
    ["Skull Egg"]    = { Rarity = "Mythic",    Luck = 250000 },
    ["Asteroid Egg"] = { Rarity = "Mythic",    Luck = 500000 },
    ["Dominus Egg"]  = { Rarity = "Mythic",    Luck = 700000 },
    ["Flaming Egg"]  = { Rarity = "Mythic",    Luck = 1000000 },
    ["Sinister Egg"] = { Rarity = "Mythic",    Luck = 3000000 },
    ["Soul Egg"]     = { Rarity = "Mythic",    Luck = 7000000 },
    ["Tidal Egg"]    = { Rarity = "Mythic",    Luck = 8000000 },
    ["Aurora Egg"]   = { Rarity = "Divine",    Luck = 300000000 },
    ["Galaxy Egg"]   = { Rarity = "Divine",    Luck = 1500000000 },
    ["Bloom Egg"]    = { Rarity = "Divine",    Luck = 2000000000 },
    ["Blackhole Egg"]  = { Rarity = "Ethereal", Luck = 210000000000 },
    ["Solaris Egg"]    = { Rarity = "Ethereal", Luck = 363000000000 },
    ["Cherub Egg"]     = { Rarity = "Ethereal", Luck = 1000000000000 },
    ["Volcanic Egg"]   = { Rarity = "Ethereal", Luck = 2500000000000 },
    ["Seraph Egg"]     = { Rarity = "Ethereal", Luck = 3000000000000 },
    ["Halloween Egg"]  = { Rarity = "Ethereal", Luck = 1000000000000 },
}
Runtime.EggPriority = {
    ["Seraph Egg"] = 6,
    ["Volcanic Egg"] = 5,
    ["Halloween Egg"] = 4,
    ["Cherub Egg"] = 3,
    ["Solaris Egg"] = 2,
    ["Blackhole Egg"] = 1,
}

local RARITY_ORDER = {
    Common = 1, Rare = 2, Epic = 3, Legendary = 4,
    Mythic = 5, Divine = 6, Ethereal = 7, Event = 8, Unknown = 0,
}

local RARITY_COLOR = {
    Common    = Color3.fromRGB(214, 214, 214),
    Rare      = Color3.fromRGB(150, 196, 230),
    Epic      = Color3.fromRGB(196, 170, 230),
    Legendary = Color3.fromRGB(230, 214, 160),
    Mythic    = Color3.fromRGB(230, 170, 186),
    Divine    = Color3.fromRGB(236, 230, 196),
    Ethereal  = Color3.fromRGB(176, 230, 214),
    Event     = Color3.fromRGB(255, 255, 255),
    Unknown   = Color3.fromRGB(180, 180, 180),
}

local EggsData, GeneralData, PetsData, PetAging, FoodData
local GameRemotes
local ActiveEggs
local EggPickup
local BasketDrop

task.spawn(function()
    local gameData = ReplicatedStorage:WaitForChild("GameData", 12)
    local gameServices = ReplicatedStorage:FindFirstChild("GameServices")
    if gameData then
        pcall(function() EggsData = require(gameData:WaitForChild("Eggs", 8)) end)
        pcall(function() GeneralData = require(gameData:WaitForChild("General", 8)) end)
        pcall(function() PetsData = require(gameData:WaitForChild("Pets", 8)) end)
        for _, foodName in ipairs({ "Food", "Foods", "FoodData", "Items" }) do
            local foodModule = gameData:FindFirstChild(foodName)
            if foodModule and foodModule:IsA("ModuleScript") then
                local ok, data = pcall(require, foodModule)
                if ok and type(data) == "table" then
                    FoodData = data
                    break
                end
            end
        end
    end
    if gameServices then
        pcall(function() PetAging = require(gameServices:WaitForChild("PetAging", 8)) end)
    end
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 12)
    if remotes then
        GameRemotes = remotes:WaitForChild("Game", 8)
        if GameRemotes then
            EggPickup = GameRemotes:FindFirstChild("EggPickup")
            BasketDrop = GameRemotes:FindFirstChild("BasketDrop")
            local gameNames = {
                "Hatch", "EggPickup", "EggPlaced", "EggBroke", "BuyHalloweenEgg",
                "PickupPet", "PlacePet", "PetCollect", "PlaceBest", "FeedPet",
                "FavoritePet", "NamePet", "CheckPetName", "FusionAction", "FusionPetPlace",
                "BuyWithCash", "SellItems", "ClaimEventReward", "ClaimIndexReward",
                "OfflineEarnings", "Restock", "OpenProducts", "OpenStockShop", "ShopStock",
                "TeleportToPlot", "UpdateSetting", "Rebirth", "CollectCandy", "DropCandy",
                "CandyState", "DigGrave", "SearchPumpkin", "PumpkinState", "GiantPumpkin",
                "GiantPumpkinHit", "GiantPumpkinSwing", "HalloweenRace", "KnockDoor",
                "ActivateRadar", "RadarState", "SkipGrowth", "SyncCollectTimes", "GetCandyState",
                "VolcanoDip", "VolcanoDipResult", "BasketDrop",
            }
            for _, remoteName in ipairs(gameNames) do
                Runtime.Remotes[remoteName] = GameRemotes:FindFirstChild(remoteName, true)
            end
            local reusable = remotes:FindFirstChild("Reusable")
            if reusable then
                for _, remoteName in ipairs({
                    "Purchase", "PromptPurchase", "OpenBuyPrompt", "GetPlayerData", "InitiatePlot",
                }) do
                    Runtime.Remotes[remoteName] = reusable:FindFirstChild(remoteName, true)
                end
            end
            local plotRemotes = GameRemotes:FindFirstChild("Plot")
            if plotRemotes then
                Runtime.Remotes.Nests = plotRemotes:FindFirstChild("Nests")
                Runtime.Remotes.Upgrades = plotRemotes:FindFirstChild("Upgrades")
            end
        end
    end
    ActiveEggs = ReplicatedStorage:WaitForChild("ServerData", 12)
    ActiveEggs = ActiveEggs and ActiveEggs:FindFirstChild("ActiveEggs") or ActiveEggs
end)


local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(180, 180, 180)
    s.Thickness = thickness or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.PaddingLeft = UDim.new(0, px)
    p.PaddingRight = UDim.new(0, px)
    p.Parent = parent
    return p
end


--========================= STATE =========================--
local SpeedValue = 800
local AutoDip = false
local WorldEsp = true
local NotifyOn = true
local VOLCANO_POS = Vector3.new(-5112.81, 41441.30, -3445.27)
local Job = { busy = false, eggId = nil, status = "Idle", token = 0, row = nil }
local refreshNote
local showEggModel
local Modes = {}
local Cards = {}
local EspMarks = {}
local LastPickup = nil
local Flight = nil
Runtime.DipSerial = 0
Runtime.DipResult = nil


Runtime.PlatformConfig = { speed = 800, enabled = false, rarity = "Rare" }
Runtime.AutoFarmConfig = { enabled = false, rarity = "Rare", volcanoDip = false }
Runtime.RaceConfig = { enabled = false }


--========================= MAIN: управление =========================--
local StatusLabel = { Text = "" }
local EmptyLabel, EggList
do
    local main = FTabs.Main
    local ctl = main:Section("Controls", "zap")
    ctl:Slider("Speed", 100, 3000, SpeedValue, function(v)
        SpeedValue = math.clamp(math.floor(v + 0.5), 100, 3000)
    end, 50)
    ctl:Toggle("Auto Volcanic Dip", false, function(v)
        AutoDip = v
    end)
    ctl:Toggle("World ESP", WorldEsp, function(v)
        WorldEsp = v
        if not v then
            for _, mark in pairs(EspMarks) do
                if mark.part then mark.part:Destroy() end
            end
            table.clear(EspMarks)
        end
    end)
    StatusLabel = labelProxy(ctl:Label("Status: Idle"))

    local eggSec = main:Section("Eggs", "egg")
    EggList = eggSec:Block(0)
    EggList.AutomaticSize = Enum.AutomaticSize.Y
    create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, EggList)
    EmptyLabel = text(EggList, {
        Size = UDim2.new(1, 0, 0, 22), Text = "Waiting for egg spawns", Col = "Dim", TextSize = 13, LayoutOrder = 0,
    })
end


--========================= FORMAT / SCAN =========================--
local function formatNumber(n)
    n = tonumber(n) or 0
    local sign = n < 0 and "-" or ""
    n = math.abs(n)
    local units = {
        { 1e12, "T" },
        { 1e9, "B" },
        { 1e6, "M" },
        { 1e3, "K" },
    }
    for _, unit in ipairs(units) do
        if n >= unit[1] then
            return string.format("%s%.2f%s", sign, n / unit[1], unit[2])
        end
    end
    if n >= 100 then
        return sign .. string.format("%.0f", n)
    end
    return sign .. string.format("%.2f", n):gsub("%.?0+$", "")
end

local function eggDef(name)
    if EggsData and EggsData[name] then
        return EggsData[name]
    end
    return nil
end

local function eggMeta(name)
    local data = eggDef(name)
    local db = EGG_DB[name]
    local rarity = (db and db.Rarity) or (data and data.Rarity) or "Unknown"
    local luck = (db and db.Luck) or (data and data.Luck) or 0
    return rarity, luck, data
end

local function readMutation(obj)
    if not obj then return "None" end
    local mutation = obj:GetAttribute("Mutation")
    local spawn = obj:GetAttribute("SpawnMutation")
    local label = (type(mutation) == "string" and mutation ~= "" and mutation) or "None"
    if type(spawn) == "string" and spawn ~= "" and spawn ~= mutation then
        if label == "None" then
            label = spawn
        else
            label = label .. " + " .. spawn
        end
    end
    return label
end

local function readTraits(obj)
    if not obj then return "-" end
    local direct = obj:GetAttribute("Traits") or obj:GetAttribute("Trait")
    if type(direct) == "string" and direct ~= "" then
        return direct
    end
    local parts = {}
    for name, value in pairs(obj:GetAttributes()) do
        local lower = string.lower(name)
        if string.find(lower, "trait", 1, true) and tostring(value) ~= "" and string.lower(name) ~= "mutation" then
            table.insert(parts, name .. ": " .. tostring(value))
        end
    end
    if #parts == 0 then
        return "-"
    end
    return table.concat(parts, ", ")
end

local function readKG(obj)
    local raw = obj:GetAttribute("Weight") or obj:GetAttribute("KG") or 1
    if GeneralData and GeneralData.ShownEggKG then
        local ok, shown = pcall(GeneralData.ShownEggKG, GeneralData, raw)
        if not ok then
            ok, shown = pcall(GeneralData.ShownEggKG, raw)
        end
        if ok and shown ~= nil then
            return shown
        end
    end
    return raw
end

local function iconFor(name, data)
    if type(data) == "table" then
        for _, key in ipairs({ "Icon", "Image", "Thumbnail", "ImageId", "IconId" }) do
            local v = data[key]
            if type(v) == "string" and v ~= "" then
                return v
            elseif type(v) == "number" then
                return "rbxassetid://" .. tostring(v)
            end
        end
    end
    return nil
end

local claimCache = { raw = nil, map = {} }
local function claimedCycles()
    local raw = LocalPlayer:GetAttribute("CollectedEggCycles")
    if claimCache.raw ~= raw then
        claimCache.raw = raw
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(raw or "{}")
        end)
        claimCache.map = (ok and type(decoded) == "table") and decoded or {}
    end
    return claimCache.map
end

local function eggClaimed(obj, name)
    if obj:GetAttribute("AdminSpawn") == true then
        local id = obj:GetAttribute("AdminEggId")
        local list = LocalPlayer:GetAttribute("CollectedAdminEggs")
        if type(id) == "string" and type(list) == "string" then
            return string.find(list, "," .. id .. ",", 1, true) ~= nil
        end
        return false
    end
    local cycle = tonumber(obj:GetAttribute("Cycle"))
    local claimed = tonumber(claimedCycles()[name])
    if cycle and claimed then
        return cycle <= claimed
    end
    local list = LocalPlayer:GetAttribute("CollectedEggs")
    if type(list) == "string" and name ~= "" then
        return string.find(list, name .. ",", 1, true) ~= nil or string.find("," .. list .. ",", "," .. name .. ",", 1, true) ~= nil
    end
    return false
end

local function setStatus(text, eggId)
    Job.status = text
    if eggId then
        Job.eggId = eggId
    end
    StatusLabel.Text = "Status: " .. text
    local id = eggId or Job.eggId
    local card = id and Cards[id]
    if card and card.status then
        card.status.Text = text
    end
    if refreshNote then
        refreshNote()
    end
end

local function scanEggs()
    local folder = ActiveEggs
    if not folder or not folder.Parent then
        local serverData = ReplicatedStorage:FindFirstChild("ServerData")
        folder = serverData and serverData:FindFirstChild("ActiveEggs")
        ActiveEggs = folder
    end
    if not folder then
        return {}
    end
    local now = workspace:GetServerTimeNow()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local rows = {}
    for _, obj in ipairs(folder:GetChildren()) do
        local name = tostring(obj:GetAttribute("Egg") or obj.Name)
        if name == "Black Hole Egg" then name = "Blackhole Egg" end
        local pos = obj:GetAttribute("Position")
        if typeof(pos) == "Vector3" then
            local priv = obj:GetAttribute("PrivateTo")
            local privOk = priv == nil or priv == LocalPlayer.UserId or tostring(priv) == tostring(LocalPlayer.UserId)
            if privOk and not eggClaimed(obj, name) then
                local rarity, luck, data = eggMeta(name)
                local dropEnd = tonumber(obj:GetAttribute("DropEndsAt")) or 0
                local admin = obj:GetAttribute("AdminSpawn") == true
                local rarityText = rarity
                if admin then
                    rarityText = rarity .. " / Admin"
                end
                table.insert(rows, {
                    Id = obj.Name,
                    Object = obj,
                    Name = name,
                    Position = pos,
                    Rarity = rarity,
                    RarityText = rarityText,
                    Luck = luck,
                    KG = readKG(obj),
                    Mutation = readMutation(obj),
                    Traits = readTraits(obj),
                    Icon = iconFor(name, data),
                    Distance = root and (root.Position - pos).Magnitude or 0,
                    Spawning = dropEnd > now,
                    Admin = admin,
                    SourcePlayer = obj:GetAttribute("OwnerName")
                        or obj:GetAttribute("StolenFrom")
                        or obj:GetAttribute("Owner")
                        or "Unknown",
                })
            end
        end
    end
    table.sort(rows, function(a, b)
        local specialA = Runtime.EggPriority[a.Name] or 0
        local specialB = Runtime.EggPriority[b.Name] or 0
        if specialA ~= specialB then
            return specialA > specialB
        end
        local ra = RARITY_ORDER[a.Rarity] or 0
        local rb = RARITY_ORDER[b.Rarity] or 0
        if ra ~= rb then
            return ra > rb
        end
        if a.Luck ~= b.Luck then
            return a.Luck > b.Luck
        end
        return a.Name < b.Name
    end)
    return rows
end

--========================= MOVEMENT / STEAL =========================--
local function character()
    local char = Runtime.OriginalCharacter and Runtime.OriginalCharacter.Parent
        and Runtime.OriginalCharacter or LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then
        return char, hum, root
    end
    return nil, nil, nil
end

function Runtime.CreateControlClone(position, owner)
    if Runtime.ControlClone and Runtime.ControlClone.Parent then
        return Runtime.ControlClone
    end
    local original = LocalPlayer.Character
    if not original then return nil end
    Runtime.OriginalCharacter = original
    Runtime.CloneOwner = owner
    original.Archivable = true
    local ok, clone = pcall(function() return original:Clone() end)
    if not ok or not clone then return nil end
    clone.Name = "SterlingControlClone"
    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("Tool") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = false
            object.CanCollide = object.Name ~= "HumanoidRootPart"
        end
    end
    clone.Parent = workspace
    clone:PivotTo(CFrame.new(position + Vector3.new(0, 4, 0)))
    Runtime.ControlClone = clone
    pcall(function() LocalPlayer.Character = clone end)
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if workspace.CurrentCamera and humanoid then
        workspace.CurrentCamera.CameraSubject = humanoid
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
    return clone
end

function Runtime.DestroyControlClone(owner)
    if owner and Runtime.CloneOwner and owner ~= Runtime.CloneOwner then return end
    local original = Runtime.OriginalCharacter
    if original and original.Parent then
        pcall(function() LocalPlayer.Character = original end)
        local humanoid = original:FindFirstChildOfClass("Humanoid")
        if workspace.CurrentCamera and humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        end
    end
    if Runtime.ControlClone then Runtime.ControlClone:Destroy() end
    Runtime.ControlClone = nil
    Runtime.CloneOwner = nil
    Runtime.OriginalCharacter = nil
end

local function mountRoot()
    local _, _, root = character()
    if not root then return nil end
    local joint = root:FindFirstChild("PetMountJoint")
    if joint and joint.Part1 and joint.Part1.Parent then
        local model = joint.Part1:FindFirstAncestorOfClass("Model") or joint.Part1.Parent
        local part = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or joint.Part1)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return root
end

local function stopFlight()
    if Flight then
        if Flight.tween then
            pcall(function() Flight.tween:Cancel() end)
        end
        if Flight.conn then
            Flight.conn:Disconnect()
        end
        if Flight.bv and Flight.bv.Parent then
            Flight.bv:Destroy()
        end
        if Flight.alpha and Flight.alpha.Parent then
            Flight.alpha:Destroy()
        end
        if Flight.humanoid and Flight.humanoid.Parent then
            Flight.humanoid.PlatformStand = Flight.platform
            Flight.humanoid.AutoRotate = Flight.auto
            pcall(function()
                Flight.humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
        for part, can in pairs(Flight.collisions or {}) do
            if part and part.Parent then
                part.CanCollide = can
            end
        end
        Flight = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d.Name == "SterlingFly" or d.Name == "SterlingAlpha" then
                d:Destroy()
            end
        end
    end
end

local function collectPhysics(extra)
    local collisions = {}
    local char = LocalPlayer.Character
    local function take(inst)
        if not inst then return end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("BasePart") and collisions[d] == nil then
                collisions[d] = d.CanCollide
            end
        end
    end
    take(char)
    take(extra)
    return collisions
end

local function applyFlightCF(hrp, cf)
    pcall(function()
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        local mount = mountRoot()
        if mount and mount ~= hrp and mount.Parent then
            mount.AssemblyLinearVelocity = Vector3.zero
            mount.AssemblyAngularVelocity = Vector3.zero
            mount.CFrame = cf
        end
    end)
end

local function moveTo(position, mode, exact)
    if not Alive or Job.token == 0 then return false end
    local char, hum, hrp = character()
    if not hrp then return false end
    local lift = exact and 0 or 3
    local goal = position + Vector3.new(0, lift, 0)
    if mode == "Instant" then
        applyFlightCF(hrp, CFrame.new(goal))
        task.wait(0.3)
        return true
    end
    stopFlight()
    local oldPlatform = hum.PlatformStand
    local oldAuto = hum.AutoRotate
    local collisions = collectPhysics(char)
    hum.PlatformStand = true
    hum.AutoRotate = false
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    local bv = Instance.new("BodyVelocity")
    bv.Name = "SterlingFly"
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local alpha = Instance.new("NumberValue")
    alpha.Name = "SterlingAlpha"
    alpha.Value = 0
    alpha.Parent = hrp
    local startPos = hrp.Position
    local dist = (startPos - goal).Magnitude
    local duration = math.max(0.08, dist / math.clamp(SpeedValue, 100, 3000))
    local tween = TweenService:Create(alpha, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = 1 })
    Flight = {
        humanoid = hum,
        platform = oldPlatform,
        auto = oldAuto,
        collisions = collisions,
        tween = tween,
        conn = nil,
        bv = bv,
        alpha = alpha,
    }
    tween:Play()
    local t0 = os.clock()
    Flight.conn = RunService.Heartbeat:Connect(function()
        if not hrp.Parent or not Alive then return end
        for part in pairs(collisions) do
            if part.Parent then
                part.CanCollide = false
            end
        end
        local along = alpha.Value
        if along < 0.01 then
            along = math.clamp((os.clock() - t0) / duration, 0, 1)
        end
        applyFlightCF(hrp, CFrame.new(startPos:Lerp(goal, math.clamp(along, 0, 1))))
        if bv.Parent then
            bv.Velocity = Vector3.zero
        end
    end)
    local deadline = os.clock() + duration + 1.2
    while Alive and hrp.Parent and os.clock() < deadline do
        if alpha.Value >= 0.985 or (os.clock() - t0) >= duration then
            break
        end
        task.wait(0.03)
    end
    applyFlightCF(hrp, CFrame.new(goal))
    stopFlight()
    return true
end

Runtime.InstantTo = function(position)
    local _, _, root = character()
    if not root or typeof(position) ~= "Vector3" then return false end
    stopFlight()
    applyFlightCF(root, CFrame.new(position + Vector3.new(0, 3, 0)))
    task.wait(0.12)
    return true
end

local function basketFolder()
    return LocalPlayer:FindFirstChild("Basket")
end

local function basketHas(eggName, configName)
    local basket = basketFolder()
    if not basket then return false end
    for _, child in ipairs(basket:GetChildren()) do
        local n = tostring(child:GetAttribute("Egg") or child.Name)
        local id = tostring(child:GetAttribute("Config") or child:GetAttribute("ConfigName") or child:GetAttribute("Source") or "")
        if n == eggName or child.Name == configName or id == configName then
            return true
        end
    end
    return false
end

function Runtime.BasketEggCount(eggName)
    local basket = basketFolder()
    local count = 0
    if not basket then return count end
    for _, child in ipairs(basket:GetChildren()) do
        local name = tostring(child:GetAttribute("Egg") or child.Name)
        if name == eggName then
            count = count + 1
        end
    end
    return count
end

function Runtime.BasketHasExact(configName)
    local basket = basketFolder()
    if not basket then return false end
    for _, child in ipairs(basket:GetChildren()) do
        local id = tostring(child:GetAttribute("Config")
            or child:GetAttribute("ConfigName")
            or child:GetAttribute("Source")
            or child:GetAttribute("EggId")
            or "")
        if child.Name == configName or id == configName then
            return true
        end
    end
    return false
end

local function isRiding()
    if LocalPlayer:GetAttribute("IsRiding") == true then
        return true
    end
    local _, _, root = character()
    return root ~= nil and root:FindFirstChild("PetMountJoint") ~= nil
end

local function petScore(obj)
    local speed = tonumber(obj:GetAttribute("Speed")) or tonumber(obj:GetAttribute("DisplaySpeed"))
    if speed then return speed end
    local name = obj:GetAttribute("PetName") or obj.Name
    local weight = tonumber(obj:GetAttribute("Weight")) or 10
    local data = PetsData and PetsData[name]
    if data and PetAging and PetAging.DisplaySpeedFor then
        local ok, value = pcall(PetAging.DisplaySpeedFor, data.Speed or 0, weight)
        if ok and type(value) == "number" then
            return value
        end
    end
    if data then
        return (data.Speed or 0) * 1000 + (data.Income or 0)
    end
    return 0
end

local FOOD_WORDS = {
    "food", "grass", "bone", "berry", "meat", "apple", "carrot", "feed", "fruit",
    "seed", "treat", "cookie", "bait", "wheat", "corn", "fish", "bread", "candy",
    "snack", "meal", "pellet", "hay", "bamboo", "melon", "potion", "kibble",
}

local function isFood(tool)
    if not tool then return false end
    local name = string.lower(tool.Name)
    local itemType = string.lower(tostring(tool:GetAttribute("ItemType") or tool:GetAttribute("Type") or tool:GetAttribute("Category") or ""))
    if tool:GetAttribute("FoodKey") or tool:GetAttribute("IsFood") or tool:HasTag("Food") then
        return true
    end
    if string.find(itemType, "food", 1, true) then
        return true
    end
    if FoodData and FoodData[tool.Name] then
        return true
    end
    for _, word in ipairs(FOOD_WORDS) do
        if string.find(name, word, 1, true) then
            return true
        end
    end
    return false
end

local function isPetTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if isFood(tool) then return false end
    if tool:HasTag("Egg") or tool:GetAttribute("EggKey") or tool:GetAttribute("EggInventoryId") then
        return false
    end
    if EGG_DB[tool.Name] or (EggsData and EggsData[tool.Name]) then
        return false
    end
    local key = tool:GetAttribute("PetKey")
    if type(key) == "string" and key ~= "" then return true end
    if type(key) == "number" then return true end
    local petName = tool:GetAttribute("PetName")
    if type(petName) == "string" and petName ~= "" and PetsData and type(PetsData[petName]) == "table" then
        return true
    end
    if PetsData and type(PetsData[tool.Name]) == "table" and PetsData[tool.Name].Speed then
        return true
    end
    return false
end

local function bestInventoryPet()
    local best, bestScore
    local function scan(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if isPetTool(tool) then
                local score = petScore(tool)
                if not bestScore or score > bestScore then
                    best, bestScore = tool, score
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return best
end

local function buttonBlob(btn)
    local blob = string.lower(btn.Name or "")
    if btn:IsA("TextButton") or btn:IsA("TextLabel") then
        blob = blob .. " " .. string.lower(btn.Text or "")
    end
    for _, child in ipairs(btn:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            blob = blob .. " " .. string.lower(child.Text or "")
        end
    end
    return blob
end

local function guiRoots()
    local roots = {}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        table.insert(roots, playerGui)
    end
    if gethui then
        pcall(function()
            local hidden = gethui()
            if hidden then
                table.insert(roots, hidden)
            end
        end)
    end
    return roots
end

local function findScreenButton(phrases)
    for _, phrase in ipairs(phrases) do
        for _, root in ipairs(guiRoots()) do
            for _, inst in ipairs(root:GetDescendants()) do
                if inst:IsA("GuiButton") and inst.Visible and inst.AbsoluteSize.X > 4 and not inst:IsDescendantOf(ScreenGui) then
                    if string.find(buttonBlob(inst), phrase, 1, true) then
                        return inst
                    end
                end
            end
        end
    end
    return nil
end

function Runtime.DropButtonVisible()
    return findScreenButton({ "drop", "throw", "discard" }) ~= nil
end

local function clickGui(btn)
    if not btn or not btn.Parent then return false end
    if getconnections then
        pcall(function()
            for _, signal in ipairs({ btn.MouseButton1Click, btn.Activated, btn.MouseButton1Down }) do
                for _, conn in ipairs(getconnections(signal)) do
                    pcall(function()
                        if conn.Function then
                            conn.Function()
                        elseif conn.Fire then
                            conn:Fire()
                        end
                    end)
                end
            end
        end)
    end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
        pcall(function() firesignal(btn.MouseButton1Down) end)
    end
    pcall(function()
        if btn.Activate then
            btn:Activate()
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local inset = game:GetService("GuiService"):GetGuiInset()
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2) + inset
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.04)
        vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    return true
end

local function findNamed(name)
    local lower = string.lower(name)
    local roots = { ReplicatedStorage, workspace }
    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if string.lower(d.Name) == lower then
                return d
            end
        end
    end
    return nil
end

local function findPrompt(root, words)
    if not root then return nil end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local blob = string.lower((d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name)
            for _, word in ipairs(words) do
                if string.find(blob, word, 1, true) then
                    return d
                end
            end
        end
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, prompt.HoldDuration > 0 and 1 or 0)
        else
            prompt:InputHoldBegin()
            task.wait((prompt.HoldDuration or 0) + 0.05)
            prompt:InputHoldEnd()
        end
    end)
end

Runtime.InstantPromptOriginal = setmetatable({}, { __mode = "k" })
function Runtime.ConfigureInstantPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    local text = string.lower((prompt.ActionText or "") .. " " .. (prompt.ObjectText or "") .. " " .. prompt.Name)
    if not string.find(text, "pick", 1, true)
        and not string.find(text, "collect", 1, true)
        and not string.find(text, "candy", 1, true) then return end
    if not Runtime.InstantPromptOriginal[prompt] then
        Runtime.InstantPromptOriginal[prompt] = {
            HoldDuration = prompt.HoldDuration,
            MaxActivationDistance = prompt.MaxActivationDistance,
            RequiresLineOfSight = prompt.RequiresLineOfSight,
        }
    end
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 1000
    prompt.RequiresLineOfSight = false
end

Runtime.SetInstantPickup = function(enabled)
    Runtime.InstantPickupEnabled = enabled
    if enabled then
        for _, object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ProximityPrompt") then
                pcall(Runtime.ConfigureInstantPrompt, object)
            end
        end
        if not Runtime.InstantPromptConnection then
            Runtime.InstantPromptConnection = workspace.DescendantAdded:Connect(function(object)
                if Runtime.InstantPickupEnabled and object:IsA("ProximityPrompt") then
                    pcall(Runtime.ConfigureInstantPrompt, object)
                end
            end)
        end
    else
        for prompt, values in pairs(Runtime.InstantPromptOriginal) do
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.HoldDuration = values.HoldDuration
                    prompt.MaxActivationDistance = values.MaxActivationDistance
                    prompt.RequiresLineOfSight = values.RequiresLineOfSight
                end)
            end
        end
        Runtime.InstantPromptOriginal = setmetatable({}, { __mode = "k" })
    end
end

Runtime.ActivateNearbyPrompt = function(position, radius)
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local parent = prompt.Parent
            if parent and parent:IsA("Attachment") then parent = parent.Parent end
            if parent and parent:IsA("BasePart") and (parent.Position - position).Magnitude <= (radius or 12) then
                pcall(function()
                    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, radius or 12)
                    prompt.HoldDuration = 0
                end)
                firePrompt(prompt)
                return true
            end
        end
    end
    return false
end

local function pressRideButton(seconds)
    local t0 = os.clock()
    while os.clock() - t0 < seconds do
        if isRiding() then
            return true
        end
        local btn = findScreenButton({ "ride pet", "ridepet", "ride" })
        if btn then
            clickGui(btn)
        end
        local prompt = findPrompt(LocalPlayer.Character, { "ride pet", "ride" })
        if not prompt then
            local plot = myPlot()
            prompt = plot and findPrompt(plot, { "ride pet", "ride" })
        end
        if prompt then
            firePrompt(prompt)
        end
        task.wait(0.2)
    end
    return isRiding()
end

local function rideBestPet()
    if isRiding() then
        return true
    end
    local _, hum = character()
    if not hum then return false end
    pcall(function()
        hum:UnequipTools()
    end)
    task.wait(0.15)
    local pet = bestInventoryPet()
    if pet and not isFood(pet) then
        pcall(function()
            hum:EquipTool(pet)
        end)
        task.wait(0.35)
    end
    if pressRideButton(4) then
        return true
    end
    local plot = myPlot()
    if plot and Job.token ~= 0 then
        local base = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
        local pos = base and base:IsA("BasePart") and base.Position or plot:GetPivot().Position
        moveTo(pos + Vector3.new(0, 4, 0), "Instant", true)
        task.wait(0.3)
        if pressRideButton(3) then
            return true
        end
    end
    local key = pet and pet:GetAttribute("PetKey")
    local remotes = GameRemotes or (ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game"))
    if remotes and key then
        for _, remoteName in ipairs({ "PetRide", "RidePet", "MountPet", "PetMount" }) do
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteEvent") then
                pcall(function()
                    remote:FireServer(key)
                end)
                task.wait(0.25)
                if isRiding() then
                    return true
                end
            end
        end
    end
    return isRiding()
end

function myPlot()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local data = plot:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner then
            local mine = false
            if owner:IsA("ObjectValue") then
                mine = owner.Value == LocalPlayer
            elseif owner:IsA("StringValue") then
                mine = owner.Value == LocalPlayer.Name or owner.Value == tostring(LocalPlayer.UserId)
            else
                mine = tostring(owner.Value) == LocalPlayer.Name
            end
            if mine then
                return plot
            end
        end
    end
    return nil
end

local function goToRanch(mode)
    local plot = myPlot()
    if not plot then
        return false
    end
    local base = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
    local pos
    if base and base:IsA("BasePart") then
        pos = base.Position
    else
        pos = plot:GetPivot().Position
    end
    return moveTo(pos + Vector3.new(0, 4, 0), mode)
end
Runtime.GoToRanch = goToRanch
function Runtime.GetRanchPosition()
    local plot = myPlot()
    if not plot then return nil end
    local base = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
    return base and base:IsA("BasePart") and base.Position or plot:GetPivot().Position
end

Runtime.VolcanicInbound = function(row, mode, token)
    if not row or row.Name ~= "Volcanic Egg" then return true end
    if Job.volcanicInbound then return true end
    local pointA = Vector3.new(-4945.00, 41274.75, -3673.88)
    local pointB = Vector3.new(-4968.07, 41274.86, -3653.67)
    local pointC = Vector3.new(-5329.92, 40912.40, -3573.92)
    setStatus("Volcanic route in: checkpoint 1", row.Id)
    moveTo(pointA, mode, true)
    if Job.token ~= token then return false end
    setStatus("Volcanic route in: careful checkpoint 2", row.Id)
    local savedSpeed = SpeedValue
    SpeedValue = math.min(SpeedValue, 500)
    moveTo(pointB, "Fly", true)
    if Job.token ~= token then SpeedValue = savedSpeed return false end
    setStatus("Volcanic route in: noclip to egg", row.Id)
    moveTo(pointC, "Fly", true)
    SpeedValue = savedSpeed
    if Job.token ~= token then return false end
    Job.volcanicInbound = true
    setStatus("Volcanic egg area reached", row.Id)
    return true
end

Runtime.VolcanicOutbound = function(row, mode, token)
    if not row or row.Name ~= "Volcanic Egg" then return true end
    if Job.volcanicOutbound then return true end
    local pointA = Vector3.new(-4945.00, 41274.75, -3673.88)
    local pointB = Vector3.new(-4968.07, 41274.86, -3653.67)
    setStatus("Volcanic route out: checkpoint 2", row.Id)
    local savedSpeed = SpeedValue
    SpeedValue = math.min(SpeedValue, 500)
    moveTo(pointB, "Fly", true)
    if Job.token ~= token then SpeedValue = savedSpeed return false end
    setStatus("Volcanic route out: checkpoint 1", row.Id)
    moveTo(pointA, mode, true)
    SpeedValue = savedSpeed
    if Job.token ~= token then return false end
    Job.volcanicOutbound = true
    Job.volcanicEscaped = true
    setStatus("Volcanic escape completed", row.Id)
    return true
end

local function ensureRemotes()
    if not GameRemotes or not GameRemotes.Parent then
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 8)
        GameRemotes = remotes and (remotes:FindFirstChild("Game") or remotes:WaitForChild("Game", 8))
    end
    if GameRemotes and not EggPickup then
        EggPickup = GameRemotes:FindFirstChild("EggPickup") or GameRemotes:WaitForChild("EggPickup", 5)
    end
    if GameRemotes and not BasketDrop then
        BasketDrop = GameRemotes:FindFirstChild("BasketDrop")
    end
end

if not _G.SterlingPickupHook then
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
        local gameFolder = remotes and remotes:WaitForChild("Game", 10)
        local pickup = gameFolder and gameFolder:WaitForChild("EggPickup", 10)
        if pickup then
            _G.SterlingPickupHook = pickup.OnClientEvent:Connect(function(status, name, id)
                LastPickup = {
                    status = tostring(status),
                    name = tostring(name),
                    id = id and tostring(id) or nil,
                    t = os.clock(),
                }
            end)
        end
        local dipResult = gameFolder and gameFolder:FindFirstChild("VolcanoDipResult", true)
            or Runtime.Remotes.VolcanoDipResult
            or findNamed("VolcanoDipResult")
        if dipResult and dipResult:IsA("RemoteEvent") then
            on(dipResult.OnClientEvent, function(...)
                local args = { ... }
                local bits = {}
                for i, v in ipairs(args) do
                    bits[i] = tostring(v)
                end
                Runtime.DipSerial = (Runtime.DipSerial or 0) + 1
                Runtime.DipResult = {
                    args = args,
                    text = table.concat(bits, " "),
                    at = os.clock(),
                }
            end)
        end
    end)
end

function Runtime.InventoryEggNameCount(eggName)
    local count = 0
    for _, container in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tostring(tool:GetAttribute("Egg") or tool.Name)
                    if name == eggName then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

function Runtime.TargetEggPresent(row)
    if not Job.targetAcquired then return false end
    if Runtime.DropButtonVisible and Runtime.DropButtonVisible() then return true end
    if Job.targetObject and Job.targetObject.Parent then return true end
    if Runtime.BasketHasExact(row.Id) then return true end
    if Runtime.BasketEggCount(row.Name) > (Job.baseBasketEggs or 0) then return true end
    if Runtime.InventoryEggNameCount(row.Name) > (Job.baseInventoryEggs or 0) then return true end
    if not Job.dipAttempted and os.clock() < (Job.targetHeldGrace or 0) then return true end
    return false
end

local function holdAtEgg(pos)
    local _, _, hrp = character()
    if hrp and typeof(pos) == "Vector3" then
        applyFlightCF(hrp, CFrame.new(pos + Vector3.new(0, 3, 0)))
    end
end

local function pickupConfirmed(row, beforeCount, start)
    if Runtime.DropButtonVisible and Runtime.DropButtonVisible() and not Job.dropVisibleBefore then
        Job.targetHeldGrace = os.clock() + 4
        return true
    end
    if Runtime.BasketHasExact(row.Id) then
        Job.targetHeldGrace = os.clock() + 4
        return true
    end
    local basket = basketFolder()
    if basket and #basket:GetChildren() > beforeCount
        and Runtime.BasketEggCount(row.Name) > (Job.baseBasketEggs or 0) then
        for _, object in ipairs(basket:GetChildren()) do
            if not (Job.pickupObjects and Job.pickupObjects[object]) then
                Job.targetObject = object
                break
            end
        end
        Job.targetHeldGrace = os.clock() + 4
        return true
    end
    if Runtime.InventoryEggNameCount(row.Name) > (Job.baseInventoryEggs or 0) then
        for _, container in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
            if container then
                for _, object in ipairs(container:GetChildren()) do
                    if object:IsA("Tool") and not (Job.pickupObjects and Job.pickupObjects[object]) then
                        local name = tostring(object:GetAttribute("Egg") or object.Name)
                        if name == row.Name then Job.targetObject = object break end
                    end
                end
            end
        end
        Job.targetHeldGrace = os.clock() + 4
        return true
    end
    return false
end

local function pickupEgg(row)
    ensureRemotes()
    local start = os.clock()
    LastPickup = nil
    Job.dropVisibleBefore = Runtime.DropButtonVisible and Runtime.DropButtonVisible() or false
    local pos = row.Object and row.Object:GetAttribute("Position") or row.Position
    if typeof(pos) ~= "Vector3" then
        pos = row.Position
    end
    local basket = basketFolder()
    local beforeCount = basket and #basket:GetChildren() or 0
    Job.pickupObjects = {}
    if basket then
        for _, object in ipairs(basket:GetChildren()) do Job.pickupObjects[object] = true end
    end
    for _, container in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
        if container then
            for _, object in ipairs(container:GetChildren()) do Job.pickupObjects[object] = true end
        end
    end
    local deadline = os.clock() + 10
    while Alive and os.clock() < deadline do
        if not row.Object or not row.Object.Parent then
            return false, "EggGone"
        else
            local fresh = row.Object:GetAttribute("Position")
            if typeof(fresh) == "Vector3" then
                pos = fresh
            end
        end
        -- The game remote is the instant pickup path. Physical prompts are not
        -- used here because their hold time can let another player take the egg.
        if EggPickup then
            pcall(function()
                EggPickup:FireServer(row.Id)
            end)
        end
        if row.Object then
            local prompt = findPrompt(row.Object, { "pick up", "pickup", "pick" })
            if prompt then
                pcall(function()
                    prompt.MaxActivationDistance = 1000
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                end)
                firePrompt(prompt)
            end
        end
        holdAtEgg(pos)
        local waitUntil = os.clock() + 0.18
        while Alive and os.clock() < waitUntil do
            holdAtEgg(pos)
            if EggPickup then
                pcall(function() EggPickup:FireServer(row.Id) end)
            end
            if pickupConfirmed(row, beforeCount, start) then
                local stick = os.clock() + 0.45
                while Alive and os.clock() < stick do
                    holdAtEgg(pos)
                    task.wait(0.1)
                end
                if pickupConfirmed(row, beforeCount, start) then
                    Job.targetAcquired = true
                    Job.targetHeldGrace = os.clock() + 4
                    return true
                end
            end
            if LastPickup and LastPickup.t >= start and LastPickup.status == "BasketFull" then
                return false, "BasketFull"
            end
            if LastPickup and LastPickup.t >= start and LastPickup.status == "Refused" then
                return false, "EggGone"
            end
            task.wait(0.03)
        end
    end
    if pickupConfirmed(row, beforeCount, start) then
        Job.targetAcquired = true
        Job.targetHeldGrace = os.clock() + 4
        return true
    end
    return false, "no egg"
end

Runtime.InstantPickupNearest = function()
    if Job.busy then
        setStatus("Busy", Job.eggId)
        return
    end
    local nearest = nil
    for _, row in ipairs(scanEggs()) do
        if not nearest or row.Distance < nearest.Distance then
            nearest = row
        end
    end
    if not nearest then
        setStatus("No egg available", nil)
        return
    end
    Job.busy = true
    Job.token = Job.token + 1
    Job.eggId = nearest.Id
    Job.row = nearest
    Job.baseBasketEggs = Runtime.BasketEggCount(nearest.Name)
    Job.baseInventoryEggs = Runtime.InventoryEggNameCount(nearest.Name)
    Job.targetAcquired = false
    Job.targetObject = nil
    task.spawn(function()
        setStatus("Instant PickUpEgg", nearest.Id)
        moveTo(nearest.Position, "Instant", true)
        local picked, reason = pickupEgg(nearest)
        setStatus(picked and "Egg in hands" or ("PickUp failed: " .. tostring(reason)), nearest.Id)
        Job.busy = false
    end)
end

local function doVolcanoDip(row, mode, token, force)
    if AutoDip ~= true and not force then return true end
    if Job.dipAttempted then return true end
    local resultBefore = Runtime.DipSerial or 0
    if mode == "Instant" then
        setStatus("Teleporting to volcano", row.Id)
    else
        setStatus("Flying to volcano", row.Id)
    end
    moveTo(VOLCANO_POS, mode, true)
    setStatus("Drop in volcano", row.Id)
    local t0 = os.clock()
    local activated = false
    while Alive and Job.token == token and os.clock() - t0 < 10 do
        local btn = findScreenButton({ "drop in volcano", "drop in" })
        if btn and not activated then
            clickGui(btn)
            activated = true
            Job.dipAttempted = true
        elseif not activated and os.clock() - t0 > 2 then
            local remote = Runtime.Remotes.VolcanoDip
            if remote and remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer(row.Id) end)
                activated = true
                Job.dipAttempted = true
            end
        end
        if (Runtime.DipSerial or 0) > resultBefore then
            local resultText = Runtime.DipResult and Runtime.DipResult.text or "received"
            setStatus("VolcanoDipResult: " .. resultText, row.Id)
            return true
        end
        -- Stay at the dip point even while the volcano temporarily removes the egg.
        local _, _, root = character()
        if root and (root.Position - VOLCANO_POS).Magnitude > 25 then
            moveTo(VOLCANO_POS, "Instant", true)
        end
        task.wait(0.25)
    end
    -- One egg can only be dipped once. A missing client result must not send it
    -- through the volcano again; continue to the ranch after the single attempt.
    Job.dipAttempted = true
    setStatus(activated and "Dip completed - result unavailable" or "Dip attempted once", row.Id)
    return true
end

function Runtime.PlotEggCount()
    local plot = myPlot()
    local eggs = plot and plot:FindFirstChild("Eggs")
    return eggs and #eggs:GetChildren() or 0
end

function Runtime.InventoryEggCount()
    local count = 0
    for _, container in ipairs({ LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tostring(tool:GetAttribute("Egg") or tool.Name)
                    if tool:HasTag("Egg") or tool:GetAttribute("EggInventoryId") or EGG_DB[name] or (EggsData and EggsData[name]) then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

function Runtime.IsAtRanch()
    local plot = myPlot()
    local base = plot and plot:FindFirstChild("Baseplate")
    local _, _, root = character()
    if not base or not base:IsA("BasePart") or not root then return false end
    local point = base.CFrame:PointToObjectSpace(root.Position)
    return math.abs(point.X) <= base.Size.X / 2 + 12
        and math.abs(point.Z) <= base.Size.Z / 2 + 12
        and math.abs(point.Y) <= 40
end

local function deliverHome(mode, row, token)
    if not Runtime.TargetEggPresent(row) then
        setStatus("Waiting for egg in hands", row.Id)
        return false
    end
    local beforePlot = Runtime.PlotEggCount()
    local beforeInventory = Runtime.InventoryEggCount()
    if mode == "Instant" then
        setStatus("Teleporting to My Ranch", Job.eggId)
    else
        setStatus("Flying to My Ranch", Job.eggId)
    end
    local ok = goToRanch(mode)
    if not ok then
        setStatus("Ranch not found", Job.eggId)
        return false
    end
    local t0 = os.clock()
    local lastDrop = 0
    while Alive and Job.token == token and os.clock() - t0 < 16 do
        local locked = false
        local basket = basketFolder()
        local now = workspace:GetServerTimeNow()
        if basket then
            for _, child in ipairs(basket:GetChildren()) do
                local untilTime = tonumber(child:GetAttribute("VolcanoUntil"))
                if untilTime and now < untilTime then
                    locked = true
                end
            end
        end
        if not locked then break end
        setStatus("Waiting for egg return", Job.eggId)
        task.wait(0.25)
    end
    ensureRemotes()
    local deliveryDeadline = os.clock() + 16
    while Alive and Job.token == token and os.clock() < deliveryDeadline do
        local basket = basketFolder()
        if BasketDrop and basket and #basket:GetChildren() > 0 and os.clock() - lastDrop > 0.45 then
            lastDrop = os.clock()
            pcall(function()
                BasketDrop:FireServer()
            end)
        end
        if Runtime.PlotEggCount() > beforePlot or Runtime.InventoryEggCount() > beforeInventory then
            setStatus("Delivered to My Ranch", row.Id)
            return true
        end
        if Runtime.IsAtRanch() and Runtime.TargetEggPresent(row) and (not basket or #basket:GetChildren() == 0) then
            setStatus("Delivered to My Ranch", row.Id)
            return true
        end
        if basket and #basket:GetChildren() == 0 and not basketHas(row.Name, row.Id) then
            task.wait(0.5)
            if Runtime.PlotEggCount() > beforePlot or Runtime.InventoryEggCount() > beforeInventory then
                setStatus("Delivered to My Ranch", row.Id)
                return true
            end
        end
        task.wait(0.15)
    end
    setStatus("Delivery not confirmed - retrying", row.Id)
    return false
end

function Runtime.RecordSuccessfulSteal(row)
    if not row then return end
    Runtime.HistoryRecorded = Runtime.HistoryRecorded or {}
    if Runtime.HistoryRecorded[row.Id] then return end
    Runtime.HistoryRecorded[row.Id] = true
    Runtime.StealHistory = Runtime.StealHistory or Storage.loadHistory()
    local now = os.time and os.time() or math.floor(workspace:GetServerTimeNow())
    local date = os.date and os.date("%Y-%m-%d %H:%M:%S", now) or tostring(now)
    table.insert(Runtime.StealHistory, {
        id = row.Id,
        timestamp = now,
        date = date,
        name = row.Name,
        rarity = row.Rarity,
        luck = formatNumber(row.Luck),
        mutation = row.Mutation,
        traits = row.Traits,
        icon = row.Icon,
        from = row.SourcePlayer or "Unknown",
    })
    local fresh = {}
    for _, entry in ipairs(Runtime.StealHistory) do
        if now - (tonumber(entry.timestamp) or 0) <= 432000 then
            table.insert(fresh, entry)
        end
    end
    Runtime.StealHistory = fresh
    Storage.saveHistory(fresh)
    if Runtime.RefreshHistory then Runtime.RefreshHistory() end
end

local function runSteal(row, mode, forceDip, deliveryMode)
    Job.busy = true
    Job.token = Job.token + 1
    local token = Job.token
    Job.eggId = row.Id
    Job.row = row
    Job.baseBasketEggs = Runtime.BasketEggCount(row.Name)
    Job.baseInventoryEggs = Runtime.InventoryEggNameCount(row.Name)
    Job.targetAcquired = false
    Job.targetObject = nil
    Job.dipAttempted = false
    Job.volcanicEscaped = false
    Job.volcanicInbound = false
    Job.volcanicOutbound = false
    local useDip = forceDip == true or AutoDip == true
    local returnMode = deliveryMode or mode
    local function cancelled()
        return (not Alive) or Job.token ~= token
    end
    local function finish()
        stopFlight()
        Job.busy = false
        if refreshNote then
            refreshNote()
        end
    end
    if showEggModel then
        showEggModel(row)
    end
    setStatus(mode == "Instant" and "Instant" or "FLY", row.Id)
    if not character() then
        setStatus("No character", row.Id)
        finish()
        return
    end
    setStatus("Riding best pet", row.Id)
    rideBestPet()
    if cancelled() then finish() return end
    if row.Spawning then
        setStatus("Waiting for spawn", row.Id)
        local t0 = os.clock()
        while os.clock() - t0 < 20 do
            if cancelled() then finish() return end
            local fresh = row.Object
            local dropEnd = fresh and tonumber(fresh:GetAttribute("DropEndsAt")) or 0
            if not fresh or not fresh.Parent or dropEnd <= workspace:GetServerTimeNow() then
                break
            end
            task.wait(0.2)
        end
    end
    local dipPassed = not useDip
    local delivered = false
    local routedAfterDip = false
    local pos = row.Object and row.Object:GetAttribute("Position") or row.Position

    while not cancelled() and not delivered do
        local carrying = Runtime.TargetEggPresent(row)
        if not carrying then
            if dipPassed and Job.targetAcquired then
                if not routedAfterDip or not Runtime.IsAtRanch() then
                    setStatus(returnMode == "Instant" and "Teleporting to My Ranch" or "Flying to My Ranch", row.Id)
                    goToRanch(returnMode)
                    routedAfterDip = true
                end
                setStatus("At My Ranch - waiting for egg", row.Id)
                local returnDeadline = os.clock() + 3
                while not cancelled() and os.clock() < returnDeadline do
                    if Runtime.TargetEggPresent(row) then
                        carrying = true
                        break
                    end
                    task.wait(0.15)
                end
            end
            if not carrying and not cancelled() and not (dipPassed and Job.targetAcquired) then
                if not row.Object or not row.Object.Parent then
                    setStatus("Egg broke or disappeared", row.Id)
                    finish()
                    return
                end
                if row.Object and row.Object.Parent then
                    local fresh = row.Object:GetAttribute("Position")
                    if typeof(fresh) == "Vector3" then
                        pos = fresh
                    end
                end
                if row.Name == "Volcanic Egg" and not Job.volcanicInbound then
                    Runtime.VolcanicInbound(row, mode, token)
                end
                setStatus(mode == "Instant" and "Instant PickUpEgg" or "Flying to egg", row.Id)
                moveTo(pos, mode, false)
                task.wait(0.15)
                setStatus("Instant PickUpEgg", row.Id)
                local picked, reason = pickupEgg(row)
                carrying = picked or Runtime.TargetEggPresent(row)
                if not carrying then
                    if reason == "EggGone" then
                        setStatus("Egg broke or disappeared", row.Id)
                        finish()
                        return
                    end
                    setStatus("PickUpEgg retry" .. (reason and (": " .. reason) or ""), row.Id)
                    task.wait(0.4)
                end
            end
        end

        if carrying and row.Name == "Volcanic Egg" and not Job.volcanicOutbound and not cancelled() then
            Runtime.VolcanicOutbound(row, mode, token)
            carrying = Runtime.TargetEggPresent(row) or carrying
        end

        if carrying and not dipPassed and not cancelled() then
            local okDip, passed = pcall(doVolcanoDip, row, mode, token, forceDip == true)
            if okDip and passed then
                dipPassed = true
                setStatus(returnMode == "Instant" and "Dip passed - teleporting to My Ranch" or "Dip passed - flying to My Ranch", row.Id)
                goToRanch(returnMode)
                routedAfterDip = true
            else
                if not okDip then
                    warn("[Sterling] dip " .. tostring(passed))
                end
                setStatus("Dip not passed - returning to volcano", row.Id)
                task.wait(0.4)
            end
        elseif carrying and dipPassed and not cancelled() then
            delivered = deliverHome(returnMode, row, token)
            if not delivered then
                setStatus("Stealing continues - delivery retry", row.Id)
                task.wait(0.4)
            end
        end
    end

    if delivered then
        setStatus("Steal completed", row.Id)
        Runtime.RecordSuccessfulSteal(row)
    end
    finish()
end

function Runtime.ClearPlatformRoute()
    if Runtime.PlatformRoute then
        Runtime.PlatformRoute:Destroy()
        Runtime.PlatformRoute = nil
    end
end

function Runtime.PlatformRunToPlot(speed, token)
    Runtime.ClearPlatformRoute()
    local plot = myPlot()
    local base = plot and (plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart"))
    local char, humanoid, root = character()
    if not base or not root or not humanoid then return false end
    local destination = base.Position + Vector3.new(0, 4, 0)
    local folder = Instance.new("Folder")
    folder.Name = "SterlingPlatformRoute"
    folder.Parent = workspace
    Runtime.PlatformRoute = folder

    local platform = Instance.new("Part")
    platform.Name = "SafeStealPlatform"
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.SmoothPlastic
    platform.Color = Color3.fromRGB(42, 42, 46)
    platform.Transparency = 0.08
    platform.Size = Vector3.new(12, 1, 12)
    platform.Parent = folder

    local target = Instance.new("Part")
    target.Name = "PlotLineTarget"
    target.Anchored = true
    target.CanCollide = false
    target.Transparency = 1
    target.Size = Vector3.one
    target.Position = destination
    target.Parent = folder
    local a0 = Instance.new("Attachment")
    a0.Parent = platform
    local a1 = Instance.new("Attachment")
    a1.Parent = target
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.Width0 = 0.12
    beam.Width1 = 0.12
    beam.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235), Color3.fromRGB(100, 100, 110))
    beam.Transparency = NumberSequence.new(0.18)
    beam.Parent = platform

    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    local oldSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = math.clamp(speed, 100, 2000)
    pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
    local arrived = false
    while Alive and Job.token == token and Runtime.PlatformConfig and Runtime.PlatformConfig.enabled do
        local dt = RunService.Heartbeat:Wait()
        if not root.Parent or humanoid.Health <= 0 then break end
        local delta = destination - root.Position
        local distance = delta.Magnitude
        if distance <= 9 then
            arrived = true
            break
        end
        local direction = delta.Unit
        local step = math.min(distance, math.clamp(speed, 100, 2000) * dt)
        local nextPosition = root.Position + direction * step
        platform.CFrame = CFrame.new(nextPosition - Vector3.new(0, 3.4, 0))
        humanoid:Move(direction, false)
        root.CFrame = CFrame.lookAt(nextPosition, nextPosition + direction)
        root.AssemblyLinearVelocity = direction * math.min(speed, 2000)
        if Runtime.PlatformStatusLabel then
            Runtime.PlatformStatusLabel.Text = "Line to Plot: " .. tostring(math.floor(distance)) .. " studs"
        end
    end
    humanoid.WalkSpeed = oldSpeed
    humanoid:Move(Vector3.zero, false)
    root.AssemblyLinearVelocity = Vector3.zero
    if arrived then
        root.CFrame = CFrame.new(destination)
    end
    Runtime.ClearPlatformRoute()
    return arrived
end

Runtime.StopPlatformSteal = function()
    if Runtime.PlatformConfig then
        Runtime.PlatformConfig.enabled = false
    end
    Runtime.PlatformToken = (Runtime.PlatformToken or 0) + 1
    Job.token = Job.token + 1
    Job.busy = false
    Runtime.ClearPlatformRoute()
end

Runtime.StartPlatformSteal = function()
    if Runtime.PlatformRunning then return end
    Runtime.PlatformRunning = true
    Runtime.PlatformToken = (Runtime.PlatformToken or 0) + 1
    local platformToken = Runtime.PlatformToken
    task.spawn(function()
        while Alive and Runtime.PlatformConfig and Runtime.PlatformConfig.enabled and Runtime.PlatformToken == platformToken do
            if Job.busy then
                task.wait(0.25)
            else
                local rows = scanEggs()
                local row = nil
                local minimum = RARITY_ORDER[Runtime.PlatformConfig.rarity] or RARITY_ORDER.Rare
                for _, candidate in ipairs(rows) do
                    if (RARITY_ORDER[candidate.Rarity] or 0) >= minimum then
                        row = candidate
                        break
                    end
                end
                if not row then
                    if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Waiting for " .. Runtime.PlatformConfig.rarity .. "+ egg" end
                    task.wait(0.8)
                else
                    Job.busy = true
                    Job.token = Job.token + 1
                    local token = Job.token
                    Job.eggId = row.Id
                    Job.row = row
                    Job.baseBasketEggs = Runtime.BasketEggCount(row.Name)
                    Job.baseInventoryEggs = Runtime.InventoryEggNameCount(row.Name)
                    Job.targetAcquired = false
                    Job.targetObject = nil
                    Job.dipAttempted = false
                    Job.volcanicEscaped = false
                    Job.volcanicInbound = false
                    Job.volcanicOutbound = false
                    if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Best pet" end
                    rideBestPet()
                    local dipPassed = false
                    local delivered = false
                    local routeDone = false
                    while Alive and Job.token == token and Runtime.PlatformConfig.enabled and not delivered do
                        local acquiredNow = false
                        if not Runtime.TargetEggPresent(row) and not dipPassed then
                            if not row.Object or not row.Object.Parent then
                                if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Egg disappeared" end
                                break
                            end
                            local pos = row.Object and row.Object:GetAttribute("Position") or row.Position
                            if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Instant PickUpEgg" end
                            if row.Name == "Volcanic Egg" and not Job.volcanicInbound then
                                Runtime.VolcanicInbound(row, "Instant", token)
                            end
                            moveTo(pos, "Instant", true)
                            local picked, reason = pickupEgg(row)
                            acquiredNow = picked == true
                            if not picked and reason == "EggGone" then
                                if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Egg disappeared" end
                                break
                            end
                        end
                        if (Runtime.TargetEggPresent(row) or acquiredNow)
                            and row.Name == "Volcanic Egg" and not Job.volcanicOutbound then
                            Runtime.VolcanicOutbound(row, "Instant", token)
                        end
                        if (Runtime.TargetEggPresent(row) or acquiredNow) and not dipPassed then
                            if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Volcano Dip" end
                            dipPassed = doVolcanoDip(row, "Instant", token, true)
                            if dipPassed then
                                if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Platform run to My Ranch" end
                                Runtime.PlatformRunToPlot(Runtime.PlatformConfig.speed or 800, token)
                                routeDone = true
                            end
                        elseif dipPassed and (not routeDone or not Runtime.IsAtRanch()) then
                            if Runtime.PlatformStatusLabel then Runtime.PlatformStatusLabel.Text = "Platform run" end
                            Runtime.PlatformRunToPlot(Runtime.PlatformConfig.speed or 800, token)
                            routeDone = true
                        elseif Runtime.TargetEggPresent(row) and dipPassed and routeDone then
                            delivered = deliverHome("Instant", row, token)
                        else
                            if Runtime.PlatformStatusLabel then
                                Runtime.PlatformStatusLabel.Text = dipPassed and "At My Ranch - waiting for egg" or "PickUp retry"
                            end
                            task.wait(0.3)
                        end
                    end
                    Job.busy = false
                    if delivered and Runtime.PlatformStatusLabel then
                        Runtime.PlatformStatusLabel.Text = "Delivered"
                    end
                    if delivered then
                        Runtime.RecordSuccessfulSteal(row)
                    end
                    task.wait(0.4)
                end
            end
        end
        Runtime.ClearPlatformRoute()
        Runtime.PlatformRunning = false
        if Runtime.PlatformStatusLabel and not Runtime.PlatformConfig.enabled then
            Runtime.PlatformStatusLabel.Text = "Stopped"
        end
    end)
end

Runtime.RideBestPet = rideBestPet

Runtime.RideFlyingPet = function()
    if isRiding() then return true end
    local allowed = { "phoenix", "mantis", "griffin", "hydra dragon", "dragon skeleton", "dragon" }
    local best, bestScore = nil, nil
    local activeCharacter = select(1, character())
    for _, container in ipairs({ LocalPlayer:FindFirstChild("Backpack"), activeCharacter }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and isPetTool(tool) then
                    local name = string.lower(tostring(tool:GetAttribute("PetName") or tool.Name))
                    local allowedPet = false
                    for _, wanted in ipairs(allowed) do
                        if string.find(name, wanted, 1, true) then allowedPet = true break end
                    end
                    if allowedPet then
                        local score = petScore(tool)
                        if not bestScore or score > bestScore then best, bestScore = tool, score end
                    end
                end
            end
        end
    end
    local _, humanoid = character()
    if best and humanoid then
        humanoid:UnequipTools()
        humanoid:EquipTool(best)
        task.wait(0.25)
        return pressRideButton(4)
    end
    return false
end

Runtime.StopSkyRace = function()
    if Runtime.RaceConfig then Runtime.RaceConfig.enabled = false end
    Runtime.RaceToken = (Runtime.RaceToken or 0) + 1
end

Runtime.StartSkyRace = function()
    if Runtime.RaceRunning then return end
    Runtime.RaceRunning = true
    Runtime.RaceToken = (Runtime.RaceToken or 0) + 1
    local raceToken = Runtime.RaceToken
    task.spawn(function()
        local points = {
            Vector3.new(805.53, 41038.87, 311.58),
            Vector3.new(1042.85, 41136.59, 412.24),
            Vector3.new(1295.22, 41123.15, 168.97),
            Vector3.new(1558.54, 41139.66, 382.79),
            Vector3.new(1858.63, 41184.38, 135.52),
            Vector3.new(1925.43, 41084.10, -177.70),
            Vector3.new(1790.99, 41112.01, -535.72),
            Vector3.new(1489.19, 41178.49, -807.74),
            Vector3.new(1144.84, 40891.94, -889.43),
        }
        local start = Vector3.new(631.14, 40747.10, 565.44)
        while Alive and Runtime.RaceConfig and Runtime.RaceConfig.enabled and Runtime.RaceToken == raceToken do
            if Runtime.RaceStatusLabel then Runtime.RaceStatusLabel.Text = "Equipping flying pet" end
            if not Runtime.RideFlyingPet() then
                if Runtime.RaceStatusLabel then Runtime.RaceStatusLabel.Text = "Flying pet not found" end
                task.wait(1)
            else
                Runtime.InstantTo(start)
                Runtime.ActivateNearbyPrompt(start, 20)
                local raceRemote = Runtime.Remotes.HalloweenRace
                if raceRemote and raceRemote:IsA("RemoteEvent") then pcall(function() raceRemote:FireServer() end) end
                task.wait(0.3)
                for index, point in ipairs(points) do
                    if not Runtime.RaceConfig.enabled or Runtime.RaceToken ~= raceToken then break end
                    if Runtime.RaceStatusLabel then Runtime.RaceStatusLabel.Text = "Race point " .. tostring(index) .. "/9" end
                    Runtime.InstantTo(point)
                    task.wait(0.18)
                end
                if Runtime.RaceConfig.enabled then
                    Runtime.GoToRanch("Instant")
                    if Runtime.RaceStatusLabel then Runtime.RaceStatusLabel.Text = "Finished - returned to My Ranch" end
                end
                task.wait(1.5)
            end
        end
        Runtime.RaceRunning = false
        if Runtime.RaceStatusLabel then Runtime.RaceStatusLabel.Text = "Stopped" end
    end)
end

Runtime.StopAutoFarm = function()
    if Runtime.AutoFarmConfig then
        Runtime.AutoFarmConfig.enabled = false
    end
    Runtime.AutoFarmToken = (Runtime.AutoFarmToken or 0) + 1
    if Job.busy then
        Job.token = Job.token + 1
        Job.busy = false
    end
    Runtime.DestroyControlClone("AutoFarm")
end

Runtime.StartAutoFarm = function()
    if Runtime.AutoFarmRunning then return end
    Runtime.AutoFarmRunning = true
    Runtime.AutoFarmToken = (Runtime.AutoFarmToken or 0) + 1
    local farmToken = Runtime.AutoFarmToken
    task.spawn(function()
        while Alive and Runtime.AutoFarmConfig and Runtime.AutoFarmConfig.enabled and Runtime.AutoFarmToken == farmToken do
            if Job.busy then
                task.wait(0.2)
            else
                local minimum = RARITY_ORDER[Runtime.AutoFarmConfig.rarity] or RARITY_ORDER.Rare
                local selected = nil
                for _, row in ipairs(scanEggs()) do
                    if (RARITY_ORDER[row.Rarity] or 0) >= minimum then
                        selected = row
                        break
                    end
                end
                if selected then
                    if Runtime.AutoFarmStatusLabel then
                        Runtime.AutoFarmStatusLabel.Text = "Collecting " .. selected.Name
                    end
                    local ranchPosition = Runtime.GetRanchPosition()
                    if ranchPosition then Runtime.CreateControlClone(ranchPosition, "AutoFarm") end
                    local oldSpeed = SpeedValue
                    if not Runtime.AutoFarmConfig.volcanoDip then SpeedValue = 1000 end
                    runSteal(
                        selected,
                        "Instant",
                        Runtime.AutoFarmConfig.volcanoDip == true,
                        Runtime.AutoFarmConfig.volcanoDip and "Instant" or "Fly"
                    )
                    SpeedValue = oldSpeed
                    Runtime.DestroyControlClone("AutoFarm")
                    if Runtime.AutoFarmStatusLabel and Runtime.AutoFarmConfig.enabled then
                        Runtime.AutoFarmStatusLabel.Text = "Watching egg spawns"
                    end
                    task.wait(0.25)
                else
                    if Runtime.AutoFarmStatusLabel then
                        Runtime.AutoFarmStatusLabel.Text = "Waiting for " .. Runtime.AutoFarmConfig.rarity .. "+ egg"
                    end
                    task.wait(0.35)
                end
            end
        end
        Runtime.AutoFarmRunning = false
        Runtime.DestroyControlClone("AutoFarm")
        if Runtime.AutoFarmStatusLabel and (not Runtime.AutoFarmConfig or not Runtime.AutoFarmConfig.enabled) then
            Runtime.AutoFarmStatusLabel.Text = "Stopped"
        end
    end)
end


local function shortStatus(id)
    if Job.busy and Job.eggId == id and Job.status ~= "Idle" then
        return Job.status
    end
    return "Idle"
end


--========================= CARDS (яйца в Main) =========================--
local function makeCard(row)
    return static(function()
        local col = RARITY_COLOR[row.Rarity] or T.DropBorder
        local card = create("Frame", {
            Size = UDim2.new(1, 0, 0, 138), BorderSizePixel = 0, ClipsDescendants = true, BackgroundColor3 = T.DropBg,
        }, EggList)
        corner(card, 12)
        local cardStroke = create("UIStroke", {
            Color = col, Thickness = 1.2, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, card)

        local icon = create("ImageLabel", {
            BackgroundColor3 = col, BackgroundTransparency = 0.2, BorderSizePixel = 0,
            Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(40, 40),
            Image = row.Icon or "", ScaleType = Enum.ScaleType.Fit,
        }, card)
        corner(icon, 9)
        local letter = text(icon, {
            Size = UDim2.fromScale(1, 1), FontFace = F.Bold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = Color3.fromRGB(20, 20, 20), Text = string.upper(string.sub(row.Name, 1, 1)), Visible = row.Icon == nil,
        })

        local function line(y, colorKey, bold)
            return text(card, {
                Position = UDim2.fromOffset(58, y), Size = UDim2.new(1, -66, 0, 15),
                FontFace = bold and F.Bold or F.Medium, TextSize = bold and 14 or 12,
                TextTruncate = Enum.TextTruncate.AtEnd, Col = colorKey,
            })
        end
        local name = line(7, "Text", true)
        local rarity = line(26, "Sub", false)
        local stats = line(42, "Sub", false)
        local mutation = line(58, "Dim", false)
        local traits = line(73, "Dim", false)
        local status = line(88, "Text", true)

        local function button(x, w, label)
            local b = create("TextButton", {
                Position = UDim2.new(x, 9, 1, -34), Size = UDim2.new(w, -6, 0, 26), AutoButtonColor = false,
                FontFace = F.Bold, Text = label, TextSize = 12, BorderSizePixel = 0,
                BackgroundColor3 = T.Item, TextColor3 = T.Sub,
            }, card)
            corner(b, 8)
            return b
        end
        local flyBtn = button(0, 0.27, "Fly")
        local instantBtn = button(0.27, 0.31, "Instant")
        local stealBtn = button(0.58, 0.42, "Steal")
        stealBtn.Position = UDim2.new(0.58, 3, 1, -34)
        stealBtn.Size = UDim2.new(0.42, -12, 0, 26)

        local rec = {
            frame = card, stroke = cardStroke, icon = icon, letter = letter,
            name = name, rarity = rarity, stats = stats, mutation = mutation, traits = traits, status = status,
            fly = flyBtn, instant = instantBtn, steal = stealBtn, row = row,
        }

        local function paintMode()
            local mode = Modes[row.Id] or "Fly"
            local function paint(b, active)
                b.BackgroundColor3 = active and T.Accent or T.Item
                b.TextColor3 = active and T.OnAccent or T.Sub
            end
            paint(flyBtn, mode == "Fly")
            paint(instantBtn, mode ~= "Fly")
        end
        paintMode()
        rec.paintMode = paintMode

        on(flyBtn.Activated, function()
            Modes[row.Id] = "Fly"
            paintMode()
        end)
        on(instantBtn.Activated, function()
            Modes[row.Id] = "Instant"
            paintMode()
        end)
        on(stealBtn.Activated, function()
            if Job.busy then
                if Job.eggId == row.Id then
                    Job.token = Job.token + 1
                    Job.busy = false
                    stopFlight()
                    Runtime.ClearPlatformRoute()
                    setStatus("Cancelled", row.Id)
                    stealBtn.Text = "Steal"
                    if NotifyOn then notify("Steal cancelled: " .. tostring(row.Name)) end
                    return
                end
                setStatus("Busy", Job.eggId)
                return
            end
            local mode = Modes[row.Id] or "Fly"
            stealBtn.Text = "Cancel"
            task.spawn(function()
                local ok, err = xpcall(function()
                    runSteal(rec.row, mode)
                end, function(message)
                    return tostring(message)
                end)
                if not ok then
                    warn("[Sterling] " .. tostring(err))
                    setStatus("Error", row.Id)
                    stopFlight()
                    Job.busy = false
                    if NotifyOn then notify("Steal error: " .. tostring(row.Name)) end
                end
            end)
        end)
        return rec
    end)
end

local function updateCard(rec, row, order)
    local col = RARITY_COLOR[row.Rarity] or T.DropBorder
    rec.row = row
    rec.frame.LayoutOrder = order
    rec.frame.Visible = true
    rec.name.Text = row.Name
    rec.rarity.Text = row.RarityText
    rec.rarity.TextColor3 = col
    rec.stats.Text = "Luck " .. formatNumber(row.Luck) .. "   |   " .. formatNumber(row.KG) .. " kg"
    rec.mutation.Text = "Mutation: " .. row.Mutation
    rec.traits.Text = "Traits: " .. row.Traits
    if Job.eggId == row.Id and Job.busy then
        rec.status.Text = Job.status
    elseif row.Spawning then
        rec.status.Text = "Spawning"
    else
        rec.status.Text = "Idle"
    end
    rec.stroke.Color = col
    rec.icon.BackgroundColor3 = col
    if row.Icon and row.Icon ~= "" then
        rec.icon.Image = row.Icon
        rec.letter.Visible = false
    else
        rec.icon.Image = ""
        rec.letter.Visible = true
        rec.letter.Text = string.upper(string.sub(row.Name, 1, 1))
    end
    local busyHere = Job.busy and Job.eggId == row.Id
    rec.steal.Text = busyHere and "Cancel" or "Steal"
    rec.steal.BackgroundColor3 = busyHere and T.Item or T.Accent
    rec.steal.TextColor3 = busyHere and T.Text or T.OnAccent
end

-- при смене темы карточки пересоздаются (цвета берутся из темы)
table.insert(themeListeners, function()
    for id, rec in pairs(Cards) do
        pcall(function() rec.frame:Destroy() end)
        Cards[id] = nil
    end
end)


local espFolder = Instance.new("Folder")
espFolder.Name = "SterlingESP"
espFolder.Parent = workspace.CurrentCamera or workspace

local function updateEsp(rows)
    if not WorldEsp then
        for id, mark in pairs(EspMarks) do
            if mark.part then mark.part:Destroy() end
            EspMarks[id] = nil
        end
        return
    end
    if espFolder.Parent == nil then
        espFolder = Instance.new("Folder")
        espFolder.Name = "SterlingESP"
    end
    espFolder.Parent = workspace.CurrentCamera or workspace
    local seen = {}
    for _, row in ipairs(rows) do
        seen[row.Id] = true
        local mark = EspMarks[row.Id]
        if not mark or not mark.part or not mark.part.Parent then
            local part = Instance.new("Part")
            part.Name = "EggMark"
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Transparency = 1
            part.Size = Vector3.new(2, 2, 2)
            part.Parent = espFolder
            local bill = Instance.new("BillboardGui")
            bill.Size = UDim2.fromOffset(180, 78)
            bill.StudsOffset = Vector3.new(0, 3.2, 0)
            bill.AlwaysOnTop = true
            bill.MaxDistance = 12000
            bill.Parent = part
            local bg = Instance.new("Frame")
            bg.Size = UDim2.fromScale(1, 1)
            bg.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
            bg.BackgroundTransparency = 0.25
            bg.Parent = bill
            corner(bg, 8)
            stroke(bg, Color3.fromRGB(200, 200, 200), 1, 0.25)
            local text = Instance.new("TextLabel")
            text.BackgroundTransparency = 1
            text.Size = UDim2.new(1, -8, 1, -6)
            text.Position = UDim2.fromOffset(4, 3)
            text.Font = Enum.Font.Gotham
            text.TextSize = 11
            text.TextXAlignment = Enum.TextXAlignment.Left
            text.TextYAlignment = Enum.TextYAlignment.Top
            text.TextColor3 = Color3.fromRGB(235, 235, 235)
            text.TextWrapped = true
            text.Text = ""
            text.Parent = bg
            mark = { part = part, text = text }
            EspMarks[row.Id] = mark
        end
        mark.part.Position = row.Position + Vector3.new(0, 2, 0)
        local state = shortStatus(row.Id)
        if row.Spawning and state == "Idle" then
            state = "Spawning"
        end
        mark.text.Text = table.concat({
            row.Name,
            row.RarityText .. "  Luck " .. formatNumber(row.Luck),
            formatNumber(row.KG) .. " kg",
            "Mutation: " .. row.Mutation,
            "Traits: " .. row.Traits,
            state,
        }, "\n")
    end
    for id, mark in pairs(EspMarks) do
        if not seen[id] then
            if mark.part then mark.part:Destroy() end
            EspMarks[id] = nil
        end
    end
end


local function refreshEggs()
    local rows = scanEggs()
    EmptyLabel.Visible = #rows == 0 and not Job.busy
    local seen = {}
    for i, row in ipairs(rows) do
        seen[row.Id] = true
        local rec = Cards[row.Id]
        if not rec or not rec.frame.Parent then
            rec = makeCard(row)
            Cards[row.Id] = rec
        end
        if rec then
            updateCard(rec, row, i)
        end
    end
    for id, rec in pairs(Cards) do
        if not seen[id] then
            if Job.busy and Job.eggId == id then
                rec.frame.Visible = true
                rec.steal.Text = "Cancel"
            else
                rec.frame:Destroy()
                Cards[id] = nil
                Modes[id] = nil
            end
        end
    end
    updateEsp(rows)
    if Job.eggId and Job.busy then
        StatusLabel.Text = "Status: " .. Job.status
    elseif not Job.busy and Job.status == "Idle" then
        StatusLabel.Text = "Status: Idle"
    end
end

-- Уведомления о ходе кражи (через Window:Notify вместо отдельного оверлея)
local NOTE_WORDS = { "egg in hands", "dip passed", "delivered", "completed", "disappeared", "cancelled", "failed", "not found" }
local noteLastKey
refreshNote = function()
    local row = Job.row
    if not row then
        noteLastKey = nil
        return
    end
    if not NotifyOn then return end
    local status = tostring(Job.status or "")
    local lower = string.lower(status)
    local key = tostring(row.Id) .. "|" .. lower
    if key == noteLastKey then return end
    local first = noteLastKey == nil
    noteLastKey = key
    local label = string.format("%s (%s, Luck %s)", tostring(row.Name), tostring(row.RarityText), formatNumber(row.Luck))
    if first and Job.busy then
        notify("Steal started: " .. label)
        return
    end
    for _, word in ipairs(NOTE_WORDS) do
        if string.find(lower, word, 1, true) then
            notify(label .. " - " .. status)
            return
        end
    end
end



--========================= AUTOMATION =========================--
local instantTo, objectPosition
do
    objectPosition = function(object)
        if object:IsA("BasePart") then return object.Position end
        if object:IsA("Model") then return object:GetPivot().Position end
        return nil
    end
    instantTo = function(position)
        if Runtime.InstantTo then
            Runtime.InstantTo(position)
            return
        end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and position then
            root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

do
    local auto = FTabs.Automation
    local rarities = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal" }

    -- Safe Steal -----------------------------------------------------------------
    local plat = auto:Section("Safe Steal", "route")
    plat:Label("Best pet, instant pickup, volcano dip, then a synchronized platform run along the line to My Ranch.")
    plat:Slider("Run Boost", 100, 2000, Runtime.PlatformConfig.speed, function(v)
        Runtime.PlatformConfig.speed = math.floor(v)
    end, 50)
    plat:Dropdown("Rarity", rarities, Runtime.PlatformConfig.rarity, function(v)
        Runtime.PlatformConfig.rarity = v
    end)
    Runtime.PlatformStatusLabel = labelProxy(plat:Label("Stopped"))
    plat:Toggle("Safe Steal", false, function(value)
        Runtime.PlatformConfig.enabled = value
        if value then
            Runtime.PlatformStatusLabel.Text = "Starting"
            task.spawn(function()
                while Alive and value and not Runtime.StartPlatformSteal do task.wait(0.1) end
                if Runtime.PlatformConfig.enabled and Runtime.StartPlatformSteal then
                    Runtime.StartPlatformSteal()
                end
            end)
        else
            Runtime.PlatformStatusLabel.Text = "Stopped"
            if Runtime.StopPlatformSteal then Runtime.StopPlatformSteal() end
        end
    end)

    -- Auto Collect Egg --------------------------------------------------------------
    local farm = auto:Section("Auto Collect Egg", "egg")
    farm:Label("Pick the minimum egg rarity, then enable Auto Collect Egg: the script watches new spawns, instantly picks a matching egg, confirms Volcano Dip and teleports to My Ranch. Starts Off after every load.")
    farm:Dropdown("Rarity", rarities, Runtime.AutoFarmConfig.rarity, function(v)
        Runtime.AutoFarmConfig.rarity = v
    end)
    Runtime.AutoFarmStatusLabel = labelProxy(farm:Label("Stopped"))
    farm:Toggle("Volcano Dip", false, function(value)
        Runtime.AutoFarmConfig.volcanoDip = value
    end)
    farm:Toggle("Auto Collect Egg", false, function(value)
        Runtime.AutoFarmConfig.enabled = value
        if value then
            Runtime.AutoFarmStatusLabel.Text = "Watching egg spawns"
            task.spawn(function()
                while Alive and value and not Runtime.StartAutoFarm do task.wait(0.1) end
                if Runtime.AutoFarmConfig.enabled and Runtime.StartAutoFarm then
                    Runtime.StartAutoFarm()
                end
            end)
        else
            Runtime.AutoFarmStatusLabel.Text = "Stopped"
            if Runtime.StopAutoFarm then Runtime.StopAutoFarm() end
        end
    end)

    -- Auto Sky Race ----------------------------------------------------------------------
    local race = auto:Section("Auto Sky Race", "flag")
    race:Label("Requires a flying pet: Phoenix, Mantis, Griffin, Dragon, Hydra Dragon or Dragon Skeleton.")
    Runtime.RaceStatusLabel = labelProxy(race:Label("Stopped"))
    race:Toggle("Auto Sky Race", false, function(value)
        Runtime.RaceConfig.enabled = value
        if value then
            Runtime.RaceStatusLabel.Text = "Starting"
            task.spawn(function()
                while Alive and value and not Runtime.StartSkyRace do task.wait(0.1) end
                if Runtime.RaceConfig.enabled and Runtime.StartSkyRace then Runtime.StartSkyRace() end
            end)
        else
            Runtime.RaceStatusLabel.Text = "Stopped"
            if Runtime.StopSkyRace then Runtime.StopSkyRace() end
        end
    end)

    -- Halloween Event ------------------------------------------------------------------------
    local hal = auto:Section("Halloween Event", "ghost")
    Runtime.Halloween = {
        collect = false, ritual = false, pumpkins = false, buy = false,
        rareFirst = false, mode = "Nearest", rarity = "Rare", running = false,
    }
    local state = Runtime.Halloween
    local status = labelProxy(hal:Label("Off - Candy 0 | carrying 0 | not on the island"))
    hal:Toggle("Collect Candy", false, function(value)
        state.collect = value
        if value and Runtime.RideBestPet then
            task.spawn(Runtime.RideBestPet)
        end
    end)
    hal:Dropdown("Candy", { "Nearest", "Highest" }, state.mode, function(v)
        state.mode = v
    end)
    hal:Toggle("Halloween Ritual", false, function(v) state.ritual = v end)
    hal:Toggle("Search Pumpkins", false, function(v) state.pumpkins = v end)
    hal:Toggle("Buy Halloween Egg", false, function(v) state.buy = v end)
    hal:Toggle("Rare Eggs First", false, function(v) state.rareFirst = v end)
    hal:Dropdown("Rare Eggs From", { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal", "Event" }, state.rarity, function(v)
        state.rarity = v
    end)


    local function candyId(object, index)
        for _, child in ipairs(object:GetChildren()) do
            if child:IsA("ValueBase") then return tostring(child.Value) end
        end
        for _, key in ipairs({ "Id", "CandyId", "Index", "Number", "ID" }) do
            local value = object:GetAttribute(key)
            if value ~= nil then return tostring(value) end
        end
        local number = string.match(object.Name, "(%d+)")
        return number and ("Candy1_" .. number) or ("Candy1_" .. tostring(index))
    end
    local function candyValue(object)
        for _, key in ipairs({ "Value", "Worth", "CandyValue", "Rarity", "Points", "Amount", "Tier" }) do
            local value = tonumber(object:GetAttribute(key))
            if value then return value end
        end
        return tonumber(string.match(object.Name, "(%d+)")) or 0
    end
    local function candyCount()
        return tonumber(LocalPlayer:GetAttribute("Candy") or LocalPlayer:GetAttribute("HalloweenCandy") or 0) or 0
    end
    local portalPosition = Vector3.new(194.19, 40315.65, 677.15)
    local function enterHalloween()
        if state.entered then return true end
        status.Text = "Entering Halloween portal"
        if Runtime.RideBestPet then
            pcall(Runtime.RideBestPet)
        end
        instantTo(portalPosition)
        task.wait(0.35)
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local parent = prompt.Parent
                if parent and parent:IsA("Attachment") then parent = parent.Parent end
                if parent and parent:IsA("BasePart") and (parent.Position - portalPosition).Magnitude <= 25 then
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(math.max(prompt.HoldDuration, 0.05) + 0.05)
                            prompt:InputHoldEnd()
                        end
                    end)
                    break
                end
            end
        end
        task.wait(0.8)
        state.entered = true
        return true
    end

    task.spawn(function()
        while Alive do
            local active = state.collect or state.ritual or state.pumpkins or state.buy
            if not active then
                state.entered = false
                if Runtime.DestroyControlClone then Runtime.DestroyControlClone("Candy") end
                status.Text = "Off - Candy " .. tostring(candyCount()) .. " | carrying 0 | not on the island"
                task.wait(0.4)
            else
                if state.collect then
                    local cloneDrop = workspace:FindFirstChild("CandyDropOff")
                    local clonePosition = cloneDrop and objectPosition(cloneDrop)
                    if clonePosition and Runtime.CreateControlClone then Runtime.CreateControlClone(clonePosition, "Candy") end
                else
                    if Runtime.DestroyControlClone then Runtime.DestroyControlClone("Candy") end
                end
                enterHalloween()
                if state.collect then
                    local folder = workspace:FindFirstChild("HalloweenCandy")
                    local dropoff = workspace:FindFirstChild("CandyDropOff")
                    local candies = folder and folder:GetChildren() or {}
                    local candyIndex = {}
                    for index, candy in ipairs(candies) do candyIndex[candy] = index end
                    table.sort(candies, function(a, b)
                        if state.mode == "Highest" then
                            return candyValue(a) > candyValue(b)
                        end
                        local dropPos = dropoff and objectPosition(dropoff) or Vector3.zero
                        local aPos, bPos = objectPosition(a) or Vector3.zero, objectPosition(b) or Vector3.zero
                        return (aPos - dropPos).Magnitude < (bPos - dropPos).Magnitude
                    end)
                    local target = candies[1]
                    local targetPos = target and objectPosition(target)
                    if target and targetPos then
                        status.Text = "Collecting " .. target.Name .. " | " .. state.mode
                        instantTo(targetPos)
                        local remote = Runtime.Remotes.CollectCandy
                        local id = candyId(target, candyIndex[target] or 1)
                        local picked = false
                        local pickupDeadline = os.clock() + 8
                        while state.collect and target.Parent and os.clock() < pickupDeadline do
                            instantTo(targetPos)
                            if Runtime.ActivateNearbyPrompt then Runtime.ActivateNearbyPrompt(targetPos, 50) end
                            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                pcall(function()
                                    prompt.MaxActivationDistance = 1000
                                    prompt.HoldDuration = 0
                                    prompt.RequiresLineOfSight = false
                                    if fireproximityprompt then fireproximityprompt(prompt) end
                                end)
                            end
                            if remote and remote:IsA("RemoteEvent") then
                                remote:FireServer(id)
                            elseif remote and remote:IsA("RemoteFunction") then
                                pcall(function() remote:InvokeServer(id) end)
                            end
                            task.wait(0.05)
                            if not target.Parent or target.Parent ~= folder then
                                picked = true
                                break
                            end
                        end
                        if not target.Parent or target.Parent ~= folder then
                            picked = true
                        end
                        if picked and dropoff then
                            status.Text = "Candy secured - anti-cheat wait"
                            task.wait(2.5)
                            status.Text = "Candy secured - delivering"
                            instantTo(objectPosition(dropoff))
                            local drop = Runtime.Remotes.DropCandy
                            if drop and drop:IsA("RemoteEvent") then
                                drop:FireServer()
                            end
                            task.wait(0.35)
                        elseif not picked then
                            status.Text = "Instant candy pickup retry"
                        end
                    end
                end
                if state.pumpkins then
                    local search = Runtime.Remotes.SearchPumpkin
                    if search and search:IsA("RemoteEvent") then
                        for _, object in ipairs(workspace:GetDescendants()) do
                            if string.find(string.lower(object.Name), "pumpkin", 1, true) then
                                local pos = objectPosition(object)
                                if pos then
                                    instantTo(pos)
                                    search:FireServer(object:GetAttribute("Id") or object.Name)
                                    break
                                end
                            end
                        end
                    end
                end
                if state.ritual then
                    for _, remoteName in ipairs({ "GiantPumpkin", "GiantPumpkinSwing", "GiantPumpkinHit" }) do
                        local remote = Runtime.Remotes[remoteName]
                        if remote and remote:IsA("RemoteEvent") then
                            pcall(function() remote:FireServer() end)
                        end
                    end
                end
                if state.buy then
                    local buy = Runtime.Remotes.BuyHalloweenEgg
                    if buy and buy:IsA("RemoteEvent") then
                        pcall(function() buy:FireServer() end)
                    end
                end
                status.Text = "On - Candy " .. tostring(candyCount()) .. " | mode " .. state.mode
                task.wait(0.35)
            end
        end
    end)


end



--========================= PETS =========================--
do
    local pets = FTabs.Pets
    local ride = pets:Section("Ride", "paw-print")
    ride:Button("Ride Best Pet", function()
        if Runtime.RideBestPet then
            task.spawn(Runtime.RideBestPet)
        end
    end)
    local seraph = pets:Section("Seraph Egg Craft", "egg")
    local atHeaven = false
    seraph:Button("Heaven Area (TP/Back)", function()
        if not atHeaven then
            instantTo(Vector3.new(-464.65, 42429.91, 930.84))
            atHeaven = true
            notify("Heaven Area: teleported. Press the button again to return to My Ranch")
        else
            if Runtime.GoToRanch then
                Runtime.GoToRanch("Instant")
            else
                local remote = Runtime.Remotes.TeleportToPlot
                if remote and remote:IsA("RemoteEvent") then remote:FireServer() end
            end
            atHeaven = false
            notify("Returned to My Ranch")
        end
    end)
end

--========================= MISC =========================--
do
    local misc = FTabs.Misc
    local pick = misc:Section("Instant PickUp", "hand")
    pick:Toggle("Instant PickUp", false, function(value)
        Runtime.InstantPickupEnabled = value
        if Runtime.SetInstantPickup then Runtime.SetInstantPickup(value) end
    end)
    pick:Toggle("Notification", NotifyOn, function(value)
        NotifyOn = value
        if refreshNote then refreshNote() end
    end)

    local hist = misc:Section("Steal History", "history")
    local histLabel = hist:Label("No successful steals in the last 5 days")
    Runtime.StealHistory = Storage.loadHistory()
    local function refreshHistory()
        local list = Runtime.StealHistory or {}
        if #list == 0 then
            histLabel:Set("No successful steals in the last 5 days")
            return
        end
        local lines = {}
        for index = #list, math.max(1, #list - 14), -1 do
            local e = list[index]
            table.insert(lines, string.format("%s  %s [%s | Luck %s]\n  Mutation: %s | Traits: %s | From: %s",
                tostring(e.date or ""), tostring(e.name or "Egg"), tostring(e.rarity or "Unknown"), tostring(e.luck or "0"),
                tostring(e.mutation or "None"), tostring(e.traits or "-"), tostring(e.from or "Unknown")))
        end
        histLabel:Set(table.concat(lines, "\n"))
    end
    Runtime.RefreshHistory = refreshHistory
    hist:Button("Refresh History", refreshHistory)
    refreshHistory()
end

--========================= PERFORMANCE (кнопки в вкладке Performance) =========================--
do
    local levels = { AntiLag = 1, FPS = 1 }
    Runtime.PerformanceLevels = levels
    local originals = setmetatable({}, { __mode = "k" })


    local function remember(instance, property)
        originals[instance] = originals[instance] or {}
        if originals[instance][property] == nil then
            pcall(function()
                originals[instance][property] = instance[property]
            end)
        end
    end

    local function optimize(level)
        level = math.clamp(level, 1, 5)
        local Lighting = game:GetService("Lighting")
        if level >= 2 then
            remember(Lighting, "GlobalShadows")
            Lighting.GlobalShadows = false
        end
        for _, object in ipairs(game:GetDescendants()) do
            pcall(function()
                if object:IsA("PostEffect") and level >= 1 then
                    remember(object, "Enabled")
                    object.Enabled = false
                elseif (object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")) and level >= 2 then
                    remember(object, "Enabled")
                    object.Enabled = false
                elseif object:IsA("BasePart") and level >= 3 then
                    remember(object, "CastShadow")
                    object.CastShadow = false
                    if level >= 4 and object.Material ~= Enum.Material.Neon then
                        remember(object, "Material")
                        object.Material = Enum.Material.Plastic
                    end
                elseif (object:IsA("Texture") or object:IsA("Decal")) and level >= 5 then
                    remember(object, "Transparency")
                    object.Transparency = 1
                end
            end)
        end
    end

    local function restorePerformance()
        for instance, properties in pairs(originals) do
            if instance and instance.Parent then
                for property, value in pairs(properties) do
                    pcall(function()
                        instance[property] = value
                    end)
                end
            end
        end
        originals = setmetatable({}, { __mode = "k" })
    end
    Runtime.RestorePerformance = restorePerformance


    local enabled = { AntiLag = false, FPS = false }
    local function reapplyPerformance()
        restorePerformance()
        if enabled.AntiLag then optimize(levels.AntiLag) end
        if enabled.FPS then optimize(levels.FPS) end
    end
    FuncHooks.FPSBoost = function(v)
        enabled.FPS = v and true or false
        reapplyPerformance()
    end
    FuncHooks.AntiLag = function(v)
        enabled.AntiLag = v and true or false
        reapplyPerformance()
    end
    FuncHooks.FPSBoostLevel = function(n)
        levels.FPS = math.clamp(n or 1, 1, 5)
        if enabled.FPS then reapplyPerformance() end
    end
    FuncHooks.AntiLagLevel = function(n)
        levels.AntiLag = math.clamp(n or 1, 1, 5)
        if enabled.AntiLag then reapplyPerformance() end
    end
end

--========================= ЦИКЛ ОБНОВЛЕНИЯ / ВЫГРУЗКА =========================--
local eggTick = 0
on(RunService.RenderStepped, function()
    if not Alive then return end
    local t = os.clock()
    if NotifyOn and Job.busy and refreshNote then
        pcall(refreshNote)
    end
    if t - eggTick >= 0.55 then
        eggTick = t
        local ok, err = pcall(refreshEggs)
        if not ok then
            warn("[Sterling] scan " .. tostring(err))
        end
    end
end)

local function unload()
    if not Alive then return end
    Alive = false
    Job.token = Job.token + 1
    stopFlight()
    if Runtime.ClearPlatformRoute then Runtime.ClearPlatformRoute() end
    if Runtime.RestorePerformance then pcall(Runtime.RestorePerformance) end
    if Runtime.DestroyControlClone then pcall(Runtime.DestroyControlClone) end
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    if _G.SterlingPickupHook then
        pcall(function() _G.SterlingPickupHook:Disconnect() end)
        _G.SterlingPickupHook = nil
    end
    if espFolder then
        espFolder:Destroy()
    end
    if _G.SterlingEngine and _G.SterlingEngine.Unload == unload then
        _G.SterlingEngine = nil
    end
end

_G.SterlingEngine = {
    Unload = unload,
    Remotes = Runtime.Remotes,
}

end -- InstallFunctions

InstallFunctions(Window, FTabs, FuncHooks)
