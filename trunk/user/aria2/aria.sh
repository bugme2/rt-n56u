#!/bin/sh

#######################################################################
# (1) run process from superuser root (less security)
# (0) run process from unprivileged user "nobody" (more security)
SVC_ROOT=0

# process priority (0-normal, 19-lowest)
SVC_PRIORITY=3
#######################################################################

SVC_NAME="Aria2"
SVC_PATH="/usr/bin/aria2c"
DIR_LINK="/mnt/aria"

func_start()
{
	# Make sure already running
	if [ -n "`pidof aria2c`" ] ; then
		return 0
	fi

	echo -n "Starting $SVC_NAME:."

	if [ ! -d "${DIR_LINK}" ] ; then
		mkdir -p "$DIR_LINK"
	fi

	for i in "a1" "a2" "a3" "a4" "b1" "b2" "b3" "b4" ; do
		disk_path="/media/AiDisk_${i}"
		if [ -d "${disk_path}" ] && grep -q ${disk_path} /proc/mounts ; then
			DIR_DL1="${disk_path}/downloads"
		fi
	done

	FILE_CONF_storage="/etc/storage/aria2.conf"
	FILE_CONF="$DIR_LINK/aria2.conf"
	FILE_LIST="$DIR_LINK/incomplete.lst"

	touch "$FILE_LIST"

	aria_pport=`nvram get aria_pport`
	aria_rport=`nvram get aria_rport`

	[ -z "$aria_rport" ] && aria_rport="6800"
	[ -z "$aria_pport" ] && aria_pport="16888"

	if [ ! -f "$FILE_CONF_storage" ] ; then
		[ ! -d "$DIR_DL1" ] && mkdir -p "$DIR_DL1"
		chmod -R 777 "$DIR_DL1"
		cat > "$FILE_CONF_storage" <<EOF
dir=$DIR_DL1
file-allocation=none
continue=true
split=8
max-concurrent-downloads=3
max-connection-per-server=8
content-disposition-default-utf8=true
enable-rpc=true
disable-ipv6=true
rpc-listen-all=true
rpc-allow-origin-all=true
follow-torrent=true
enable-dht=true
enable-dht6=false
seed-time=0
bt-max-peers=0
bt-enable-lpd=true
bt-remove-unselected-file=true
enable-peer-exchange=true
optimize-concurrent-downloads=true
peer-id-prefix=-TR2930-
peer-agent=Transmission/2.93
bt-seed-unverified=true
allow-overwrite=true
EOF
	fi

if [ -f "$FILE_CONF_storage" ] && [ -s "$FILE_CONF_storage" ] ; then
	umount -l $FILE_CONF
	[ -f "$FILE_CONF" ] && rm -f $FILE_CONF
	cp -f $FILE_CONF_storage $FILE_CONF
	mount --bind $FILE_CONF_storage $FILE_CONF
fi

	# aria2 needed home dir
	export HOME="$DIR_LINK"

	svc_user=""

	if [ $SVC_ROOT -eq 0 ] ; then
		chmod 777 "${DIR_LINK}"
		chown -R nobody "$DIR_LINK"
		svc_user=" -c nobody"
	fi

	start-stop-daemon -S -N $SVC_PRIORITY$svc_user -x $SVC_PATH -- \
		-D --conf-path="$FILE_CONF" --input-file="$FILE_LIST" --save-session="$FILE_LIST" \
		--rpc-listen-port="$aria_rport" --listen-port="$aria_pport" --dht-listen-port="$aria_pport"

	if [ $? -eq 0 ] ; then
		echo "[  OK  ]"
		logger -t "$SVC_NAME" "daemon is started"
	else
		echo "[FAILED]"
	fi
}

func_stop()
{
	# Make sure not running
	if [ -z "`pidof aria2c`" ] ; then
		return 0
	fi

	echo -n "Stopping $SVC_NAME:."

	# stop daemon
	killall -q aria2c

	# gracefully wait max 15 seconds while aria2c stopped
	i=0
	while [ -n "`pidof aria2c`" ] && [ $i -le 15 ] ; do
		echo -n "."
		i=$(( $i + 1 ))
		sleep 1
	done

	aria_pid=`pidof aria2c`
	if [ -n "$aria_pid" ] ; then
		# force kill (hungup?)
		kill -9 "$aria_pid"
		sleep 1
		echo "[KILLED]"
		logger -t "$SVC_NAME" "Cannot stop: Timeout reached! Force killed."
	else
		echo "[  OK  ]"
	fi
}

func_reload()
{
	aria_pid=`pidof aria2c`
	if [ -n "$aria_pid" ] ; then
		echo -n "Reload $SVC_NAME config:."
		kill -1 "$aria_pid"
		echo "[  OK  ]"
	else
		echo "Error: $SVC_NAME is not started!"
	fi
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
reload)
	func_reload
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: $0 {start|stop|reload|restart}"
	exit 1
	;;
esac

