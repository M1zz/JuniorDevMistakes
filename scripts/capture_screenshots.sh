#!/bin/zsh
# Builds a Debug app, captures every screenshot scene in every language on an iPhone 6.9"
# and an iPad 13" simulator, then composes the App Store images.
#   raw captures → docs/screenshots/raw/{iphone,ipad}/<lang>/<scene>.png   (not uploaded)
#   store images → docs/screenshots/marketing/<lang>/NN-<scene>.png        (DeployBar uploads these)
#
# Usage: scripts/capture_screenshots.sh <iPhone UDID> <iPad UDID> [lang ...]
#   With languages after the devices, only those are (re)captured and composed.
#   Scenes come from the app's DEBUG-only `-screenshotScene` launch argument (JuniorDevMistakesApp.swift).
set -euo pipefail

ROOT=${0:A:h:h}
IPHONE=$1 IPAD=$2
shift 2
BUNDLE_ID=com.leeo.JuniorDevMistakes
DD=$ROOT/build/screenshots-dd
RAW=$ROOT/docs/screenshots/raw
SCENES=(home detail list retro progress)

# <AppleLanguages code>:<AppleLocale>. The code is also the folder name.
LANGS=(ko:ko_KR en:en_US en-GB:en_GB zh-Hans:zh_CN zh-Hant:zh_TW ja:ja_JP ru:ru_RU es:es_ES de:de_DE fr:fr_FR it:it_IT
       pt-BR:pt_BR th:th_TH vi:vi_VN cs:cs_CZ da:da_DK el:el_GR fi:fi_FI id:id_ID nb:nb_NO nl:nl_NL pl:pl_PL sv:sv_SE tr:tr_TR)

# True when the capture is missing or a single flat colour (app not drawn yet).
blank() { [[ ! -s $1 ]] || python3 -c 'import sys; from PIL import Image, ImageStat
im = Image.open(sys.argv[1]).convert("L"); c = im.crop((0, 300, im.width, im.height - 200))
sys.exit(0 if ImageStat.Stat(c).stddev[0] < 12 else 1)' "$1"; }

nice -n 10 xcodebuild -project $ROOT/JuniorDevMistakes.xcodeproj -scheme JuniorDevMistakes -configuration Debug \
  -destination "generic/platform=iOS Simulator" -derivedDataPath $DD build -quiet
APP=$DD/Build/Products/Debug-iphonesimulator/JuniorDevMistakes.app

for device in $IPHONE $IPAD; do
  xcrun simctl boot $device 2>/dev/null || true
  xcrun simctl bootstatus $device -b >/dev/null
  xcrun simctl install $device $APP
  xcrun simctl status_bar $device override --time "9:41" --dataNetwork wifi --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100 --operatorName ""
done

# One loop per device, run side by side.
capture() {
  local kind=$1 device=$2; shift 2
  for entry in $LANGS; do
    local lang=${entry%%:*} locale=${entry##*:}
    if (( $# > 0 )) && (( ! ${@[(Ie)$lang]} )); then continue; fi
    mkdir -p $RAW/$kind/$lang
    for scene in $SCENES; do
      local shot=$RAW/$kind/$lang/$scene.png
      xcrun simctl terminate $device $BUNDLE_ID 2>/dev/null || true
      xcrun simctl launch $device $BUNDLE_ID -screenshotScene $scene -hasSeenOnboarding YES -isPremiumUnlocked YES \
        -AppleLanguages "($lang)" -AppleLocale $locale >/dev/null
      for wait in 6 10 16; do
        sleep $wait
        xcrun simctl io $device screenshot $shot >/dev/null 2>&1 || true
        blank $shot || break
      done
      echo "captured $kind/$lang/$scene"
    done
  done
}
capture iphone $IPHONE "$@" &
capture ipad $IPAD "$@" &
wait

for device in $IPHONE $IPAD; do
  xcrun simctl terminate $device $BUNDLE_ID 2>/dev/null || true
  xcrun simctl status_bar $device clear
done

python3 $ROOT/scripts/compose_screenshots.py "$@"
