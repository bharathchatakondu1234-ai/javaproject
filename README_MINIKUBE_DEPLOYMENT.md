# Kubernetes Deployment with Minikube - Complete Guide

## 📋 Overview

Your Spring Boot Java application is now configured for deployment to Minikube with:
- ✅ **Liveness Probes** - Monitor if container should be restarted
- ✅ **Readiness Probes** - Monitor if container can receive traffic
- ✅ **Multi-replica deployment** - 2 pods for high availability
- ✅ **NodePort Service** - External access to application

## 🚀 Quick Start

### Prerequisites
```bash
# Install Docker (for Minikube)
# Install kubectl
# Install Minikube
```

### Deploy in One Command
```bash
./deploy-to-minikube.sh
```

This comprehensive script will:
1. Start Minikube
2. Apply the deployment
3. Wait for pods to be ready
4. Test all health endpoints
5. Display probe information
6. Generate a log file

### Test Probes Anytime
```bash
./test-probes.sh
```

## 📁 Files Created

| File | Purpose |
|------|---------|
| `deploy-to-minikube.sh` | Complete deployment and testing automation |
| `test-probes.sh` | On-demand probe and health testing |
| `DEPLOYMENT_GUIDE.md` | Manual step-by-step deployment guide |
| `deployment.yaml` | Updated with your Docker Hub username |

## 🔧 Configuration Details

### Deployment Configuration

**Image:** `bharathchatakondu/java-app:latest`
**Replicas:** 2  
**Service Type:** NodePort (Port 30005)

### Liveness Probe
- **Endpoint:** `GET /actuator/health/liveness`
- **Port:** 8080
- **Initial Delay:** 30 seconds (time to start)
- **Period:** 15 seconds (check interval)
- **Failure Threshold:** 3 failures
- **Purpose:** Restart dead containers

### Readiness Probe
- **Endpoint:** `GET /actuator/health/readiness`
- **Port:** 8080
- **Initial Delay:** 20 seconds (time to startup)
- **Period:** 10 seconds (check interval)
- **Failure Threshold:** 3 failures
- **Purpose:** Control traffic to pod

## 📊 Manual Deployment Steps

If you prefer to run commands manually:

### 1. Start Minikube
```bash
minikube start
```

### 2. Apply Deployment
```bash
kubectl apply -f deployment.yaml
```

### 3. Monitor Pods
```bash
kubectl get pods -l app=java -w
```

### 4. Wait for Ready
```bash
kubectl wait --for=condition=ready pod -l app=java --timeout=300s
```

### 5. Get Pod Name
```bash
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}')
```

### 6. Test Liveness Probe
```bash
kubectl exec $POD_NAME -- curl http://localhost:8080/actuator/health/liveness
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### 7. Test Readiness Probe
```bash
kubectl exec $POD_NAME -- curl http://localhost:8080/actuator/health/readiness
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

### 8. View Pod Details & Probe History
```bash
kubectl describe pod $POD_NAME
```

Look for sections marked:
- `Liveness probe:`
- `Readiness probe:`
- `Events:`

### 9. View Service
```bash
kubectl get svc java-service
```

### 10. Access via Minikube
```bash
# Get service URL
minikube service java-service --url

# Test via service
curl $(minikube service java-service --url)/actuator/health
```

## 🧪 Testing Probe Behavior

### Test 1: Normal Operation
Your probes should show:
- Status: `UP`
- All pods in `Running` state
- `READY 1/1` for each pod

### Test 2: Simulate Pod Failure
Kill the Java process and watch the pod restart:

```bash
# Kill the application
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- pkill -9 java

# Watch pod restart (should restart automatically)
kubectl get pods -l app=java -w

# Check restart count
kubectl get pods -l app=java -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}'
```

**Expected Behavior:**
- Liveness probe fails → Container restarts
- Readiness probe fails → Pod removed from service load balancing
- `RESTART COUNT` should increase
- Pod should become healthy again

### Test 3: Check Probe Logs
```bash
kubectl describe pod $POD_NAME | grep -A 20 "Events:"
```

You should see events like:
```
Liveness probe succeeded
Readiness probe succeeded
```

## 📈 Monitoring & Debugging

### View Logs
```bash
# Real-time logs
kubectl logs $POD_NAME -f

# Last 100 lines
kubectl logs $POD_NAME --tail=100

# All pods
kubectl logs -l app=java
```

### Port Forward for Direct Testing
```bash
# Forward local 8080 to pod 8080
kubectl port-forward $POD_NAME 8080:8080

# Then in another terminal
curl http://localhost:8080/actuator/health
```

### Check Events
```bash
# Pod-specific events
kubectl describe pod $POD_NAME

# All events
kubectl get events --sort-by='.lastTimestamp'
```

### Debug Container
```bash
# Shell into container
kubectl exec -it $POD_NAME -- /bin/bash

# Run diagnostics inside
kubectl exec $POD_NAME -- ps aux
kubectl exec $POD_NAME -- netstat -tuln
```

## 🛠️ Troubleshooting

### Pods Not Starting

**Check pod status:**
```bash
kubectl describe pod <pod-name>
```

**Common issues:**
- Image not found → Check Docker Hub username in deployment.yaml
- Insufficient resources → Check minikube has enough memory
- Network issues → Check if minikube can reach Docker Hub

### Probes Not Responding

**Verify endpoints exist:**
```bash
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- curl -v http://localhost:8080/actuator/health
```

**Check application logs:**
```bash
kubectl logs $POD_NAME | tail -50
```

### Image Pull Failures

**Solution 1: Load image into Minikube**
```bash
minikube image load bharathchatakondu/java-app:latest
```

**Solution 2: Use Always ImagePull Policy**
Edit `deployment.yaml` and add:
```yaml
spec:
  containers:
  - name: java-container
    image: bharathchatakondu/java-app:latest
    imagePullPolicy: Always
```

## 📞 Support

For more information:
- [Spring Boot Actuator Docs](https://spring.io/guides/gs/actuator-service/)
- [Kubernetes Probes Docs](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Minikube Docs](https://minikube.sigs.k8s.io/)

## ✅ Verification Checklist

- [ ] Docker image pushed to Docker Hub: `bharathchatakondu/java-app:latest`
- [ ] Minikube running: `minikube status`
- [ ] Pods deployed: `kubectl get pods -l app=java`
- [ ] Pods ready: `kubectl get pods -l app=java | grep 1/1`
- [ ] Service created: `kubectl get svc java-service`
- [ ] Liveness probe responds: `kubectl exec <pod> -- curl http://localhost:8080/actuator/health/liveness`
- [ ] Readiness probe responds: `kubectl exec <pod> -- curl http://localhost:8080/actuator/health/readiness`
- [ ] Service accessible: `curl $(minikube service java-service --url)/actuator/health`

---

**Ready to deploy? Run:**
```bash
./deploy-to-minikube.sh
```
