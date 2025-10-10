#!/bin/bash
# Script to test build the docker image locally

GIT_DIR=$(pwd)
TARGETPLATFORM="linux/amd64"

# Import buildvars
BUILD_DATE=$(cat ${GIT_DIR}/buildvars | awk '/^BUILD_DATE=/' | cut -d= -f2)
BUILD_IMAGE_VERSION=$(cat ${GIT_DIR}/buildvars | awk '/^BUILD_IMAGE_VERSION=/' | cut -d= -f2)

# Check if BUILD_VERSION is already released
# Check for latest released
if [[ $(curl -s https://api.github.com/repos/megavolts/lego_cli-docker/releases | grep "status" | cut -d\" -f4) = 404 ]];
    then
    echo "No release existing"
else
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/megavolts/lego_cli-docker/releases | jq '.[0] | .name' -r)

    if [[ $LATEST_RELEASE = $BUILD_IMAGE_VERSION ]];
        then
        echo "Release $BUILD_IMAGE_VERSION already exist. Updated build version with next revision"
        BUILD_VERSION=$( echo $BUILD_IMAGE_VERSION | cut -d- -f1)
        BUILD_REVISION=$( echo $BUILD_IMAGE_VERSION | cut -d- -f2)
        BUILD_REVISION=$(( $BUILD_REVISION +1 ))
        BUILD_IMAGE_VERSION=$BUILD_VERSION-$BUILD_REVISION
    fi
fi

echo "Building docker image version $BUILD_IMAGE_VERSION on $BUILD_DATE for $TARGETPLATFORM"

docker buildx build $GIT_DIR/lego_cli/ \
        -t megavolts/lego_cli:latest \
        --build-arg BUILD_IMAGE_VERSION=$BUILD_IMAGE_VERSION \
        --build-arg BUILD_DATE=$BUILD_DATE \
        --build-arg TARGETPLATFORM=$TARGETPLATFORM \
        -t megavolts/lego_cli:$BUILD_IMAGE_VERSION \
        --load
        # --no-cache
