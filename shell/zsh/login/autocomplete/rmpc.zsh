#compdef rmpc

autoload -U is-at-least

_rmpc() {
    typeset -A opt_args
    typeset -a _arguments_options
    local ret=1

    if is-at-least 5.2; then
        _arguments_options=(-s -S -C)
    else
        _arguments_options=(-s -C)
    fi

    local context curcontext="$curcontext" state line
    _arguments "${_arguments_options[@]}" : \
'-c+[]:FILE:_files' \
'--config=[]:FILE:_files' \
'-t+[]:FILE:_files' \
'--theme=[]:FILE:_files' \
'-a+[Override the address to connect to. Defaults to value in the config file]:ADDRESS:_default' \
'--address=[Override the address to connect to. Defaults to value in the config file]:ADDRESS:_default' \
'-p+[Override the MPD password]:PASSWORD:_default' \
'--password=[Override the MPD password]:PASSWORD:_default' \
'--partition=[Partition to connect to at startup]:PARTITION:_default' \
'--autocreate[Automatically create the partition if it does not exist. Requires partition to be set]' \
'-h[Print help]' \
'--help[Print help]' \
":: :_rmpc_commands" \
"*::: :->rmpc" \
&& ret=0
    case $state in
    (rmpc)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-command-$line[1]:"
        case $line[1] in
            (addrandom)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':tag:(song artist album albumartist genre)' \
':count:_default' \
&& ret=0
;;
(config)
_arguments "${_arguments_options[@]}" : \
'-c[If provided, print the current config instead of the default one]' \
'--current[If provided, print the current config instead of the default one]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
'-c[If provided, print the current theme instead of the default one]' \
'--current[If provided, print the current theme instead of the default one]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(lyricsindex)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(update)
_arguments "${_arguments_options[@]}" : \
'-w[Rmpc will wait for the update job to finish before returning]' \
'--wait[Rmpc will wait for the update job to finish before returning]' \
'-h[Print help]' \
'--help[Print help]' \
'::path -- If supplied, MPD will update only the provided directory/file. If not specified, everything is updated:_default' \
&& ret=0
;;
(rescan)
_arguments "${_arguments_options[@]}" : \
'-w[Rmpc will wait for the update job to finish before returning]' \
'--wait[Rmpc will wait for the update job to finish before returning]' \
'-h[Print help]' \
'--help[Print help]' \
'::path -- If supplied, MPD will update only the provided directory/file. If not specified, everything is updated:_default' \
&& ret=0
;;
(albumart)
_arguments "${_arguments_options[@]}" : \
'-o+[Output file where to save the album art, "-" for stdout]:OUTPUT:_default' \
'--output=[Output file where to save the album art, "-" for stdout]:OUTPUT:_default' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(debuginfo)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(version)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(play)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
'::position -- Index of the song in the queue:_default' \
&& ret=0
;;
(pause)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(unpause)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(togglepause)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(stop)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(next)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(prev)
_arguments "${_arguments_options[@]}" : \
'-r+[Go back to the start of the song if more than 5 seconds elapsed]' \
'--rewind-to-start=[Go back to the start of the song if more than 5 seconds elapsed]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(volume)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
'::value:_default' \
&& ret=0
;;
(repeat)
_arguments "${_arguments_options[@]}" : \
'-h[Print help (see more with '\''--help'\'')]' \
'--help[Print help (see more with '\''--help'\'')]' \
':value:((on\:"Enable"
off\:"Disable"))' \
&& ret=0
;;
(random)
_arguments "${_arguments_options[@]}" : \
'-h[Print help (see more with '\''--help'\'')]' \
'--help[Print help (see more with '\''--help'\'')]' \
':value:((on\:"Enable"
off\:"Disable"))' \
&& ret=0
;;
(single)
_arguments "${_arguments_options[@]}" : \
'-h[Print help (see more with '\''--help'\'')]' \
'--help[Print help (see more with '\''--help'\'')]' \
':value:((on\:"Enable"
off\:"Disable"
oneshot\:"Track get removed from playlist after it has been played"))' \
&& ret=0
;;
(consume)
_arguments "${_arguments_options[@]}" : \
'-h[Print help (see more with '\''--help'\'')]' \
'--help[Print help (see more with '\''--help'\'')]' \
':value:((on\:"Enable"
off\:"Disable"
oneshot\:"Track get removed from playlist after it has been played"))' \
&& ret=0
;;
(togglerepeat)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(togglerandom)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(togglesingle)
_arguments "${_arguments_options[@]}" : \
'-s[Skip the oneshot mode, i.e. toggle between on and off]' \
'--skip-oneshot[Skip the oneshot mode, i.e. toggle between on and off]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(toggleconsume)
_arguments "${_arguments_options[@]}" : \
'-s[Skip the oneshot mode, i.e. toggle between on and off]' \
'--skip-oneshot[Skip the oneshot mode, i.e. toggle between on and off]' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(seek)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':value:_default' \
&& ret=0
;;
(clear)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(add)
_arguments "${_arguments_options[@]}" : \
'-p+[If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)]:POSITION:_default' \
'--position=[If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)]:POSITION:_default' \
'--skip-ext-check[Rmpc checks whether MPD supports the added external file'\''s extension and skips it if it does not. This option disables this behaviour and rmpc will try to add all the files]' \
'-h[Print help]' \
'--help[Print help]' \
'*::files -- Files to add to MPD'\''s queue:_files' \
&& ret=0
;;
(addyt)
_arguments "${_arguments_options[@]}" : \
'-p+[If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)]:POSITION:_default' \
'--position=[If provided, queue the new item at this position instead of the end of the queue. Allowed positions are <number> (absolute) and +<number> or -<number> (relative)]:POSITION:_default' \
'-h[Print help]' \
'--help[Print help]' \
':url:_default' \
&& ret=0
;;
(outputs)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(toggleoutput)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':id:_default' \
&& ret=0
;;
(enableoutput)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':id:_default' \
&& ret=0
;;
(disableoutput)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':id:_default' \
&& ret=0
;;
(decoders)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(status)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(song)
_arguments "${_arguments_options[@]}" : \
'*-p+[]:PATH:_default' \
'*--path=[]:PATH:_default' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(mount)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':name:_default' \
':path:_default' \
&& ret=0
;;
(unmount)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':name:_default' \
&& ret=0
;;
(listmounts)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(listpartitions)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(sticker)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
":: :_rmpc__sticker_commands" \
"*::: :->sticker" \
&& ret=0

    case $state in
    (sticker)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-sticker-command-$line[1]:"
        case $line[1] in
            (set)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a song, relative to music directory root:_default' \
':key -- Sticker key to set:_default' \
':value -- Sticker value that will be written:_default' \
&& ret=0
;;
(get)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a song, relative to music directory root:_default' \
':key -- Sticker key to get:_default' \
&& ret=0
;;
(list)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a song, relative to music directory root:_default' \
&& ret=0
;;
(find)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a directory, relative to music directory root:_default' \
':key -- Sticker key to search for:_default' \
&& ret=0
;;
(delete)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a song, relative to music directory root:_default' \
':key -- Sticker key to search delete:_default' \
&& ret=0
;;
(deleteall)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':uri -- Path to a song, relative to music directory root:_default' \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__sticker__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-sticker-help-command-$line[1]:"
        case $line[1] in
            (set)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(get)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(list)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(find)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(delete)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(deleteall)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
;;
(remote)
_arguments "${_arguments_options[@]}" : \
'--pid=[PID of the rmpc instance to send the remote command to. If not provided, rmpc will try to notify all the running instances]:PID:_default' \
'-h[Print help]' \
'--help[Print help]' \
":: :_rmpc__remote_commands" \
"*::: :->remote" \
&& ret=0

    case $state in
    (remote)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-remote-command-$line[1]:"
        case $line[1] in
            (indexlrc)
_arguments "${_arguments_options[@]}" : \
'-p+[Absolute path to the lrc file]:PATH:_files' \
'--path=[Absolute path to the lrc file]:PATH:_files' \
'-h[Print help]' \
'--help[Print help]' \
&& ret=0
;;
(status)
_arguments "${_arguments_options[@]}" : \
'-l+[Controls the color of the message in the status bar]:LEVEL:(info error warn)' \
'--level=[Controls the color of the message in the status bar]:LEVEL:(info error warn)' \
'-t+[How long should the message be displayed for in milliseconds]:TIMEOUT:_default' \
'--timeout=[How long should the message be displayed for in milliseconds]:TIMEOUT:_default' \
'-h[Print help]' \
'--help[Print help]' \
':message -- Message to display in the status bar:_default' \
&& ret=0
;;
(tmux)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':hook:_default' \
&& ret=0
;;
(set)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
":: :_rmpc__remote__set_commands" \
"*::: :->set" \
&& ret=0

    case $state in
    (set)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-remote-set-command-$line[1]:"
        case $line[1] in
            (config)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':path -- Value to set the path to. Can be either path to a file or "-" to read from stdin:_files' \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
'-h[Print help]' \
'--help[Print help]' \
':path -- Value to set the path to. Can be either path to a file or "-" to read from stdin:_files' \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__remote__set__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-remote-set-help-command-$line[1]:"
        case $line[1] in
            (config)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(help)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
;;
(help)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__remote__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-remote-help-command-$line[1]:"
        case $line[1] in
            (indexlrc)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(status)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(tmux)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(set)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__remote__help__set_commands" \
"*::: :->set" \
&& ret=0

    case $state in
    (set)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-remote-help-set-command-$line[1]:"
        case $line[1] in
            (config)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
(help)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
;;
(help)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__help_commands" \
"*::: :->help" \
&& ret=0

    case $state in
    (help)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-help-command-$line[1]:"
        case $line[1] in
            (addrandom)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(config)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(lyricsindex)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(update)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(rescan)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(albumart)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(debuginfo)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(version)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(play)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(pause)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(unpause)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(togglepause)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(stop)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(next)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(prev)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(volume)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(repeat)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(random)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(single)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(consume)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(togglerepeat)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(togglerandom)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(togglesingle)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(toggleconsume)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(seek)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(clear)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(add)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(addyt)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(outputs)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(toggleoutput)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(enableoutput)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(disableoutput)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(decoders)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(status)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(song)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(mount)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(unmount)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(listmounts)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(listpartitions)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(sticker)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__help__sticker_commands" \
"*::: :->sticker" \
&& ret=0

    case $state in
    (sticker)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-help-sticker-command-$line[1]:"
        case $line[1] in
            (set)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(get)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(list)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(find)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(delete)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(deleteall)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
(remote)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__help__remote_commands" \
"*::: :->remote" \
&& ret=0

    case $state in
    (remote)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-help-remote-command-$line[1]:"
        case $line[1] in
            (indexlrc)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(status)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(tmux)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(set)
_arguments "${_arguments_options[@]}" : \
":: :_rmpc__help__remote__set_commands" \
"*::: :->set" \
&& ret=0

    case $state in
    (set)
        words=($line[1] "${words[@]}")
        (( CURRENT += 1 ))
        curcontext="${curcontext%:*:*}:rmpc-help-remote-set-command-$line[1]:"
        case $line[1] in
            (config)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
(theme)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
;;
(help)
_arguments "${_arguments_options[@]}" : \
&& ret=0
;;
        esac
    ;;
esac
;;
        esac
    ;;
esac
}

(( $+functions[_rmpc_commands] )) ||
_rmpc_commands() {
    local commands; commands=(
'addrandom:' \
'config:Prints the default config. Can be used to bootstrap your config file' \
'theme:Prints the default theme. Can be used to bootstrap your theme file' \
'lyricsindex:Index the lyrics dir and display result, meant only for debugging purposes' \
'update:Scan MPD'\''s music directory for updates' \
'rescan:Scan MPD'\''s music directory for updates. Also rescans unmodified files' \
'albumart:Saves the current album art to a file. Exit codes\: * 0\: Success * 1\: Error * 2\: No album art found * 3\: No song playing' \
'debuginfo:Prints information about optional runtime dependencies' \
'version:Prints the rmpc version' \
'play:Plays song at the position in the current playlist. Defaults to current paused song' \
'pause:Pause playback' \
'unpause:Unpause playback' \
'togglepause:Toggles between play and pause' \
'stop:Stops playback' \
'next:Plays the next song in the playlist' \
'prev:Plays the previous song in the playlist' \
'volume:Sets volume, relative if prefixed by + or -. Prints current volume if no arguments is given' \
'repeat:On or off' \
'random:On or off' \
'single:On, off or oneshot' \
'consume:On, off or oneshot' \
'togglerepeat:Toggles the repeat mode' \
'togglerandom:Toggles the random mode' \
'togglesingle:Toggles the single mode' \
'toggleconsume:Toggles the consume mode' \
'seek:Seeks current song(seconds), relative if prefixed by + or -' \
'clear:Clear the current queue' \
'add:Add a song to the current queue. Relative to music database root. '\''/'\'' to add all files to the queue' \
'addyt:Add a song from youtube to the current queue' \
'outputs:List MPD outputs' \
'toggleoutput:Toggle MPD output on or off' \
'enableoutput:Enable MPD output' \
'disableoutput:Disable MPD output' \
'decoders:List MPD decoder plugins' \
'status:Prints various information like the playback status' \
'song:Prints info about the current song. If --path specified, prints information about the song at the given path instead. If --path is specified multiple times, prints an array containing all the songs' \
'mount:Mounts supported storage to MPD' \
'unmount:Unmounts storage with given name' \
'listmounts:List currently mounted storages' \
'listpartitions:List the currently existing partitions' \
'sticker:Manipulate and query song stickers' \
'remote:Send a remote command to running rmpc instance' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc commands' commands "$@"
}
(( $+functions[_rmpc__add_commands] )) ||
_rmpc__add_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc add commands' commands "$@"
}
(( $+functions[_rmpc__addrandom_commands] )) ||
_rmpc__addrandom_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc addrandom commands' commands "$@"
}
(( $+functions[_rmpc__addyt_commands] )) ||
_rmpc__addyt_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc addyt commands' commands "$@"
}
(( $+functions[_rmpc__albumart_commands] )) ||
_rmpc__albumart_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc albumart commands' commands "$@"
}
(( $+functions[_rmpc__clear_commands] )) ||
_rmpc__clear_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc clear commands' commands "$@"
}
(( $+functions[_rmpc__config_commands] )) ||
_rmpc__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc config commands' commands "$@"
}
(( $+functions[_rmpc__consume_commands] )) ||
_rmpc__consume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc consume commands' commands "$@"
}
(( $+functions[_rmpc__debuginfo_commands] )) ||
_rmpc__debuginfo_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc debuginfo commands' commands "$@"
}
(( $+functions[_rmpc__decoders_commands] )) ||
_rmpc__decoders_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc decoders commands' commands "$@"
}
(( $+functions[_rmpc__disableoutput_commands] )) ||
_rmpc__disableoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc disableoutput commands' commands "$@"
}
(( $+functions[_rmpc__enableoutput_commands] )) ||
_rmpc__enableoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc enableoutput commands' commands "$@"
}
(( $+functions[_rmpc__help_commands] )) ||
_rmpc__help_commands() {
    local commands; commands=(
'addrandom:' \
'config:Prints the default config. Can be used to bootstrap your config file' \
'theme:Prints the default theme. Can be used to bootstrap your theme file' \
'lyricsindex:Index the lyrics dir and display result, meant only for debugging purposes' \
'update:Scan MPD'\''s music directory for updates' \
'rescan:Scan MPD'\''s music directory for updates. Also rescans unmodified files' \
'albumart:Saves the current album art to a file. Exit codes\: * 0\: Success * 1\: Error * 2\: No album art found * 3\: No song playing' \
'debuginfo:Prints information about optional runtime dependencies' \
'version:Prints the rmpc version' \
'play:Plays song at the position in the current playlist. Defaults to current paused song' \
'pause:Pause playback' \
'unpause:Unpause playback' \
'togglepause:Toggles between play and pause' \
'stop:Stops playback' \
'next:Plays the next song in the playlist' \
'prev:Plays the previous song in the playlist' \
'volume:Sets volume, relative if prefixed by + or -. Prints current volume if no arguments is given' \
'repeat:On or off' \
'random:On or off' \
'single:On, off or oneshot' \
'consume:On, off or oneshot' \
'togglerepeat:Toggles the repeat mode' \
'togglerandom:Toggles the random mode' \
'togglesingle:Toggles the single mode' \
'toggleconsume:Toggles the consume mode' \
'seek:Seeks current song(seconds), relative if prefixed by + or -' \
'clear:Clear the current queue' \
'add:Add a song to the current queue. Relative to music database root. '\''/'\'' to add all files to the queue' \
'addyt:Add a song from youtube to the current queue' \
'outputs:List MPD outputs' \
'toggleoutput:Toggle MPD output on or off' \
'enableoutput:Enable MPD output' \
'disableoutput:Disable MPD output' \
'decoders:List MPD decoder plugins' \
'status:Prints various information like the playback status' \
'song:Prints info about the current song. If --path specified, prints information about the song at the given path instead. If --path is specified multiple times, prints an array containing all the songs' \
'mount:Mounts supported storage to MPD' \
'unmount:Unmounts storage with given name' \
'listmounts:List currently mounted storages' \
'listpartitions:List the currently existing partitions' \
'sticker:Manipulate and query song stickers' \
'remote:Send a remote command to running rmpc instance' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc help commands' commands "$@"
}
(( $+functions[_rmpc__help__add_commands] )) ||
_rmpc__help__add_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help add commands' commands "$@"
}
(( $+functions[_rmpc__help__addrandom_commands] )) ||
_rmpc__help__addrandom_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help addrandom commands' commands "$@"
}
(( $+functions[_rmpc__help__addyt_commands] )) ||
_rmpc__help__addyt_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help addyt commands' commands "$@"
}
(( $+functions[_rmpc__help__albumart_commands] )) ||
_rmpc__help__albumart_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help albumart commands' commands "$@"
}
(( $+functions[_rmpc__help__clear_commands] )) ||
_rmpc__help__clear_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help clear commands' commands "$@"
}
(( $+functions[_rmpc__help__config_commands] )) ||
_rmpc__help__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help config commands' commands "$@"
}
(( $+functions[_rmpc__help__consume_commands] )) ||
_rmpc__help__consume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help consume commands' commands "$@"
}
(( $+functions[_rmpc__help__debuginfo_commands] )) ||
_rmpc__help__debuginfo_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help debuginfo commands' commands "$@"
}
(( $+functions[_rmpc__help__decoders_commands] )) ||
_rmpc__help__decoders_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help decoders commands' commands "$@"
}
(( $+functions[_rmpc__help__disableoutput_commands] )) ||
_rmpc__help__disableoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help disableoutput commands' commands "$@"
}
(( $+functions[_rmpc__help__enableoutput_commands] )) ||
_rmpc__help__enableoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help enableoutput commands' commands "$@"
}
(( $+functions[_rmpc__help__help_commands] )) ||
_rmpc__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help help commands' commands "$@"
}
(( $+functions[_rmpc__help__listmounts_commands] )) ||
_rmpc__help__listmounts_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help listmounts commands' commands "$@"
}
(( $+functions[_rmpc__help__listpartitions_commands] )) ||
_rmpc__help__listpartitions_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help listpartitions commands' commands "$@"
}
(( $+functions[_rmpc__help__lyricsindex_commands] )) ||
_rmpc__help__lyricsindex_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help lyricsindex commands' commands "$@"
}
(( $+functions[_rmpc__help__mount_commands] )) ||
_rmpc__help__mount_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help mount commands' commands "$@"
}
(( $+functions[_rmpc__help__next_commands] )) ||
_rmpc__help__next_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help next commands' commands "$@"
}
(( $+functions[_rmpc__help__outputs_commands] )) ||
_rmpc__help__outputs_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help outputs commands' commands "$@"
}
(( $+functions[_rmpc__help__pause_commands] )) ||
_rmpc__help__pause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help pause commands' commands "$@"
}
(( $+functions[_rmpc__help__play_commands] )) ||
_rmpc__help__play_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help play commands' commands "$@"
}
(( $+functions[_rmpc__help__prev_commands] )) ||
_rmpc__help__prev_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help prev commands' commands "$@"
}
(( $+functions[_rmpc__help__random_commands] )) ||
_rmpc__help__random_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help random commands' commands "$@"
}
(( $+functions[_rmpc__help__remote_commands] )) ||
_rmpc__help__remote_commands() {
    local commands; commands=(
'indexlrc:Notify rmpc that a new lyrics file has been added' \
'status:Display a message in the status bar' \
'tmux:' \
'set:Sets a value in running rmpc instance' \
    )
    _describe -t commands 'rmpc help remote commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__indexlrc_commands] )) ||
_rmpc__help__remote__indexlrc_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help remote indexlrc commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__set_commands] )) ||
_rmpc__help__remote__set_commands() {
    local commands; commands=(
'config:Replaces config in a running rmpc instance with the provided one, theme is NOT replaced' \
'theme:Replaces theme in a running rmpc instance with the provided one' \
    )
    _describe -t commands 'rmpc help remote set commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__set__config_commands] )) ||
_rmpc__help__remote__set__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help remote set config commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__set__theme_commands] )) ||
_rmpc__help__remote__set__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help remote set theme commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__status_commands] )) ||
_rmpc__help__remote__status_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help remote status commands' commands "$@"
}
(( $+functions[_rmpc__help__remote__tmux_commands] )) ||
_rmpc__help__remote__tmux_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help remote tmux commands' commands "$@"
}
(( $+functions[_rmpc__help__repeat_commands] )) ||
_rmpc__help__repeat_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help repeat commands' commands "$@"
}
(( $+functions[_rmpc__help__rescan_commands] )) ||
_rmpc__help__rescan_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help rescan commands' commands "$@"
}
(( $+functions[_rmpc__help__seek_commands] )) ||
_rmpc__help__seek_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help seek commands' commands "$@"
}
(( $+functions[_rmpc__help__single_commands] )) ||
_rmpc__help__single_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help single commands' commands "$@"
}
(( $+functions[_rmpc__help__song_commands] )) ||
_rmpc__help__song_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help song commands' commands "$@"
}
(( $+functions[_rmpc__help__status_commands] )) ||
_rmpc__help__status_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help status commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker_commands] )) ||
_rmpc__help__sticker_commands() {
    local commands; commands=(
'set:Set sticker value for a song' \
'get:Get sticker value for a song' \
'list:List all stickers of a song' \
'find:Find all stickers of given name in  the specified directory' \
'delete:Delete a sticker from a song' \
'deleteall:Delete all stickers in a song' \
    )
    _describe -t commands 'rmpc help sticker commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__delete_commands] )) ||
_rmpc__help__sticker__delete_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker delete commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__deleteall_commands] )) ||
_rmpc__help__sticker__deleteall_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker deleteall commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__find_commands] )) ||
_rmpc__help__sticker__find_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker find commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__get_commands] )) ||
_rmpc__help__sticker__get_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker get commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__list_commands] )) ||
_rmpc__help__sticker__list_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker list commands' commands "$@"
}
(( $+functions[_rmpc__help__sticker__set_commands] )) ||
_rmpc__help__sticker__set_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help sticker set commands' commands "$@"
}
(( $+functions[_rmpc__help__stop_commands] )) ||
_rmpc__help__stop_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help stop commands' commands "$@"
}
(( $+functions[_rmpc__help__theme_commands] )) ||
_rmpc__help__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help theme commands' commands "$@"
}
(( $+functions[_rmpc__help__toggleconsume_commands] )) ||
_rmpc__help__toggleconsume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help toggleconsume commands' commands "$@"
}
(( $+functions[_rmpc__help__toggleoutput_commands] )) ||
_rmpc__help__toggleoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help toggleoutput commands' commands "$@"
}
(( $+functions[_rmpc__help__togglepause_commands] )) ||
_rmpc__help__togglepause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help togglepause commands' commands "$@"
}
(( $+functions[_rmpc__help__togglerandom_commands] )) ||
_rmpc__help__togglerandom_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help togglerandom commands' commands "$@"
}
(( $+functions[_rmpc__help__togglerepeat_commands] )) ||
_rmpc__help__togglerepeat_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help togglerepeat commands' commands "$@"
}
(( $+functions[_rmpc__help__togglesingle_commands] )) ||
_rmpc__help__togglesingle_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help togglesingle commands' commands "$@"
}
(( $+functions[_rmpc__help__unmount_commands] )) ||
_rmpc__help__unmount_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help unmount commands' commands "$@"
}
(( $+functions[_rmpc__help__unpause_commands] )) ||
_rmpc__help__unpause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help unpause commands' commands "$@"
}
(( $+functions[_rmpc__help__update_commands] )) ||
_rmpc__help__update_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help update commands' commands "$@"
}
(( $+functions[_rmpc__help__version_commands] )) ||
_rmpc__help__version_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help version commands' commands "$@"
}
(( $+functions[_rmpc__help__volume_commands] )) ||
_rmpc__help__volume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc help volume commands' commands "$@"
}
(( $+functions[_rmpc__listmounts_commands] )) ||
_rmpc__listmounts_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc listmounts commands' commands "$@"
}
(( $+functions[_rmpc__listpartitions_commands] )) ||
_rmpc__listpartitions_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc listpartitions commands' commands "$@"
}
(( $+functions[_rmpc__lyricsindex_commands] )) ||
_rmpc__lyricsindex_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc lyricsindex commands' commands "$@"
}
(( $+functions[_rmpc__mount_commands] )) ||
_rmpc__mount_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc mount commands' commands "$@"
}
(( $+functions[_rmpc__next_commands] )) ||
_rmpc__next_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc next commands' commands "$@"
}
(( $+functions[_rmpc__outputs_commands] )) ||
_rmpc__outputs_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc outputs commands' commands "$@"
}
(( $+functions[_rmpc__pause_commands] )) ||
_rmpc__pause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc pause commands' commands "$@"
}
(( $+functions[_rmpc__play_commands] )) ||
_rmpc__play_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc play commands' commands "$@"
}
(( $+functions[_rmpc__prev_commands] )) ||
_rmpc__prev_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc prev commands' commands "$@"
}
(( $+functions[_rmpc__random_commands] )) ||
_rmpc__random_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc random commands' commands "$@"
}
(( $+functions[_rmpc__remote_commands] )) ||
_rmpc__remote_commands() {
    local commands; commands=(
'indexlrc:Notify rmpc that a new lyrics file has been added' \
'status:Display a message in the status bar' \
'tmux:' \
'set:Sets a value in running rmpc instance' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc remote commands' commands "$@"
}
(( $+functions[_rmpc__remote__help_commands] )) ||
_rmpc__remote__help_commands() {
    local commands; commands=(
'indexlrc:Notify rmpc that a new lyrics file has been added' \
'status:Display a message in the status bar' \
'tmux:' \
'set:Sets a value in running rmpc instance' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc remote help commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__help_commands] )) ||
_rmpc__remote__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help help commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__indexlrc_commands] )) ||
_rmpc__remote__help__indexlrc_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help indexlrc commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__set_commands] )) ||
_rmpc__remote__help__set_commands() {
    local commands; commands=(
'config:Replaces config in a running rmpc instance with the provided one, theme is NOT replaced' \
'theme:Replaces theme in a running rmpc instance with the provided one' \
    )
    _describe -t commands 'rmpc remote help set commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__set__config_commands] )) ||
_rmpc__remote__help__set__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help set config commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__set__theme_commands] )) ||
_rmpc__remote__help__set__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help set theme commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__status_commands] )) ||
_rmpc__remote__help__status_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help status commands' commands "$@"
}
(( $+functions[_rmpc__remote__help__tmux_commands] )) ||
_rmpc__remote__help__tmux_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote help tmux commands' commands "$@"
}
(( $+functions[_rmpc__remote__indexlrc_commands] )) ||
_rmpc__remote__indexlrc_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote indexlrc commands' commands "$@"
}
(( $+functions[_rmpc__remote__set_commands] )) ||
_rmpc__remote__set_commands() {
    local commands; commands=(
'config:Replaces config in a running rmpc instance with the provided one, theme is NOT replaced' \
'theme:Replaces theme in a running rmpc instance with the provided one' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc remote set commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__config_commands] )) ||
_rmpc__remote__set__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote set config commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__help_commands] )) ||
_rmpc__remote__set__help_commands() {
    local commands; commands=(
'config:Replaces config in a running rmpc instance with the provided one, theme is NOT replaced' \
'theme:Replaces theme in a running rmpc instance with the provided one' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc remote set help commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__help__config_commands] )) ||
_rmpc__remote__set__help__config_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote set help config commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__help__help_commands] )) ||
_rmpc__remote__set__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote set help help commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__help__theme_commands] )) ||
_rmpc__remote__set__help__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote set help theme commands' commands "$@"
}
(( $+functions[_rmpc__remote__set__theme_commands] )) ||
_rmpc__remote__set__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote set theme commands' commands "$@"
}
(( $+functions[_rmpc__remote__status_commands] )) ||
_rmpc__remote__status_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote status commands' commands "$@"
}
(( $+functions[_rmpc__remote__tmux_commands] )) ||
_rmpc__remote__tmux_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc remote tmux commands' commands "$@"
}
(( $+functions[_rmpc__repeat_commands] )) ||
_rmpc__repeat_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc repeat commands' commands "$@"
}
(( $+functions[_rmpc__rescan_commands] )) ||
_rmpc__rescan_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc rescan commands' commands "$@"
}
(( $+functions[_rmpc__seek_commands] )) ||
_rmpc__seek_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc seek commands' commands "$@"
}
(( $+functions[_rmpc__single_commands] )) ||
_rmpc__single_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc single commands' commands "$@"
}
(( $+functions[_rmpc__song_commands] )) ||
_rmpc__song_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc song commands' commands "$@"
}
(( $+functions[_rmpc__status_commands] )) ||
_rmpc__status_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc status commands' commands "$@"
}
(( $+functions[_rmpc__sticker_commands] )) ||
_rmpc__sticker_commands() {
    local commands; commands=(
'set:Set sticker value for a song' \
'get:Get sticker value for a song' \
'list:List all stickers of a song' \
'find:Find all stickers of given name in  the specified directory' \
'delete:Delete a sticker from a song' \
'deleteall:Delete all stickers in a song' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc sticker commands' commands "$@"
}
(( $+functions[_rmpc__sticker__delete_commands] )) ||
_rmpc__sticker__delete_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker delete commands' commands "$@"
}
(( $+functions[_rmpc__sticker__deleteall_commands] )) ||
_rmpc__sticker__deleteall_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker deleteall commands' commands "$@"
}
(( $+functions[_rmpc__sticker__find_commands] )) ||
_rmpc__sticker__find_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker find commands' commands "$@"
}
(( $+functions[_rmpc__sticker__get_commands] )) ||
_rmpc__sticker__get_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker get commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help_commands] )) ||
_rmpc__sticker__help_commands() {
    local commands; commands=(
'set:Set sticker value for a song' \
'get:Get sticker value for a song' \
'list:List all stickers of a song' \
'find:Find all stickers of given name in  the specified directory' \
'delete:Delete a sticker from a song' \
'deleteall:Delete all stickers in a song' \
'help:Print this message or the help of the given subcommand(s)' \
    )
    _describe -t commands 'rmpc sticker help commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__delete_commands] )) ||
_rmpc__sticker__help__delete_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help delete commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__deleteall_commands] )) ||
_rmpc__sticker__help__deleteall_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help deleteall commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__find_commands] )) ||
_rmpc__sticker__help__find_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help find commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__get_commands] )) ||
_rmpc__sticker__help__get_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help get commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__help_commands] )) ||
_rmpc__sticker__help__help_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help help commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__list_commands] )) ||
_rmpc__sticker__help__list_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help list commands' commands "$@"
}
(( $+functions[_rmpc__sticker__help__set_commands] )) ||
_rmpc__sticker__help__set_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker help set commands' commands "$@"
}
(( $+functions[_rmpc__sticker__list_commands] )) ||
_rmpc__sticker__list_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker list commands' commands "$@"
}
(( $+functions[_rmpc__sticker__set_commands] )) ||
_rmpc__sticker__set_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc sticker set commands' commands "$@"
}
(( $+functions[_rmpc__stop_commands] )) ||
_rmpc__stop_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc stop commands' commands "$@"
}
(( $+functions[_rmpc__theme_commands] )) ||
_rmpc__theme_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc theme commands' commands "$@"
}
(( $+functions[_rmpc__toggleconsume_commands] )) ||
_rmpc__toggleconsume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc toggleconsume commands' commands "$@"
}
(( $+functions[_rmpc__toggleoutput_commands] )) ||
_rmpc__toggleoutput_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc toggleoutput commands' commands "$@"
}
(( $+functions[_rmpc__togglepause_commands] )) ||
_rmpc__togglepause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc togglepause commands' commands "$@"
}
(( $+functions[_rmpc__togglerandom_commands] )) ||
_rmpc__togglerandom_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc togglerandom commands' commands "$@"
}
(( $+functions[_rmpc__togglerepeat_commands] )) ||
_rmpc__togglerepeat_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc togglerepeat commands' commands "$@"
}
(( $+functions[_rmpc__togglesingle_commands] )) ||
_rmpc__togglesingle_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc togglesingle commands' commands "$@"
}
(( $+functions[_rmpc__unmount_commands] )) ||
_rmpc__unmount_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc unmount commands' commands "$@"
}
(( $+functions[_rmpc__unpause_commands] )) ||
_rmpc__unpause_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc unpause commands' commands "$@"
}
(( $+functions[_rmpc__update_commands] )) ||
_rmpc__update_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc update commands' commands "$@"
}
(( $+functions[_rmpc__version_commands] )) ||
_rmpc__version_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc version commands' commands "$@"
}
(( $+functions[_rmpc__volume_commands] )) ||
_rmpc__volume_commands() {
    local commands; commands=()
    _describe -t commands 'rmpc volume commands' commands "$@"
}

if [ "$funcstack[1]" = "_rmpc" ]; then
    _rmpc "$@"
else
    compdef _rmpc rmpc
fi
