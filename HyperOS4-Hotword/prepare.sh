#!/system/bin/sh
MODDIR=${0%/*}
PACKAGE=com.google.android.googlequicksearchbox
WORK="$MODDIR/.prepare"
fail() {
  rm -rf "$WORK"
  echo "Google preparation failed: $*"
  return 1
}
prepare() {
  mkdir -p "$WORK/app" || return 1
  paths=$(/system/bin/pm path --user 0 "$PACKAGE") || return 1
  printf '%s\n' "$paths" > "$WORK/paths"
  [ -s "$WORK/paths" ] || return 1
  while IFS= read -r line; do
    case "$line" in
      package:*) source=${line#package:} ;;
      *) return 1 ;;
    esac
    [ -f "$source" ] || return 1
    cp "$source" "$WORK/app/${source##*/}" || return 1
  done < "$WORK/paths"
  [ -f "$WORK/app/base.apk" ] || return 1
  definitions=$(/system/bin/pm list permissions -f) || return 1
  printf '%s\n' "$definitions" > "$WORK/definitions"
  package_info=$(/system/bin/dumpsys package "$PACKAGE") || return 1
  printf '%s\n' "$package_info" > "$WORK/package"
  awk '
    /^    requested permissions:/ { active=1; next }
    active && /^    [^ ]/ { active=0 }
    active && /android\.permission\.[A-Z_0-9]+/ { gsub(/^[ \t]+|[ \t\r]+$/, ""); print }
  ' "$WORK/package" > "$WORK/requested"
  [ -s "$WORK/requested" ] || return 1
  awk '
    NR==FNR { requested[$0]=1; next }
    function emit() {
      if (owner=="android" && privileged && requested[name]) {
        grant=(name=="android.permission.CAPTURE_AUDIO_HOTWORD" || name=="android.permission.MANAGE_SOUND_TRIGGER" || name=="android.permission.MANAGE_VOICE_KEYPHRASES" || name=="android.permission.SOUND_TRIGGER_RUN_IN_BATTERY_SAVER")
        tag=grant ? "permission" : "deny-permission"
        print "    <" tag " name=\"" name "\"/>"
        if (grant) grants++
      }
    }
    /^\+ permission:/ { emit(); name=$0; sub(/^\+ permission:/,"",name); sub(/\r$/,"",name); owner=""; privileged=0 }
    /^  package:/ { owner=$0; sub(/^  package:/,"",owner); sub(/\r$/,"",owner) }
    /^  protectionLevel:/ { privileged=($0 ~ /(^|[|])privileged([|]|[\r]*$)/) }
    END { emit(); if (grants!=4) exit 1 }
  ' "$WORK/requested" "$WORK/definitions" > "$WORK/entries" || return 1
  {
    echo '<?xml version="1.0" encoding="utf-8"?>'
    echo '<permissions>'
    echo '  <privapp-permissions package="com.google.android.googlequicksearchbox">'
    cat "$WORK/entries"
    echo '  </privapp-permissions>'
    echo '</permissions>'
  } > "$WORK/policy.xml" || return 1
  paths_after=$(/system/bin/pm path --user 0 "$PACKAGE") || return 1
  printf '%s\n' "$paths_after" > "$WORK/paths-after"
  cmp -s "$WORK/paths" "$WORK/paths-after" || return 1
  chmod 0755 "$WORK/app" || return 1
  chmod 0644 "$WORK/app/"*.apk "$WORK/policy.xml" || return 1
  chown -R 0:0 "$WORK/app" "$WORK/policy.xml" || return 1
  chcon -R u:object_r:system_file:s0 "$WORK/app" "$WORK/policy.xml" || return 1
  mkdir -p "$MODDIR/system/priv-app" "$MODDIR/system/etc/permissions" || return 1
  rm -rf "$MODDIR/system/priv-app/HyperOS4Google"
  mv "$WORK/app" "$MODDIR/system/priv-app/HyperOS4Google" || return 1
  mv "$WORK/policy.xml" "$MODDIR/system/etc/permissions/privapp-hyperos4-google-hotword.xml" || return 1
  rm -rf "$WORK"
  rm -f "$MODDIR/skip_mount"
}
if ! prepare; then
  fail "Install Google App for user 0, then reboot to try preparation again."
  exit 1
fi
echo 'Google APKs and permission policy prepared locally. Reboot again to activate systemless mounting.'
