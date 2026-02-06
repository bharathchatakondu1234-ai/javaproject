# Minikube Deployment & Testing Guide

## Summary
I've configured your Spring Boot application for deployment to Minikube with liveness and readiness probes.

## What I've Done

### 1. Updated Deployment Configuration
- Updated `deployment.yaml` with your Docker Hub username: `bharathchatakondu`
- Configured two replicas for the Java application
- Service is exposed as NodePort on port 30005

### 2. Health Probes Configuration
Your deployment includes both probes using Spring Boot Actuator endpoints:

**Liveness Probe:**
- Endpoint: `/actuator/health/liveness`
- Port: 8080
- Initial Delay: 30 seconds
- Period: 15 seconds
- Purpose: Determines if container should be restarted

**Readiness Probe:**
- Endpoint: `/actuator/health/readiness`
- Port: 8080
- Initial Delay: 20 seconds
- Period: 10 seconds
- Purpose: Determines if container can receive traffic

## How to Deploy and Test

### Step 1: Verify Minikube is Running
```bash
minikube status
```

### Step 2: Load Image into Minikube (optional)
If the image doesn't exist on Docker Hub yet:
```bash
minikube image load bharathchatakondu/java-app:latest
```

Or set imagePullPolicy to Always to pull from Docker Hub.

### Step 3: Apply Deployment
```bash
kubectl apply -f deployment.yaml
```

### Step 4: Watch the Pods Start
```bash
kubectl get pods -l app=java -w
```

### Step 5: Check Pod Status
```bash
kubectl get pods -l app=java -o wide
```

### Step 6: Get Pod Name
```bash
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}')
echo $POD_NAME
```

### Step 7: Test Liveness Probe Endpoint
```bash
kubectl exec $POD_NAME -- curl -v http://localhost:8080/actuator/health/liveness
```

Expected response: `{"status":"UP"}`

### Step 8: Test Readiness Probe Endpoint
```bash
kubectl exec $POD_NAME -- curl -v http://localhost:8080/actuator/health/readiness
```

Expected response: `{"status":"UP"}`

### Step 9: View Probe History in Pod Description
```bash
kubectl describe pod $POD_NAME
```

Look for sections like:
- `Liveness probe information`
- `Readiness probe information`

### Step 10: Check Service and Get Minikube Service URL
```bash
minikube service java-service --url
```

### Step 11: Manually Test the Service
```bash
curl $(minikube service java-service --url)/actuator/health
```

## Testing Probe Failures (Advanced)

To test if probes work correctly, you can simulate a failure:

### Stop the application to trigger probe failures:
```bash
POD_NAME=$(kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- pkill -9 java
```

Then watch the pod restart:
```bash
kubectl get pods -l app=java -w
```

## Key Files

- [deployment.yaml](deployment.yaml) - Kubernetes deployment manifest with probes
- [pom.xml](pom.xml) - Maven configuration with Spring Boot Actuator
- [dockerfile](dockerfile) - Multistage Docker build

## Important Notes

1. The application uses Spring Boot Actuator for health endpoints
2. The Actuator endpoints are automatically exposed at `/actuator/health/liveness` and `/actuator/health/readiness`
3. Docker image must be pushed to Docker Hub first: `bharathchatakondu/java-app:latest`
4. Minikube needs to be able to reach Docker Hub to pull the image
5. Use `kubectl logs <pod-name>` to see application logs if deployment fails

## Troubleshooting

If pods don't start:
```bash
# Check pod status and events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check if image can be pulled
kubectl get events
```

## Next Steps

1. Make sure your Docker image is available at: `bharathchatakondu/java-app:latest`
2. Run the kubectl commands above to deploy and test
3. Monitor probe activity and pod restarts
