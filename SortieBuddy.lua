_addon.name = 'SortieBuddy'
_addon.author = 'Dabidobido'
_addon.version = '1.1.2'
_addon.commands = {'sortiebuddy', 'srtb' }

packets = require('packets')
config = require('config')
texts = require('texts')
require('logger')

targets = nil
current_target = ""
current_zone = nil
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

default_settings.mobs = {}
default_settings.mobs["133"] = {} -- Sortie
default_settings.mobs["133"]["a"] = 144
default_settings.mobs["133"]["b"] = 223
default_settings.mobs["133"]["c"] = 285
default_settings.mobs["133"]["d"] = 373
default_settings.mobs["133"]["f"] = 837
default_settings.mobs["133"]["g"] = 838
default_settings.mobs["133"]["h"] = 839
settings = config.load(default_settings)

text_box = texts.new(settings)

function help_command()
	notice("showinfo: shows target infor for current zone")
	notice("ping (name): ping a target for the current zone")
	notice("spawn (name): forces a target to spawn in the current zone")
	notice("add (name): saves the currently selected target to settings so that it can be spawned or pinged later")
	notice("remove (zone_id, name): removes the named target from the zone_id in the settings file")
	notice("Default settings has target information for Sortie:")
	notice("a = Abject Obdella")
	notice("b = Biune Porxie")
	notice("c = Cachaemic Bhoot")
	notice("d = Demisang Deleterious")
	notice("f = Diaphanous Bitzer #F")
	notice("g = Diaphanous Bitzer #G")
	notice("h = Diaphanous Bitzer #H")
end

windower.register_event('addon command', function (...)
	local args = T{...}
	local command = args[1]:lower()

	if command == 'ping' then
		if args[2] then
			local zone = tostring(windower.ffxi.get_info().zone)
			if settings.mobs[zone] then
				local arg2 = args[2]:lower()
				if settings.mobs[zone][arg2] then
					targets = nil
					text_box:visible(false)
					current_target = arg2
					local p = packets.new('outgoing', 0x016)
					p["Target Index"] = settings.mobs[zone][current_target]
					packets.inject(p)
				else
					notice("Error: No info for " .. arg2 .. " in zone " .. zone )
				end
			else
				notice("Error: No info for zone " .. zone)
			end
		else
			notice("Error: Ping command needs a name for 2nd argument")
		end
	elseif command == 'add' and args[2] then
		if args[2] then
			local player = windower.ffxi.get_player()
			local arg2 = args[2]:lower()
			if player.target_index then
				local zone = tostring(windower.ffxi.get_info().zone)
				if not settings.mobs[zone] then settings.mobs[zone] = {} end
				settings.mobs[zone][arg2] = player.target_index
				settings:save()
				notice("Adding target index " .. player.target_index .. " to zone " .. zone .. " as " .. arg2)
			else
				notice("Error: Need target for add command")
			end
		else
			notice("Error: Need name for add command")
		end
	elseif command == 'remove' then
		if args[2] then
			if args[3] then
				if settings.mobs[args[2]] then
					local arg3 = args[3]:lower()
					if settings.mobs[args[2]][arg3] then
						settings.mobs[args[2]][arg3] = nil
						notice("Removing " .. arg3 .. " from settings for zone id " .. args[2])
						local count = 0
						for _,_ in pairs(settings.mobs[args[2]]) do
							count = count + 1
						end
						if count == 0 then
							settings.mobs[args[2]] = nil
							notice("Removing zone id " .. args[2] .. " from settings")
						end
						settings:save()
					else
						notice("Error: Entry " .. arg3 .. " not found in settings for zone id " .. args[2])
					end
				else
					notice("Error: Zone id " .. args[2] .. " not found in settings")
				end
			else
				notice("Error: Remove command needs a name for 3rd argument")
			end
		else
			notice("Error: Remove command needs a zone_id for 2nd argument")
		end
	elseif command == 'spawn' and args[2] then
		if args[2] then
			local zone = tostring(windower.ffxi.get_info().zone)
			if settings.mobs[zone] then
				local arg2 = args[2]:lower()
				if settings.mobs[zone][arg2] then
					local p = packets.new('outgoing', 0x016)
					p["Target Index"] = settings.mobs[zone][arg2]
					packets.inject(p)
				else
					notice("Error: No info for " .. arg2 .. " in zone " .. zone )
				end
			else
				notice("Error: No info for zone " .. zone)
			end
		else
			notice("Error: Spawn command needs a name for 2nd argument")
		end
	elseif command == 'showinfo' then
		local zone = tostring(windower.ffxi.get_info().zone)
		notice('Current zone is ' .. zone)
		for name, index in pairs(settings.mobs[zone]) do
			notice(name .. " = " .. index)
		end
	else
		help_command()
	end
end)

function get_distance(p1, p2)
	if p1 and p2 then
		return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2))
	else
		return 0
	end
end

function get_direction(p1, p2)
	if p1 and p2 then 
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
		end
	end
	return "??"
end

function update_text()
	local new_text = ""
	local player = windower.ffxi.get_mob_by_target('me')
	for k,v in pairs(targets) do
		new_text = new_text .. v.name .. " Distance: " .. string.format("%.2f",get_distance(player, v)) .. " (" .. get_direction(player,v) .. ")\n"
	end
	text_box:text(new_text)
end

windower.register_event("incoming chunk", function(id, data)
	if current_zone and current_target ~= "" then
		if id == 0x0E then
			local packet = packets.parse('incoming', data)
			local mob_index = packet["Index"]
			if settings.mobs[current_zone][current_target] == mob_index then
				local mobx = packet['X']
				local moby = packet['Y']
				notice("got mob x: "  .. string.format("%.2f", mobx) .. " y: " .. string.format("%.2f", moby))
				targets = {}
				targets[mob_index] = { x = mobx, y = moby, name = current_target }
				current_target = ""
				text_box:visible(true)
			end
		end
	end
end)

function zone_change(new, old)
	targets = nil
	current_target = ""
	current_zone = tostring(new)
	text_box:visible(false) 
end

function reset()
	zone_change("")
end

function on_load()
	current_zone = tostring(windower.ffxi.get_info().zone)
end

windower.register_event('zone change', zone_change)
windower.register_event('logout', reset)
windower.register_event('login', reset)
windower.register_event('load', on_load)

windower.register_event('prerender', function()
	if targets then 
		update_text()
	end
end)