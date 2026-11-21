use framework "Foundation"
use framework "AppKit"
use scripting additions

property statusItem : missing value
property clicks : 0

on run
	set statusItem to current application's NSStatusBar's systemStatusBar()'s statusItemWithLength:(current application's NSVariableStatusItemLength)
	set m to current application's NSMenu's alloc()'s init()
	set qi to m's addItemWithTitle:"Quit Muse AutoAllow" action:"quitApp:" keyEquivalent:""
	qi's setTarget:me
	statusItem's setMenu:m
	my refresh()
end run

on refresh()
	statusItem's button()'s setTitle:("M✓ " & clicks)
end refresh

on quitApp:sender
	quit
end quitApp:

on idle
	try
		tell application "System Events" to tell process "Muse"
			repeat with w in windows
				set els to entire contents of w
				set isUpload to false
				repeat with e in els
					try
						if role of e is "AXStaticText" and ((value of e as text) contains "to upload this file") then set isUpload to true
					end try
				end repeat
				if isUpload then
					repeat with e in els
						try
							if role of e is "AXButton" and ((name of e as text) is "Allow once" or (description of e as text) is "Allow once") then
								click e
								set clicks to clicks + 1
								exit repeat
							end if
						end try
					end repeat
				end if
			end repeat
		end tell
	end try
	my refresh()
	return 2
end idle
