#!/usr/bin/env sh

set -e

echo "process: $1"
if [ -z "$1" ]; then
  exit 130 # process not provided
fi

echo "duration: $2s"
if [ -z "$2" ]; then
  exit 131 # duration not provided
fi

case $1 in
    ''|*[!0-9]*)
      pid="$(pgrep $1 || exit 132)" # process not found
      ;;
    *)
      pid="$1"
      ;;
esac
echo "pid: $1"

echo "is it java?"
exe=$(readlink "/proc/$pid/exe")
case "$exe" in
  *java*)
    echo "yes"
    cp /libperfmap.so proc/$pid/root
    java -cp /attach-main.jar net.virtualvoid.perf.AttachOnce $pid
    nspid=$(cat proc/$pid/status | grep NSpid | cut -f3)
    cp /proc/$pid/root/tmp/perf-$nspid.map /tmp/perf-$pid.map
    ;;
  *)
    echo "no"
    ;;
esac

echo "capturing..."
profile --stack-storage-size=65536 -adf -p $pid $2 | tee /out/profile
burn convert --type=folded /out/profile | tee /out/profile.json
