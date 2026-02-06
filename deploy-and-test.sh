#!/bin/bash
set -e

echo "=== Starting deployment to minikube ==="

# Apply deployment
echo "Applying deployment..."
kubectl apply -f /workspaces/javaproject/deployment.yaml

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=java --timeout=300s

# Get pod status
echo "Pod status:"
kubectl get pods -l app=java -o wide

# Get service info
echo "Service info:"
kubectl get svc java-service

# Get the service URL
echo "Getting service URL..."
SERVICE_URL=$(minikube service java-service --url 2>/dev/null || echo "URL not available")
echo "Service URL: $SERVICE_URL"

# Wait for application to be ready
echo "Waiting 10 seconds for application to fully start..."
sleep 10

# Test the probes
echo ""
echo "=== Testing Health Probes ==="

# Port forward to test
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo "No pods found"
    exit 1
fi

echo "Pod name: $POD_NAME"
echo ""

# Test liveness probe
echo "Testing liveness probe endpoint..."
kubectl exec $POD_NAME -- curl -s http://localhost:8080/actuator/health/liveness || echo "Liveness probe endpoint test failed"

echo ""

# Test readiness probe
echo "Testing readiness probe endpoint..."
kubectl exec $POD_NAME -- curl -s http://localhost:8080/actuator/health/readiness || echo "Readiness probe endpoint test failed"

echo ""

# Get probe events
echo "=== Probe Events ==="
kubectl describe pod $POD_NAME | grep -A 5 "Liveness\|Readiness" || echo "No probe info found"

echo ""
echo "=== Deployment Complete ==="
