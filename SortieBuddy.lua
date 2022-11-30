_addon.name = 'SortieBuddy'
_addon.author = 'Dabidobido'
_addon.version = '1.0.1'
_addon.commands = {'sortiebuddy', 'srtb' }

packets = require('packets')
config = require('config')
texts = require('texts')
require('logger')

indexes = {
	["a"] = 144,
	["b"] = 223,
	["c"] = 285,
	["d"] = 373,
	["f"] = 837,
	["g"] = 838,
	["h"] = 839,
	['test'] = 73,
}

reverse_index = {
	[144] = "a",
	[223] = "b",
	[285] = "c",
	[373] = "d",
	[837] = "f",
	[838] = "g",
	[839] = "h",
	[73] = 'test',
}

targets = {}
current_target = ""
current_zone = 0
test_mode = false

default_settings = {}
default_settings.pos = {}
default_settings.pos.x = 144
default_settings.pos.y = 144
default_settings.text = {}
default_settings.text.font = 'Segoe UI'
default_settings.text.size = 12
default_settings.text.alpha = 255
default_settings.text.red = 246
default_settings.text.green = 131
default_settings.text.blue = 188
default_settings.bg = {}
default_settings.bg.alpha = 175
default_settings.bg.red = 052
default_settings.bg.green = 109
default_settings.bg.blue = 166
settings = config.load(default_settings)
text_box = texts.new(settings)

function help_command()
	notice("ping (target): ping the a/b/c/d NMs or f/g/h bitzer")
end

windower.register_event('addon command', function (...)
	local args = T{...}
	local command = args[1]:lower()

	if command == 'ping' and args[2] then
		local arg2 = args[2]:lower()
		if indexes[arg2] then 
			targets = {}
			text_box:visible(false)
			current_target = arg2
			if current_target == "test" then test_mode = true end
			local p = packets.new('outgoing', 0x016)
			p["Target Index"] = indexes[current_target]
			packets.inject(p)
		else
			notice("Ping command needs argument.")
		end
	else
		help_command()
	end
end)

function get_distance(p1, p2)
	return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2))
end

function get_direction(p1, p2)
	local angle = math.atan2(p2.y - p1.y, p2.x - p1.x)
	angle = angle + math.pi
	angle = angle / (math.pi * 2 / 8)
	local heading = math.round(angle) % 8
	if heading == 0 then return "W"
	elseif heading == 1 then return "SW"
	elseif heading == 2 then return "S"
	elseif heading == 3 then return "SE"
	elseif heading == 4 then return "E"
	elseif heading == 5 then return "NE"
	elseif heading == 6 then return "N"
	elseif heading == 7 then return "NW"
	else return "??"
	end
end

function update_text()
	local new_text = ""
	local player = windower.ffxi.get_mob_by_target('me')
	for k,v in pairs(targets) do
		new_text = new_text .. reverse_index[k]:upper() .. " Distance: " .. string.format("%.2f",get_distance(player, v)) .. " (" .. get_direction(player,v) .. ")\n"
	end
	text_box:text(new_text)
end

windower.register_event("incoming chunk", function(id, data)
	if current_zone == 133 and current_target ~= "" or current_target == 'test' then
		if id == 0x0E then
			local packet = packets.parse('incoming', data)
			local mob_index = packet["Index"]
			if indexes[current_target] == mob_index then
				local mobx = packet['X']
				local moby = packet['Y']
				notice("got mob x: "  .. string.format("%.2f", mobx) .. " y: " .. string.format("%.2f", moby))
				targets[mob_index] = { x = mobx, y = moby }
				current_target = ""
				text_box:visible(true)
			end
		end
	end
end)

function zone_change(new, old)
	targets = {}
	current_target = ""
	current_zone = new
	test_mode = false
	text_box:visible(false) 
end

function reset()
	zone_change("")
end

windower.register_event('zone change', zone_change)
windower.register_event('logout', reset)
windower.register_event('login', reset)

windower.register_event('prerender', function()
	if current_zone == 133 or test_mode then 
		--update()
		update_text() 
	end
end)