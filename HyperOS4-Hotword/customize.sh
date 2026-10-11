#!/system/bin/sh
# Google APKs and this ROM's permission policy are captured over ADB or reused offline.
# KernelSU's installer namespace on this ROM cannot call PackageManager Binder.
[ "$BOOTMODE" = true ] || abort "Install from a running Android system."
[ "$API" -ge 36 ] || abort "Original enrollment APKs require Android 16 or newer."
[ ! -d /data/adb/modules/GoogleApp ] || abort "Remove the GoogleApp module first to avoid duplicate system packages."
if [ "$KSU" = true ]; then
  [ -d /data/adb/modules/meta-mm ] || abort "This device requires the existing meta-mm mount metamodule."
fi
[ -f "$MODPATH/system/priv-app/HyperOS4Google/base.apk" ] || abort "Build this device-specific ZIP using build.ps1 first."
[ -f "$MODPATH/system/etc/permissions/privapp-hyperos4-google-hotword.xml" ] || abort "Device permission policy missing."
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
ui_print "- Prepared Google APKs copied without changing app version or clearing data."
ui_print "- Four Google hotword grants plus two requested enrollment privileges per APK."
ui_print "- No Pixel features, SELinux rules or system partition writes."
ui_print "- Google lock-screen display permission will be allowed automatically after reboot."
ui_print "- Reboot required; complete Voice Match enrollment yourself."
