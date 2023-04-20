#!/bin/bash

# Get latest version of ReVanced tools
TOOLS=$(curl -s -X 'GET' 'https://releases.revanced.app/tools' -H 'accept: application/json')

TOOLS_NEEDED="revanced-cli revanced-patches revanced-integrations"

for TOOL in ${TOOLS_NEEDED[@]}; do
    echo "Getting $TOOL"
    INDEX=""
    if [ "$TOOL" == "revanced-patches" ]; then
        INDEX="2"
    fi
    TOOL_NAME=$(echo $TOOLS | jq -r ".tools | .[$INDEX] | select(.repository==\"revanced/$TOOL\") | .name")
    TOOL_URL=$(echo $TOOLS | jq -r ".tools | .[$INDEX] | select(.repository==\"revanced/$TOOL\") | .browser_download_url")

    if [ -f "$TOOL_NAME" ]; then
        echo "$TOOL_NAME already downloaded, skipping!"
        continue
    fi

    wget -q "$TOOL_URL" -O "$TOOL_NAME"
done

function get_name() {
    INDEX=""
    if [ "$1" == "revanced-patches" ]; then
        INDEX="2"
    fi
    echo $TOOLS | jq -r ".tools | .[$INDEX] | select(.repository==\"revanced/$1\") | .name"
}

REVANCED_CLI=$(get_name "revanced-cli")
REVANCED_PATCHES=$(get_name "revanced-patches")
REVANCED_INTEGRATIONS=$(get_name "revanced-integrations")

# Get patches
wget -q https://releases.revanced.app/patches -O patches.json

# Get latest version of apkkeep
echo "Getting apkkeep"

APKKEEP_URL=$(curl -s -X GET https://api.github.com/repos/EFForg/apkeep/releases/latest | jq -r ".assets[] | select(.name | contains(\"apkeep-x86_64-unknown-linux-gnu\") and (contains(\".sig\") | not)) | .browser_download_url")
if [ ! -f "apkkeep" ]; then
    wget -q "$APKKEEP_URL" -O apkkeep
    chmod +x apkkeep
fi

# Get latest youtube version
YOUTUBE_VERSION=$(cat patches.json | jq -r ".[] | select(.name==\"spoof-app-version\") | .compatiblePackages | .[] | .versions | .[-1]")

echo "$YOUTUBE_VERSION" > yt-version

# Download YouTube apk
YOUTUBE_APK="com.google.android.youtube@$YOUTUBE_VERSION"
./apkkeep -a "$YOUTUBE_APK" .

declare -a EXCLUDED_PATCHES

for p in $(cat excluded-patches); do
    EXCLUDED_PATCHES+=("-e $p")
done

# Finally patch the apk
java -jar "$REVANCED_CLI" \
  ${EXCLUDED_PATCHES[@]} \
  -a "$YOUTUBE_APK".apk \
  -b "$REVANCED_PATCHES" \
  -m "$REVANCED_INTEGRATIONS" \
  -o revanced_youtube_"$YOUTUBE_VERSION".apk