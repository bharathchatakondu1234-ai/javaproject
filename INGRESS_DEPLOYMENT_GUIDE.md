# Kubernetes Ingress Feature Guide

## Overview
The Java application now includes a complete Kubernetes Ingress configuration for HTTP routing and load balancing. This feature allows external access to your application through a domain name instead of exposing ports directly.

## What Was Added

### 1. **Ingress Resource** (`ingress.yaml`)
- Created new ingress configuration for NGINX ingress controller
- Configured with two routes:
  - **Host-based routing**: `java-app.local`
  - **Default path-based routing**: `/` for wildcard access
- Automatic URL rewriting and SSL redirect disabled for simplicity

### 2. **Service Updated** (`deployment.yaml`)
- Changed Service type from `NodePort` to `ClusterIP`
- `ClusterIP` is the recommended service type for use with Ingress
- Port mapping: 80 (external) → 8080 (container)

## Deployment Prerequisites

Before deploying the Ingress, ensure your Kubernetes cluster has:

1. **NGINX Ingress Controller** installed:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

2. For **Minikube**, enable ingress addon:
```bash
minikube addons enable ingress
```

## Deployment Instructions

### Step 1: Deploy the Application
```bash
kubectl apply -f deployment.yaml
```

This deploys:
- Java application (2 replicas)
- ClusterIP service

### Step 2: Deploy the Ingress
```bash
kubectl apply -f ingress.yaml
```

### Step 3: Verify Deployment
```bash
# Check Ingress status
kubectl get ingress java-app-ingress

# Check Service
kubectl get svc java-service

# Check Pods
kubectl get pods -l app=java
```

## Accessing Your Application

### Local Development (Minikube)
1. Get the Minikube IP:
```bash
minikube ip
```

2. Add to your `/etc/hosts` file:
```
<minikube-ip> java-app.local
```

3. Access the application:
```bash
curl http://java-app.local
# or
curl http://<minikube-ip>
```

### Cloud Deployment
1. Get the Ingress external IP/hostname:
```bash
kubectl get ingress java-app-ingress -o wide
```

2. Use the external IP or hostname to access your application

## Docker Build Status
✅ Successfully built Docker image: `bharathchatakondu/java-app:latest`

The JAR artifact is available at:
- `/workspaces/javaproject/target/demo-0.0.1-SNAPSHOT.jar` (19MB)

## Architecture Benefits

1. **Load Balancing**: NGINX distributes traffic across 2 replicas
2. **Domain-based Access**: Access via `java-app.local` instead of IP:port
3. **Scalability**: Easy to scale replicas without changing external configuration
4. **URL Rewriting**: Automatic request path rewriting if needed
5. **Better Resource Utilization**: ClusterIP avoids port exposure on nodes

## Customization

To modify ingress rules, edit `ingress.yaml`:

- **Change hostname**: Modify `host: java-app.local` to your domain
- **Add more paths**: Add additional `path` entries under `http.paths`
- **Enable HTTPS**: Add TLS section with certificate reference
- **Add custom middleware**: Add annotations like `nginx.ingress.kubernetes.io/auth-type: basic`

## Monitoring

Check ingress controller logs:
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f
```

Check application logs:
```bash
kubectl logs -l app=java -f
```
