#!/bin/bash
# this script is used by lr-mess to run softwares without using softlists.

if [ $# -lt 6 ]; then
	# NOTE: the file specifying the standalone system to run (eg. simon) MUST ALWAYS BE THE LAST PARAMETER !
        echo "usage: $0 <path/to/retroarch_binary> </path/to/mess_libretro> </path/to/retroarch.cfg>"
        echo "\t<mess_system_name> </path/to/bios_folder> <further_parameters path/to/game_specfile>"
        exit 1
fi

_retroarchbin="$1"
_messpath="$2"
_config="$3"
_cfgdir=$(dirname "$_config")
_system="$4"
_biosdir="$5"

echo "[.] parameters dump"
echo "\t_retroarchbin: $_retroarchbin"
echo "\t_messpath: $_messpath"
echo "\t_config: $_config (+ $_config.add)"
echo "\t_cfg_directory: $_cfgdir"
echo "\t_system: $_system"
echo "\t_biosdir: $_biosdir"

_count=0
_stopadd=false
_lastparam=""
for _param in "$@"; do
    if [[ $_count -gt 4 ]]; then
                # we need to strip --appendconfig here, which seems to be added by runcommand.sh in the end......
                # we also remove verbose, in case it's launched with verbose on from runcommand.sh (we use --verbose anyway ourself)
                if [[ "$_param" == --* ]]; then # "--appendconfig" ]] || [[ "$_param" = "--verbose" ]]; then
                        if [[ "$_stopadd" = false ]]; then
                                _romdir=$(dirname "$_lastparam")
                        fi
                        _stopadd=true
                fi
                if [[ "$_stopadd" = false ]]; then
                _cmdarr+=( \""$_param"\" )
                fi
    fi
    ((_count+=1))
        if [[ "$_stopadd" = false ]]; then
                _lastparam=$_param
                _romdir=$(dirname "$_lastparam")
        fi
done

echo "\t_romdir: $_romdir"

#echo "Spec file contents:"
#echo `cat "$_lastparam"`


# generate parameters for mess.cmd
_cmdarr=()
# the contents of the rom file specified are the actual system to run
_cmdarr+=( `cat "$_lastparam"` )

_cmdarr+=( "-rp" )
_cmdarr+=( "$_biosdir" )
_cmdarr+=( "-cfg_directory" )
_cmdarr+=( "$_cfgdir" )
_cmdarr+=( "-artpath" )
_cmdarr+=( "$_romdir/artwork" )

# generate mess.cmd
echo "\t/tmp/mess.cmd content: ${_cmdarr[@]}"
_tmpcmd="$_romdir/tmpmess.cmd"
_tmpcfg="$_cfgdir/tmpconfig.add"
rm "$_tmpcmd"
rm "$_tmpcfg"
echo "${_cmdarr[@]}" > "$_tmpcmd"

# run retroarch & mess using the custom generated launcher .cmd
# $_config.add has been generated by the setup script, it's needed to force softlists disabled...
# we also add here the same /dev/shm/retroarch.cfg that was stripped above....
cat /dev/shm/retroarch.cfg >> "$_tmpcfg"
cat "$_config.add" >> "$_tmpcfg"
set -- "$_retroarchbin"
set -- "$@" --verbose --config "$_config" --appendconfig "$_tmpcfg" -L "$_messpath" "$_tmpcmd"
echo "[.] launching: $@"
"$@"

# deleting tmp 
rm "$_tmpcmd"
rm "$_tmpcfg"

