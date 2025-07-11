# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_rmpc_global_optspecs
	string join \n c/config= t/theme= a/address= p/password= partition= autocreate h/help
end

function __fish_rmpc_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_rmpc_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_rmpc_using_subcommand
	set -l cmd (__fish_rmpc_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c rmpc -n "__fish_rmpc_needs_command" -s c -l config -r -F
complete -c rmpc -n "__fish_rmpc_needs_command" -s t -l theme -r -F
complete -c rmpc -n "__fish_rmpc_needs_command" -s a -l address -d 'Override the address to connect to. Defaults to value in the config file' -r
complete -c rmpc -n "__fish_rmpc_needs_command" -s p -l password -d 'Override the MPD password' -r
complete -c rmpc -n "__fish_rmpc_needs_command" -l partition -d 'Partition to connect to at startup' -r
complete -c rmpc -n "__fish_rmpc_needs_command" -l autocreate -d 'Automatically create the partition if it does not exist. Requires partition to be set'
complete -c rmpc -n "__fish_rmpc_needs_command" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "addrandom"
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "config" -d 'Prints the default config. Can be used to bootstrap your config file'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "theme" -d 'Prints the default theme. Can be used to bootstrap your theme file'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "lyricsindex" -d 'Index the lyrics dir and display result, meant only for debugging purposes'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "update" -d 'Scan MPD\'s music directory for updates'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "rescan" -d 'Scan MPD\'s music directory for updates. Also rescans unmodified files'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "albumart" -d 'Saves the current album art to a file. Exit codes: * 0: Success * 1: Error * 2: No album art found * 3: No song playing'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "debuginfo" -d 'Prints information about optional runtime dependencies'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "version" -d 'Prints the rmpc version'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "play" -d 'Plays song at the position in the current playlist. Defaults to current paused song'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "pause" -d 'Pause playback'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "unpause" -d 'Unpause playback'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "togglepause" -d 'Toggles between play and pause'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "stop" -d 'Stops playback'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "next" -d 'Plays the next song in the playlist'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "prev" -d 'Plays the previous song in the playlist'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "volume" -d 'Sets volume, relative if prefixed by + or -. Prints current volume if no arguments is given'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "repeat" -d 'On or off'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "random" -d 'On or off'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "single" -d 'On, off or oneshot'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "consume" -d 'On, off or oneshot'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "togglerepeat" -d 'Toggles the repeat mode'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "togglerandom" -d 'Toggles the random mode'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "togglesingle" -d 'Toggles the single mode'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "toggleconsume" -d 'Toggles the consume mode'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "seek" -d 'Seeks current song(seconds), relative if prefixed by + or -'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "clear" -d 'Clear the current queue'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "add" -d 'Add a song to the current queue. Relative to music database root. \'/\' to add all files to the queue'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "addyt" -d 'Add a song from youtube to the current queue'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "outputs" -d 'List MPD outputs'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "toggleoutput" -d 'Toggle MPD output on or off'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "enableoutput" -d 'Enable MPD output'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "disableoutput" -d 'Disable MPD output'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "decoders" -d 'List MPD decoder plugins'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "status" -d 'Prints various information like the playback status'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "song" -d 'Prints info about the current song. If --path specified, prints information about the song at the given path instead. If --path is specified multiple times, prints an array containing all the songs'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "mount" -d 'Mounts supported storage to MPD'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "unmount" -d 'Unmounts storage with given name'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "listmounts" -d 'List currently mounted storages'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "listpartitions" -d 'List the currently existing partitions'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "sticker" -d 'Manipulate and query song stickers'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "remote" -d 'Send a remote command to running rmpc instance'
complete -c rmpc -n "__fish_rmpc_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand addrandom" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand config" -s c -l current -d 'If provided, print the current config instead of the default one'
complete -c rmpc -n "__fish_rmpc_using_subcommand config" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand theme" -s c -l current -d 'If provided, print the current theme instead of the default one'
complete -c rmpc -n "__fish_rmpc_using_subcommand theme" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand lyricsindex" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand update" -s w -l wait -d 'Rmpc will wait for the update job to finish before returning'
complete -c rmpc -n "__fish_rmpc_using_subcommand update" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand rescan" -s w -l wait -d 'Rmpc will wait for the update job to finish before returning'
complete -c rmpc -n "__fish_rmpc_using_subcommand rescan" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand albumart" -s o -l output -d 'Output file where to save the album art, "-" for stdout' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand albumart" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand debuginfo" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand version" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand play" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand pause" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand unpause" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand togglepause" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand stop" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand next" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand prev" -s r -l rewind-to-start -d 'Go back to the start of the song if more than 5 seconds elapsed' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand prev" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand volume" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand repeat" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rmpc -n "__fish_rmpc_using_subcommand random" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rmpc -n "__fish_rmpc_using_subcommand single" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rmpc -n "__fish_rmpc_using_subcommand consume" -s h -l help -d 'Print help (see more with \'--help\')'
complete -c rmpc -n "__fish_rmpc_using_subcommand togglerepeat" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand togglerandom" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand togglesingle" -s s -l skip-oneshot -d 'Skip the oneshot mode, i.e. toggle between on and off'
complete -c rmpc -n "__fish_rmpc_using_subcommand togglesingle" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand toggleconsume" -s s -l skip-oneshot -d 'Skip the oneshot mode, i.e. toggle between on and off'
complete -c rmpc -n "__fish_rmpc_using_subcommand toggleconsume" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand seek" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand clear" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand add" -s p -l position -d 'If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand add" -l skip-ext-check -d 'Rmpc checks whether MPD supports the added external file\'s extension and skips it if it does not. This option disables this behaviour and rmpc will try to add all the files'
complete -c rmpc -n "__fish_rmpc_using_subcommand add" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand addyt" -s p -l position -d 'If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand addyt" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand outputs" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand toggleoutput" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand enableoutput" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand disableoutput" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand decoders" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand status" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand song" -s p -l path -r
complete -c rmpc -n "__fish_rmpc_using_subcommand song" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand mount" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand unmount" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand listmounts" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand listpartitions" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "set" -d 'Set sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "get" -d 'Get sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "list" -d 'List all stickers of a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "find" -d 'Find all stickers of given name in  the specified directory'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "delete" -d 'Delete a sticker from a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "deleteall" -d 'Delete all stickers in a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and not __fish_seen_subcommand_from set get list find delete deleteall help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from set" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from get" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from list" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from find" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from delete" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from deleteall" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "set" -d 'Set sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "get" -d 'Get sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "list" -d 'List all stickers of a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "find" -d 'Find all stickers of given name in  the specified directory'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "delete" -d 'Delete a sticker from a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "deleteall" -d 'Delete all stickers in a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand sticker; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -l pid -d 'PID of the rmpc instance to send the remote command to. If not provided, rmpc will try to notify all the running instances' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -f -a "indexlrc" -d 'Notify rmpc that a new lyrics file has been added'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -f -a "status" -d 'Display a message in the status bar'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -f -a "tmux"
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -f -a "set" -d 'Sets a value in running rmpc instance'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and not __fish_seen_subcommand_from indexlrc status tmux set help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from indexlrc" -s p -l path -d 'Absolute path to the lrc file' -r -F
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from indexlrc" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from status" -s l -l level -d 'Controls the color of the message in the status bar' -r -f -a "info\t''
error\t''
warn\t''"
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from status" -s t -l timeout -d 'How long should the message be displayed for in milliseconds' -r
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from status" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from tmux" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from set" -s h -l help -d 'Print help'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from set" -f -a "config" -d 'Replaces config in a running rmpc instance with the provided one, theme is NOT replaced'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from set" -f -a "theme" -d 'Replaces theme in a running rmpc instance with the provided one'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from set" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from help" -f -a "indexlrc" -d 'Notify rmpc that a new lyrics file has been added'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from help" -f -a "status" -d 'Display a message in the status bar'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from help" -f -a "tmux"
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from help" -f -a "set" -d 'Sets a value in running rmpc instance'
complete -c rmpc -n "__fish_rmpc_using_subcommand remote; and __fish_seen_subcommand_from help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "addrandom"
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "config" -d 'Prints the default config. Can be used to bootstrap your config file'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "theme" -d 'Prints the default theme. Can be used to bootstrap your theme file'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "lyricsindex" -d 'Index the lyrics dir and display result, meant only for debugging purposes'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "update" -d 'Scan MPD\'s music directory for updates'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "rescan" -d 'Scan MPD\'s music directory for updates. Also rescans unmodified files'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "albumart" -d 'Saves the current album art to a file. Exit codes: * 0: Success * 1: Error * 2: No album art found * 3: No song playing'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "debuginfo" -d 'Prints information about optional runtime dependencies'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "version" -d 'Prints the rmpc version'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "play" -d 'Plays song at the position in the current playlist. Defaults to current paused song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "pause" -d 'Pause playback'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "unpause" -d 'Unpause playback'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "togglepause" -d 'Toggles between play and pause'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "stop" -d 'Stops playback'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "next" -d 'Plays the next song in the playlist'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "prev" -d 'Plays the previous song in the playlist'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "volume" -d 'Sets volume, relative if prefixed by + or -. Prints current volume if no arguments is given'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "repeat" -d 'On or off'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "random" -d 'On or off'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "single" -d 'On, off or oneshot'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "consume" -d 'On, off or oneshot'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "togglerepeat" -d 'Toggles the repeat mode'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "togglerandom" -d 'Toggles the random mode'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "togglesingle" -d 'Toggles the single mode'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "toggleconsume" -d 'Toggles the consume mode'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "seek" -d 'Seeks current song(seconds), relative if prefixed by + or -'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "clear" -d 'Clear the current queue'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "add" -d 'Add a song to the current queue. Relative to music database root. \'/\' to add all files to the queue'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "addyt" -d 'Add a song from youtube to the current queue'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "outputs" -d 'List MPD outputs'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "toggleoutput" -d 'Toggle MPD output on or off'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "enableoutput" -d 'Enable MPD output'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "disableoutput" -d 'Disable MPD output'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "decoders" -d 'List MPD decoder plugins'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "status" -d 'Prints various information like the playback status'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "song" -d 'Prints info about the current song. If --path specified, prints information about the song at the given path instead. If --path is specified multiple times, prints an array containing all the songs'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "mount" -d 'Mounts supported storage to MPD'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "unmount" -d 'Unmounts storage with given name'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "listmounts" -d 'List currently mounted storages'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "listpartitions" -d 'List the currently existing partitions'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "sticker" -d 'Manipulate and query song stickers'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "remote" -d 'Send a remote command to running rmpc instance'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and not __fish_seen_subcommand_from addrandom config theme lyricsindex update rescan albumart debuginfo version play pause unpause togglepause stop next prev volume repeat random single consume togglerepeat togglerandom togglesingle toggleconsume seek clear add addyt outputs toggleoutput enableoutput disableoutput decoders status song mount unmount listmounts listpartitions sticker remote help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "set" -d 'Set sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "get" -d 'Get sticker value for a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "list" -d 'List all stickers of a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "find" -d 'Find all stickers of given name in  the specified directory'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "delete" -d 'Delete a sticker from a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from sticker" -f -a "deleteall" -d 'Delete all stickers in a song'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from remote" -f -a "indexlrc" -d 'Notify rmpc that a new lyrics file has been added'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from remote" -f -a "status" -d 'Display a message in the status bar'
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from remote" -f -a "tmux"
complete -c rmpc -n "__fish_rmpc_using_subcommand help; and __fish_seen_subcommand_from remote" -f -a "set" -d 'Sets a value in running rmpc instance'
