"""Prepare native Android/iOS runners for Izdihar (Flutter must be installed)."""
import re
import shutil
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
if not shutil.which('flutter'):
    raise SystemExit('Flutter SDK غير موجود في PATH. ثبّت Flutter أولًا ثم أعد المحاولة.')

print('1/3 Creating native platform templates...')
subprocess.run(
    ['flutter', 'create', '--project-name', 'izdihar', '--org', 'com.izdihar', '--platforms=android,ios', '.'],
    cwd=root, check=True,
)

print('2/3 Configuring Android notifications and Java desugaring...')
manifest = root / 'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    s = manifest.read_text(encoding='utf-8')
    permissions = (
        '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n'
        '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n'
    )
    if 'android.permission.RECEIVE_BOOT_COMPLETED' not in s:
        s = s.replace('<application', permissions + '    <application', 1)
    receivers = '''
        <!-- Scheduled local reminders, restored when the device restarts -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
    if 'ScheduledNotificationReceiver' not in s:
        s = s.replace('</application>', receivers + '    </application>', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="ازدهار"', s, count=1)
    manifest.write_text(s, encoding='utf-8')

build = root / 'android/app/build.gradle.kts'
if build.exists():
    s = build.read_text(encoding='utf-8')
    s = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = 36', s, count=1)
    if 'isCoreLibraryDesugaringEnabled' not in s:
        s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
    s = re.sub(r'sourceCompatibility\s*=\s*JavaVersion\.VERSION_\d+',
               'sourceCompatibility = JavaVersion.VERSION_17', s)
    s = re.sub(r'targetCompatibility\s*=\s*JavaVersion\.VERSION_\d+',
               'targetCompatibility = JavaVersion.VERSION_17', s)
    s = re.sub(r'jvmTarget\s*=\s*JavaVersion\.VERSION_\d+\.toString\(\)',
               'jvmTarget = JavaVersion.VERSION_17.toString()', s)
    if 'multiDexEnabled' not in s:
        s = s.replace('defaultConfig {', 'defaultConfig {\n        multiDexEnabled = true', 1)
    if 'coreLibraryDesugaring(' not in s:
        s += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    build.write_text(s, encoding='utf-8')

settings = root / 'android/settings.gradle.kts'
if settings.exists():
    s = settings.read_text(encoding='utf-8')
    s = re.sub(r'(id\("com\.android\.application"\)\s+version\s+")[^"]+("\s+apply\s+false)',
               r'\g<1>8.11.1\2', s)
    settings.write_text(s, encoding='utf-8')

wrapper = root / 'android/gradle/wrapper/gradle-wrapper.properties'
if wrapper.exists():
    s = wrapper.read_text(encoding='utf-8')
    s = re.sub(r'gradle-[\d.]+-(?:all|bin)\.zip', 'gradle-8.13-all.zip', s)
    wrapper.write_text(s, encoding='utf-8')

# iOS supports >= 13.0 for this dependency set.
podfile = root / 'ios/Podfile'
if podfile.exists():
    s = podfile.read_text(encoding='utf-8')
    s = re.sub(r"#?\s*platform :ios, '[0-9.]+'", "platform :ios, '13.0'", s, count=1)
    podfile.write_text(s, encoding='utf-8')

print('3/3 Resolving Flutter packages...')
subprocess.run(['flutter', 'pub', 'get'], cwd=root, check=True)
print('Ready! Run: flutter run')
