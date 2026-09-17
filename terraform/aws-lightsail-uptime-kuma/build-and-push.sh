#!/bin/bash
# Build and deploy custom Uptime Kuma image to ECR

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REPO_NAME="uptime-kuma"
IMAGE_TAG="${IMAGE_TAG:-configured}"

echo "Building custom Uptime Kuma image..."

# Check if kuma.db exists
if [ ! -f "kuma.db" ]; then
  echo "Error: kuma.db not found!"
  echo "Export your database first:"
  echo "  docker cp uptime-kuma:/app/data/kuma.db ./kuma.db"
  exit 1
fi

# Build the Docker image
docker build -t "${ECR_REPO_NAME}:${IMAGE_TAG}" .

echo "Image built successfully!"

# Create ECR repository if it doesn't exist
echo "Checking ECR repository..."
aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${AWS_REGION}" 2>/dev/null || \
  aws ecr create-repository --repository-name "${ECR_REPO_NAME}" --region "${AWS_REGION}"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Tag and push
ECR_IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"
echo "Tagging image as: ${ECR_IMAGE_URI}"
docker tag "${ECR_REPO_NAME}:${IMAGE_TAG}" "${ECR_IMAGE_URI}"

echo "Pushing image to ECR..."
docker push "${ECR_IMAGE_URI}"

echo ""
echo "✅ Image pushed successfully!"
echo ""
echo "Update your terraform.tfvars with:"
echo "  uptime_kuma_image = \"${ECR_IMAGE_URI}\""
echo ""
