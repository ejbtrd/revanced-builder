#!/bin/bash

LOCAL_YOUTUBE_VERSION=$(cat yt-version)

REVANCED_YOUTUBE_VERSION=$(curl -s -X GET https://releases.revanced.app/patches | jq -r ".[] | select(.name==\"spoof-app-version\") | .compatiblePackages | .[] | .versions | .[-1]")

if [ "$LOCAL_YOUTUBE_VERSION" == "$REVANCED_YOUTUBE_VERSION" ]; then
    echo "Latest YouTube version supported by ReVanced is equal to last patched version, aborting!"
    exit 1
fi
