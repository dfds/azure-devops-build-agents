#!/bin/bash
#
# build.sh(1)
#

[[ -n $DEBUG ]] && set -x
set -eu -o pipefail

# build parameters
readonly REGION=${AWS_DEFAULT_REGION:-"eu-central-1"}
readonly IMAGE_NAME='azure-devops-build-agent'
readonly TAG='ubuntu-16.04'
readonly BUILD_NUMBER=${1:-"N/A"}
readonly BUILD_SOURCES_DIRECTORY=${2:-${PWD}}

build_container_image() {
    echo "Building container image..."
    docker build -t ${IMAGE_NAME}:${TAG} .
}

push_container_image() {
    echo "Login to docker..."
    $(aws ecr get-login --no-include-email)

    account_id=$(aws sts get-caller-identity --output text --query 'Account')
    ecr_image_name="${account_id}.dkr.ecr.${REGION}.amazonaws.com/ded/${IMAGE_NAME}:${TAG}"

    echo "Tagging container image..."
    docker tag ${IMAGE_NAME}:${TAG} ${ecr_image_name}

    echo "Pushing container image to ECR..."
    docker push ${ecr_image_name}
}

build_container_image

if [[ "${BUILD_NUMBER}" != "N/A" ]]; then
    push_container_image
fi
