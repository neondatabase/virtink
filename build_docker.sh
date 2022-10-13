#!/bin/bash

set -xe

DOCKER_BUILDKIT=1 
REGISTRY=sergeyneon
TAG=dev-2022-09-28

echo virt-prerunner
docker buildx build \
    --pull \
    -f build/virt-prerunner/Dockerfile \
    -t "${REGISTRY}/virt-prerunner:${TAG}" \
    .

echo virt-controller
docker buildx build \
    --pull \
    -f build/virt-controller/Dockerfile \
    -t "${REGISTRY}/virt-controller:${TAG}" \
    --build-arg PRERUNNER_IMAGE="${REGISTRY}/virt-prerunner:${TAG}" \
    .

echo virt-daemon
docker buildx build \
    --pull \
    -f build/virt-daemon/Dockerfile \
    -t "${REGISTRY}/virt-daemon:${TAG}" \
    .

echo push
docker push "${REGISTRY}/virt-prerunner:${TAG}"
docker push "${REGISTRY}/virt-controller:${TAG}"
docker push "${REGISTRY}/virt-daemon:${TAG}"

LOCALBIN="$(pwd)/bin"
SKAFFOLD="${LOCALBIN}/skaffold"

GOARCH="$(go env GOARCH)"
GOOS="$(go env GOOS)"

mkdir -p "${LOCALBIN}"
SKAFFOLD_URL="https://storage.googleapis.com/skaffold/releases/latest/skaffold-${GOOS}-${GOARCH}"
test -f "${SKAFFOLD}" || curl -sLo "${SKAFFOLD}" "$SKAFFOLD_URL" && chmod +x "${SKAFFOLD}"

PATH="${LOCALBIN}:${PATH}" "${SKAFFOLD}" render --offline=true --default-repo="${REGISTRY}" \
    --digest-source=tag --images "virt-controller:${TAG},virt-daemon:${TAG}" \
    >"virtink_${REGISTRY}.yaml"
