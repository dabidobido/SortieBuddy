# Sortie Buddy

Use at your own risk!

# How to Use

Default settings has the following info for Sortie:
a = Abject Obdella
b = Biune Porxie
c = Cachaemic Bhoot
d = Demisang Deleterious
f = Diaphanous Bitzer #F
g = Diaphanous Bitzer #G
h = Diaphanous Bitzer #H

1. In Sortie, use //sortiebuddy ping command after you zone into a, b, c, d, f, g or h.

or 

1. Target something (e.g Mireu)
2. Use add command
3. Next time the target doesn't spawn in the zone that you used the add command, use spawn command to force spawn the target

# Commands

use //sortiebuddy or //srtb to send commands

## //sortiebuddy ping (name)

> Injects a target packet then shows distance and direction to target

## //sortiebuddy spawn (name)

> Injects a target packet only.

## //sortiebuddy add (name)

> Save a target in current zone to settings

## //sortiebuddy remove (zone_id, name)

> Remove a target in zone_id from settings

## //sortiebuddy showinfo

> Shows target info for current zone

# Known Issues

Injecting the target packet on certain targets might crash the game!!!

# Version History
1.1.1:
- Fix lua runtime error. Need to save keys as string, not number

1.1.0:
- Moved configuration to settings
- Added spawn, add, remove command.

1.0.2:
- Fix info not showing if loaded addon while in sortie
- Fix nil error when zoning out

1.0.1:
- Add shortcut //srtb
- Don't use name from packet, sometimes it's crap

1.0.0:
- First version