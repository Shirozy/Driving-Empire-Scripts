# Script Examples

## Cash Values
- Example 1: integer only
```lua
local cash_no_cents = get_player_cash("no_cents")
print("Cash with no cents:", cash_no_cents)
```

Output Example: 
```
Cash with no cents: 1000
```

Exammple output after Escaped:
```
Cash with no cents: 0
```

---

- Example 2: full number including cents
```lua
local cash_with_cents = get_player_cash("with_cents")
print("Cash with cents:", cash_with_cents)
```

Output Example: 
```
Cash with cents: 2500.50
```

Exammple output after Escaped:
```
Cash with cents: 0
```

---

- Example 3: split into dollars and cents
```lua
local dollars, cents = get_player_cash("split")
print("Dollars:", dollars, "Cents:", cents)
```

Output Example: 
```
Dollars: 1500 Cents: 25
```

Exammple output after Escaped:
```
Dollars: 0 Cents: 0
```

---

- Example 4: get the raw label
```lua
local cash_label = get_player_criminal_cash_label()
if cash_label then
	print("Raw cash label text:", cash_label.Text)
end
```

Output Example: 
```
Raw cash label text: $1500.25
```

Exammple output after Escaped:
```
Raw cash label text: $0
```

---

## Time Escape Values

- Example 5: get just the notification time text
```lua
local escape_time_text = get_escape_notification("time_text")
print("Escape time text:", escape_time_text)
```

Output Example:
```
Escape time text: 01:30
```

Exammple output after Escaped:
```
Escape time text: nil
```

---

- Example 6: get just the notification seconds
```lua
local escape_seconds = get_escape_notification("seconds")
print("Escape seconds:", escape_seconds)
```

Output Example:
```
Escape seconds: 90
```

Exammple output after Escaped:
```
Escape seconds: nil
```

---

- Example 7: get both
```lua
local notification_time_text, notification_seconds = get_escape_notification("both")
print("Notification time text:", notification_time_text)
print("Notification seconds:", notification_seconds)
```

Output Example:
```
Notification time text: 01:30
Notification seconds: 90
```

Exammple output after Escaped:
```
Notification time text: nil
Notification seconds: nil
```

---

## Extra

- Example 8: combined usage
```lua
if cash_no_cents and notification_seconds then
	if cash_no_cents >= 1000 and notification_seconds <= 30 then
		print("Player has at least $1000 and 30 seconds or less remain.")
	end
end
```

Output Example:
```
Player has at least $1000 and 30 seconds or less remain.
```

Exammple output after Escaped:
```

```

---

# Script
```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local notifications = player.PlayerGui:WaitForChild("MainHUD"):WaitForChild("Notification")

local function time_to_seconds(time_text: string): number
	local minutes, seconds = string.match(time_text, "^(%d+):(%d+)$")

	if not minutes or not seconds then
		return 0
	end

	return (tonumber(minutes) * 60) + tonumber(seconds)
end

local function get_player_criminal_cash_label(): TextLabel?
	local character = player.Character or player.CharacterAdded:Wait()
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	local billboard = head:FindFirstChild("CharacterBillboard")
	if not billboard then
		return nil
	end

	for _, instance in ipairs(billboard:GetChildren()) do
		if not instance:IsA("TextLabel") then
			continue
		end

		if string.match(instance.Text, "^%$") then
			return instance
		end
	end

	return nil
end

local function parse_cash_text(cash_text: string): (number, number)
	local cleaned_text = cash_text:gsub("[%$,]", "")
	local dollars_text, cents_text = string.match(cleaned_text, "^(%d+)%.?(%d*)$")

	if not dollars_text then
		return 0, 0
	end

	local dollars = tonumber(dollars_text) or 0
	local cents = tonumber(cents_text) or 0

	return dollars, cents
end

type CashMode = "no_cents" | "with_cents" | "split"

local function get_player_cash(mode: CashMode)
	local cash_label = get_player_criminal_cash_label()
	if not cash_label then
		return nil
	end

	local dollars, cents = parse_cash_text(cash_label.Text)

	if mode == "no_cents" then
		return dollars
	end

	if mode == "with_cents" then
		return dollars + (cents / 100)
	end

	if mode == "split" then
		return dollars, cents
	end

	return nil
end

type NotificationMode = "time_text" | "seconds" | "both"

local function get_escape_notification(mode: NotificationMode)
	for _, notification in ipairs(notifications:GetChildren()) do
		if not notification:IsA("ImageLabel") then
			continue
		end

		local title = notification:FindFirstChild("Title")
		if not title or not title:IsA("TextLabel") then
			continue
		end

		local time_text = string.match(title.Text, "^Escape the security:%s*(%d+:%d+)$")
		if not time_text then
			continue
		end

		local seconds = time_to_seconds(time_text)

		if mode == "time_text" then
			return time_text
		end

		if mode == "seconds" then
			return seconds
		end

		if mode == "both" then
			return time_text, seconds
		end
	end

	return nil
end
```
