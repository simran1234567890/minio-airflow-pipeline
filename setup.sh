#!/bin/bash

# Setup script for MinIO-Airflow-Webhook pipeline

echo "🚀 Setting up MinIO-Airflow-Webhook Pipeline"
echo "=============================================="

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p logs plugins

# Start the services
echo "🐳 Starting services with Docker Compose..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check if MinIO is running
echo "🔍 Checking MinIO status..."
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    echo "✅ MinIO is running"
else
    echo "❌ MinIO is not responding. Please check the logs:"
    docker-compose logs minio
    exit 1
fi

# Check if Airflow is running
echo "🔍 Checking Airflow status..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "✅ Airflow is running"
else
    echo "❌ Airflow is not responding. Please check the logs:"
    docker-compose logs airflow-webserver
    exit 1
fi

# Check if webhook is running
echo "🔍 Checking webhook status..."
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Webhook server is running"
else
    echo "❌ Webhook server is not responding. Please check the logs:"
    docker-compose logs webhook
    exit 1
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Service URLs:"
echo "   - MinIO Console: http://localhost:9001 (minioadmin/minioadmin)"
echo "   - MinIO API: http://localhost:9000"
echo "   - Airflow: http://localhost:8080 (airflow/airflow)"
echo "   - Webhook: http://localhost:5000"
echo ""
echo "📝 Next steps:"
echo "   1. Create MinIO buckets:"
echo "      mc alias set local http://localhost:9000 minioadmin minioadmin"
echo "      mc mb local/testing-files"
echo "      mc mb local/compressed-files"
echo ""
echo "   2. Configure MinIO notifications (optional):"
echo "      mc event add local/testing-files arn:minio:sqs::webhook:webhook --event put"
echo ""
echo "   3. Test the pipeline by uploading a file to the testing-files bucket"
echo ""
echo "🔧 Manual testing:"
echo "   - Test webhook: curl http://localhost:5000/test"
echo "   - Manual trigger: curl -X POST http://localhost:5000/trigger-dag -H 'Content-Type: application/json' -d '{\"object_name\":\"test.txt\"}'"
echo "" 