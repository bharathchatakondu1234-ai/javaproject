#!/bin/bash

# Enhanced Kubernetes Deployment and Testing Script
# This script deploys the Java application to Minikube and tests liveness/readiness probes

set -e

OUTPUT_LOG="minikube_deployment.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$OUTPUT_LOG"
}

log "============================================"
log "Minikube Deployment & Probe Testing Script"
log "============================================"
log ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    log "ERROR: kubectl is not installed"
    exit 1
fi

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    log "ERROR: minikube is not installed"
    exit 1
fi

# Ensure minikube is running
log "Checking minikube status..."
if ! minikube status | grep -q "Running"; then
    log "WARNING: Minikube not running. Starting..."
    minikube start
fi

log "✓ Minikube is running"
log ""

# Apply deployment
log "Applying deployment..."
kubectl apply -f /workspaces/javaproject/deployment.yaml | tee -a "$OUTPUT_LOG"
log ""

# Wait for pods to be ready
log "Waiting for pods to be ready (this may take a minute)..."
if kubectl wait --for=condition=ready pod -l app=java --timeout=300s 2>&1 | tee -a "$OUTPUT_LOG"; then
    log "✓ Pods are ready"
else
    log "WARNING: Pods did not become ready within timeout. Continuing anyway..."
fi

log ""

# Get pod status
log "Pod Status:"
kubectl get pods -l app=java -o wide | tee -a "$OUTPUT_LOG"
log ""

# Get service info
log "Service Information:"
kubectl get svc java-service | tee -a "$OUTPUT_LOG"
log ""

# Get the first pod name
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    log "ERROR: No pods found for app=java"
    exit 1
fi

log "Using pod: $POD_NAME"
log ""

# Additional wait for application to be fully ready
log "Waiting 15 seconds for application to fully start..."
sleep 15

# Test if application is responding
log "============================================"
log "Testing Application Endpoints"
log "============================================"
log ""

# Check if curl exists in container
if kubectl exec "$POD_NAME" -- which curl &> /dev/null; then
    log "Testing Liveness Probe Endpoint..."
    log "Command: curl -s http://localhost:8080/actuator/health/liveness"
    log "Response:"
    kubectl exec "$POD_NAME" -- curl -s http://localhost:8080/actuator/health/liveness | tee -a "$OUTPUT_LOG" || log "ERROR: Liveness probe request failed"
    log ""
    log ""
    
    log "Testing Readiness Probe Endpoint..."
    log "Command: curl -s http://localhost:8080/actuator/health/readiness"
    log "Response:"
    kubectl exec "$POD_NAME" -- curl -s http://localhost:8080/actuator/health/readiness | tee -a "$OUTPUT_LOG" || log "ERROR: Readiness probe request failed"
    log ""
    log ""
    
    log "Testing Main Health Endpoint..."
    log "Command: curl -s http://localhost:8080/actuator/health"
    log "Response:"
    kubectl exec "$POD_NAME" -- curl -s http://localhost:8080/actuator/health | tee -a "$OUTPUT_LOG" || log "ERROR: Health endpoint request failed"
    log ""
else
    log "WARNING: curl not found in container. Skipping endpoint tests."
fi

log ""
log "============================================"
log "Probe Configuration Details"
log "============================================"
log ""

log "Describing pod for probe information..."
kubectl describe pod "$POD_NAME" | grep -A 10 "Probes:\|Liveness probe\|Readiness probe" | tee -a "$OUTPUT_LOG"

log ""
log "============================================"
log "Service Testing"
log "============================================"
log ""

log "Getting Minikube service URL..."
SERVICE_URL=$(minikube service java-service --url 2>/dev/null || echo "")

if [ -n "$SERVICE_URL" ]; then
    log "Service URL: $SERVICE_URL"
    log "Testing service endpoint..."
    curl -s "$SERVICE_URL/actuator/health" | tee -a "$OUTPUT_LOG" || log "ERROR: Could not reach service"
else
    log "Note: Service URL could not be determined. Use 'minikube service java-service --url' to get it."
fi

log ""
log "============================================"
log "Deployment Complete!"
log "============================================"
log ""
log "Summary of what was deployed:"
log "  - Image: bharathchatakondu/java-app:latest"
log "  - Replicas: 2"
log "  - Service Type: NodePort (port 30005)"
log "  - Liveness Probe: /actuator/health/liveness (every 15 seconds after 30s delay)"
log "  - Readiness Probe: /actuator/health/readiness (every 10 seconds after 20s delay)"
log ""
log "Useful commands:"
log "  View pods:           kubectl get pods -l app=java -w"
log "  View logs:           kubectl logs <pod-name>"
log "  Describe pod:        kubectl describe pod <pod-name>"
log "  Port forward:        kubectl port-forward <pod-name> 8080:8080"
log "  Service URL:         minikube service java-service --url"
log ""
log "Log file saved to: $OUTPUT_LOG"
