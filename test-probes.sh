#!/bin/bash

# Manual Probe Testing Script
# Test liveness and readiness probes without full deployment

echo "==========================================="
echo "Kubernetes Probe Testing Script"
echo "==========================================="
echo ""

# Get all java app pods
PODS=$(kubectl get pods -l app=java -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo "❌ No pods found with label app=java"
    echo ""
    echo "Make sure to deploy first with:"
    echo "  ./deploy-to-minikube.sh"
    exit 1
fi

echo "Found pods:"
kubectl get pods -l app=java
echo ""

for POD in $PODS; do
    echo "============================================"
    echo "Testing Pod: $POD"
    echo "============================================"
    echo ""
    
    echo "📋 Pod Status:"
    kubectl get pod "$POD" -o wide
    echo ""
    
    echo "🔍 Pod Events (last 5):"
    kubectl describe pod "$POD" | tail -20
    echo ""
    
    echo "💓 Liveness Probe:"
    if kubectl exec "$POD" -- sh -c 'curl -s http://localhost:8080/actuator/health/liveness 2>/dev/null' 2>/dev/null; then
        echo "✓ Liveness probe endpoint responded"
    else
        echo "❌ Liveness probe endpoint failed"
    fi
    echo ""
    
    echo "✅ Readiness Probe:"
    if kubectl exec "$POD" -- sh -c 'curl -s http://localhost:8080/actuator/health/readiness 2>/dev/null' 2>/dev/null; then
        echo "✓ Readiness probe endpoint responded"
    else
        echo "❌ Readiness probe endpoint failed"
    fi
    echo ""
    
    echo "🏥 Overall Health:"
    if kubectl exec "$POD" -- sh -c 'curl -s http://localhost:8080/actuator/health 2>/dev/null' 2>/dev/null; then
        echo "✓ Health endpoint responded"
    else
        echo "❌ Health endpoint failed"
    fi
    echo ""
    
    echo "📊 Application Logs (last 50 lines):"
    kubectl logs "$POD" --tail=50
    echo ""
    echo ""
done

echo "============================================"
echo "Testing Probe Failure Recovery"
echo "============================================"
echo "To test if probes trigger container restart:"
echo ""
echo "1. Kill the Java process:"
echo "   kubectl exec <pod-name> -- pkill -9 java"
echo ""
echo "2. Watch the pod restart:"
echo "   kubectl get pods -l app=java -w"
echo ""
echo "3. You should see the pod's RESTART COUNT increase"
echo ""
