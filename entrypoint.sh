#!/usr/bin/env sh

set -e

echo "duration: $2s"
if [ -z "$2" ]; then
  exit 131 # duration not provided
fi

case $1 in
  '')
    pid=$(ps -e -opid= --sort -%cpu | head -n1)
    ;;
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
    cat /proc/$pid/cmdline | grep -qFe '-XX:+PreserveFramePointer' || exit 133
    set +e
    jcmd $pid Compiler.perfmap
    set -e
    if [ $? -ne 0 ]; then
      cp /libperfmap.so /proc/$pid/root
      java -cp /attach-main.jar net.virtualvoid.perf.AttachOnce $pid
      nspid=$(cat proc/$pid/status | grep NSpid | cut -f3)
      cp /proc/$pid/root/tmp/perf-$nspid.map /tmp/perf-$pid.map
    fi
    ;;
  *)
    echo "no"
    ;;
esac

echo "capturing..."
profile --stack-storage-size=65536 -adf -p $pid $2 | tee /out/profile
burn convert --type=folded /out/profile | tee /out/profile.json
