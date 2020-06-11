#!/bin/sh

set -ex

# build / lint agent in a container
find . -name "goroot" -type d | xargs rm -rf
mkdir goroot

docker build -f Dockerfile.git -t golang-git:1.14-alpine .
docker run --user $(id -u ${USER}):$(id -g ${USER}) -v ${PWD}/goroot:/go/ --rm golang-git:1.14-alpine /bin/sh -c 'go get github.com/signalsciences/tlstext && go get github.com/tinylib/msgp && go get github.com/alecthomas/gometalinter'
./scripts/build-docker.sh

# run module tests
./scripts/test.sh

BASE=$PWD
## setup our package properties by distro
PKG_NAME="sigsci-module-golang"
DEST_BUCKET="package-build-artifacts"
DEST_KEY="${PKG_NAME}/${GITHUB_RUN_NUMBER}"
VERSION=$(cat ./VERSION)

cd ${BASE}
echo "DONE"

# Main package
aws s3api put-object \
  --bucket "${DEST_BUCKET}" \
  --cache-control="max-age=300" \
  --content-type="application/octet-stream" \
  --body "./artifacts/${PKG_NAME}.tar.gz" \
  --key "${DEST_KEY}/${PKG_NAME}_${VERSION}.tar.gz" \
  --grant-full-control id="${PROD_ID}"

# Metadata files
aws s3api put-object \
  --bucket "${DEST_BUCKET}" \
  --cache-control="max-age=300" \
  --content-type="text/plain; charset=UTF-8" \
  --body "VERSION" \
  --key "${DEST_KEY}/VERSION" \
  --grant-full-control id="${PROD_ID}"

aws s3api put-object \
  --bucket "${DEST_BUCKET}" \
  --cache-control="max-age=300" \
  --content-type="text/plain; charset=UTF-8" \
  --body "CHANGELOG.md" \
  --key "${DEST_KEY}/CHANGELOG.md" \
  --grant-full-control id="${PROD_ID}"