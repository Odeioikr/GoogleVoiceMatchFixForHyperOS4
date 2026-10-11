#!/system/bin/sh
# Google APKs and permission policy are prepared locally after the first boot.
# KernelSU's installer namespace on this ROM cannot call PackageManager Binder.
[ "$BOOTMODE" = true ] || abort "Install from a running Android system."
[ "$KSU" = true ] || abort "This module requires KernelSU."
[ "$API" -ge 36 ] || abort "Original enrollment APKs require Android 16 or newer."
[ ! -d /data/adb/modules/GoogleApp ] || abort "Remove the GoogleApp module first to avoid duplicate system packages."
if [ "$KSU" = true ]; then
  [ -d /data/adb/modules/meta-mm ] || abort "This device requires the existing meta-mm mount metamodule."
fi
[ -f "$MODPATH/prepare.sh" ] || abort "Local Google preparation script missing."
[ -f "$MODPATH/service.sh" ] || abort "Lock-screen permission service missing."
for payload in \
  priv-app/HotwordEnrollmentXGoogleHEXAGON_WIDEBAND/HotwordEnrollmentXGoogleHEXAGON_WIDEBAND.apk \
  priv-app/HotwordEnrollmentYGoogleHEXAGON_WIDEBAND/HotwordEnrollmentYGoogleHEXAGON_WIDEBAND.apk \
  framework/com.android.hotwordenrollment.common.util.jar \
  etc/permissions/com.android.hotwordenrollment.common.util.xml \
  etc/permissions/privapp-hyperos4-enrollment.xml; do
  [ -f "$MODPATH/system/$payload" ] || abort "Enrollment payload missing: $payload"
done
set_perm_recursive "$MODPATH/system" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/prepare.sh" 0 0 0755
touch "$MODPATH/skip_mount"
ui_print "- No Google App APK is distributed; your installed Google App will be reused locally."
ui_print "- Four Google hotword grants plus two requested enrollment privileges per APK."
ui_print "- No Pixel features, SELinux rules or system partition writes."
ui_print "- Google lock-screen display permission will be allowed automatically after reboot."
ui_print "- Reboot once to prepare Google, then reboot again to activate mounting."
ui_print "- Google App must already be installed for user 0; no app data is copied or cleared."
