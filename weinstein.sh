#!/usr/bin/env bash

set -e # exit on error

# Absolute path to the directory that contains this script
HERE=`realpath "$(dirname "$0")"`

error()
{
	echo "-!- $1"
	exit 1
}


# ============ Setup / Preconditions

[ ! -f "config.sh" ] && \
	error "Missing config.sh. Please read the setup instructions."

# CFG_* variables
source "$HERE/config.sh"

[ ! -f "$CFG_WINE_ROOT/bin/wine" ] && \
	error "Edit config.sh. Cannot find the 'wine' binary."

[ ! -d "$CFG_SRC_DIR" ] && \
	error "Edit config.sh. The directory '$CFG_SRC_DIR' does not exist."
[ ! -f "$CFG_SRC_DIR/include/windows.h" ] && \
	error "'$CFG_SRC_DIR' is not a valid Wine source clone."
[ ! -f "$CFG_BUILD_DIR/Makefile" ] && \
	error "Forgot to run 'configure'? Build path '$CFG_BUILD_DIR' has no Makefile."

DLL_SRC="$CFG_BUILD_DIR/dlls"
DLL_DST="$HERE/overrides/lib/wine"

# Cannot use .gitkeep here. The directory must be empty. This is a unionfs safeguard.
[ ! -d "$HERE/fakeinstall" ] && mkdir "$HERE/fakeinstall"
if [ ! -d "$DLL_DST" ]; then
	mkdir -p "${DLL_DST}/x86_64-windows"
	mkdir -p "${DLL_DST}/x86_64-unix"
fi

# Dependency check
for appname in unionfs; do
	binpath=$(command -v "$appname" | tee)
	[ ! -e "$binpath" ] && \
		error "Cannot find dependency: ${appname}."
done


# ============ Utility functions

print_help()
{
	echo "Commands can be either specified with '--cmd' or 'cmd'."
	echo "Available commands:"
	echo "   a|apply  DLLDIRNAME    *1  Adds a DLL to the fake Wine install"
	echo "   r|remove DLLDIRNAME    *1  Counterpart of 'apply'"
	echo "   b|build  DLLDIRNAME    *1  Builds the specified DLL"
	echo "   r|run  CMD ARGS ...    Runs the specified command using the fake Wine install"
	echo "   d|dbg  CMD ARGS ...    Same as 'run winedbg CMD ARGS ...'"
	echo "   u                      *1  Unmounts the fake install"
	echo "Note *1: This command does not terminate the script, thus allows daisy-chaining."
	echo "Note: After a 'build' command, you should run 'apply' to update the \"installed\" DLL."
}

run_prepared=0
prepare_run()
{
	[ "$run_prepared" -ne 0 ] && return

	if [ ! -d "$HERE/fakeinstall/lib" ]; then
		unionfs "$HERE/overrides":"$CFG_WINE_ROOT" "$HERE/fakeinstall"
		echo "--> Mounted unionfs-fuse dir"
	fi

	if [ -n "$WINEPREFIX" ]; then
		# Use directly without overwriting
		export WINEPREFIX
	elif [ -n "$CFG_ENV_WINEPREFIX" ]; then
		export WINEPREFIX="$CFG_ENV_WINEPREFIX"
	fi # else: global default

	if [ -z "$WINEPREFIX" ]; then
		echo "=== WARNING! Using the default WINEPREFIX (most likely ~/.wine/)"
	else
		echo "Using WINEPREFIX = ${WINEPREFIX}"
	fi

	export WINEDEBUG="$CFG_ENV_WINEDEBUG,$WINEDEBUG"
	echo "Using WINEDEBUG = ${WINEDEBUG}"
	echo ""
	run_prepared=1
}

link_file() {
	# ntdll does not like getting symlinked
	#ln -vsf "$1" "$2"
	ln -vf "$1" "$2"
}


# ============ CLI argument parsing

while [[ $# -gt 0 ]]; do
	arg=${1##--}
	case "$arg" in
		h|help|'?')
			print_help
			break
			;;
		u|umount|unmount)
			fusermount -u "$HERE/fakeinstall"
			echo "--> Unmounted fuse dir"
			shift 1
			;;
		r|run)
			prepare_run
			shift 1
			"$HERE/fakeinstall/bin/wine" $*
			break
			;;
		d|dbg)
			prepare_run
			shift 1
			"$HERE/fakeinstall/bin/wine" winedbg $*
			break
			;;
		b|build)
			dll_dir="${DLL_SRC}/$2" # /path/to/wine/dlls/shell32
			make -C "$dll_dir" -j
			shift 2
			;;
		a|apply)
			COMP="$2" # DLL dir name: shell32, winex11.drv
			COMP_NOEXT=${2%.*} # trim "extension"
			dll_dir="${DLL_SRC}/${COMP}" # /path/to/wine/dlls/shell32

			for ext in dll exe drv; do
				f="${dll_dir}/x86_64-windows/${COMP_NOEXT}.${ext}"
				[ -e "$f" ] && link_file "$f" "${DLL_DST}/x86_64-windows/"

				f="${dll_dir}/${COMP_NOEXT}.${ext}.so"
				[ -e "$f" ] && link_file "$f" "${DLL_DST}/x86_64-unix/"
			done
			[ -e "${dll_dir}/${COMP}.so" ] &&
				link_file "${dll_dir}/${COMP}.so" "${DLL_DST}/x86_64-unix/"

			shift 2
			;;
		r|rm|remove)
			COMP="$2" # DLL dir name: shell32, winex11.drv
			COMP_NOEXT=${2%.*} # trim "extension"

			for ext in dll exe drv; do
				rm -vf "${DLL_DST}/x86_64-windows/${COMP_NOEXT}.${ext}"
				rm -vf "${DLL_DST}/x86_64-unix/${COMP_NOEXT}.${ext}.so"
			done
			rm -vf "${DLL_DST}/x86_64-unix/${COMP}.so"

			shift 2
			;;
		i|installed|list)
			list=$(find "$DLL_DST" -type f,l | xargs -L1 -r basename | sort)
			echo "==> Installed files:"
			echo "$list"

			shift 1
			;;
		*)
			error "Unknown argument $1"
			;;
	esac
done

echo "--> Exit"
