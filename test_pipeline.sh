#!/bin/bash

# Test script for the MinIO-Airflow-Webhook pipeline

echo "🧪 Testing MinIO-Airflow-Webhook Pipeline"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Test 1: Check if services are running
echo ""
echo "🔍 Testing Service Health..."

# Test MinIO
if curl -s http://localhost:9000/minio/health/live > /dev/null; then
    print_status 0 "MinIO is running"
else
    print_status 1 "MinIO is not responding"
fi

# Test Airflow
if curl -s http://localhost:8080/health > /dev/null; then
    print_status 0 "Airflow is running"
else
    print_status 1 "Airflow is not responding"
fi

# Test Webhook
if curl -s http://localhost:5000/health > /dev/null; then
    print_status 0 "Webhook server is running"
else
    print_status 1 "Webhook server is not responding"
fi

# Test 2: Test webhook endpoint
echo ""
echo "🔍 Testing Webhook Endpoint..."
WEBHOOK_RESPONSE=$(curl -s http://localhost:5000/test)
if echo "$WEBHOOK_RESPONSE" | grep -q "Webhook server is running"; then
    print_status 0 "Webhook endpoint is working"
    echo "   Response: $WEBHOOK_RESPONSE"
else
    print_status 1 "Webhook endpoint is not working"
fi

# Test 3: Check if MinIO buckets exist
echo ""
echo "🔍 Checking MinIO Buckets..."

# Check if mc is installed
if command -v mc &> /dev/null; then
    # Configure mc if not already configured
    mc alias set local http://localhost:9000 minioadmin minioadmin > /dev/null 2>&1
    
    # Check testing-files bucket
    if mc ls local/testing-files > /dev/null 2>&1; then
        print_status 0 "testing-files bucket exists"
    else
        print_status 1 "testing-files bucket does not exist"
        echo -e "${YELLOW}   Run: mc mb local/testing-files${NC}"
    fi
    
    # Check compressed-files bucket
    if mc ls local/compressed-files > /dev/null 2>&1; then
        print_status 0 "compressed-files bucket exists"
    else
        print_status 1 "compressed-files bucket does not exist"
        echo -e "${YELLOW}   Run: mc mb local/compressed-files${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  MinIO Client (mc) not installed. Install it to test buckets.${NC}"
    echo "   macOS: brew install minio/stable/mc"
    echo "   Linux: wget https://dl.min.io/client/mc/release/linux-amd64/mc"
fi

# Test 4: Manual DAG trigger test
echo ""
echo "🔍 Testing Manual DAG Trigger..."

# Create a test file
echo "This is a test file for compression testing. $(date)" > test_file.txt

# Upload to MinIO if mc is available
if command -v mc &> /dev/null; then
    mc cp test_file.txt local/testing-files/ > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_status 0 "Test file uploaded to MinIO"
    else
        print_status 1 "Failed to upload test file to MinIO"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping MinIO upload test (mc not available)${NC}"
fi

# Test manual DAG trigger
TRIGGER_RESPONSE=$(curl -s -X POST http://localhost:5000/trigger-dag \
  -H 'Content-Type: application/json' \
  -d '{"object_name":"test_file.txt"}')

if echo "$TRIGGER_RESPONSE" | grep -q "DAG triggered successfully"; then
    print_status 0 "Manual DAG trigger is working"
    echo "   Response: $TRIGGER_RESPONSE"
else
    print_status 1 "Manual DAG trigger failed"
    echo "   Response: $TRIGGER_RESPONSE"
fi

# Cleanup test file
rm -f test_file.txt

echo ""
echo "🎯 Test Summary:"
echo "================"
echo "• Services should be running (MinIO, Airflow, Webhook)"
echo "• Webhook endpoint should be accessible"
echo "• MinIO buckets should be created"
echo "• Manual DAG trigger should work"
echo ""
echo "📋 Next Steps:"
echo "=============="
echo "1. Create MinIO buckets if they don't exist:"
echo "   mc mb local/testing-files"
echo "   mc mb local/compressed-files"
echo ""
echo "2. Upload a file to test the full pipeline:"
echo "   echo 'Hello World' > test.txt"
echo "   mc cp test.txt local/testing-files/"
echo ""
echo "3. Check Airflow UI for DAG runs:"
echo "   http://localhost:8080"
echo ""
echo "4. Check compressed files in MinIO:"
echo "   mc ls local/compressed-files/"
echo ""
echo "5. Check email notifications (currently logged to console)"
echo "" 