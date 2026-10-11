#!/system/bin/sh
# Run after boot: the installer namespace cannot access the permission service.
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done

TAG=HyperOS4GoogleHotword
PACKAGE=com.google.android.googlequicksearchbox
if ! cmd appops set --user 0 "$PACKAGE" 10020 allow; then
  log -p e -t "$TAG" "Failed to allow Google lock-screen display (10020)."
  exit 1
fi
MODE=$(cmd appops get --user 0 "$PACKAGE" 10020 2>&1)
case "$MODE" in
  *"MIUIOP(10020): allow"*) ;;
  *)
    log -p e -t "$TAG" "Google lock-screen permission not applied: $MODE"
    exit 1
    ;;
esac
if ! cmd appops write-settings; then
  log -p e -t "$TAG" "Google lock-screen permission allowed, but saving settings failed."
  exit 1
fi
log -p i -t "$TAG" "Google lock-screen display (10020) allowed and saved."
