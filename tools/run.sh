#!/bin/sh

export MINIO_HOST=${MINIO_HOST:-minio}
export MINIO_PORT=${MINIO_PORT:-9000}
export MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY:-fake_key_id}
export MINIO_SECRET_KEY=${MINIO_SECRET_KEY:-fake_secret_key}
export MINIO_REGION_NAME=${MINIO_REGION_NAME:-local-region}
export INSIGHTS_BUCKET=${INSIGHTS_BUCKET:-insights}

echo "Loading - Vulcan tools"

until nc $MINIO_HOST $MINIO_PORT; do
    echo "Waiting for MINIO" && sleep 15;
done

# Configure MINIO Client
./mc config host add minio http://$MINIO_HOST:$MINIO_PORT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

# Copy static files to insights bucket
./mc mirror _public_resources/ minio/$INSIGHTS_BUCKET/public/ --region $MINIO_REGION_NAME

echo "Loaded - Vulcan tools"
sleep infinit
