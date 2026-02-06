#!/usr/bin/env python3
import subprocess
import sys
import time

def run_cmd(cmd, description=""):
    print(f"{'='*60}")
    if description:
        print(f"Running: {description}")
    print(f"Command: {cmd}")
    print(f"{'='*60}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    output = result.stdout + result.stderr
    print(output)
    return result.returncode, output

# Apply deployment
run_cmd("kubectl apply -f /workspaces/javaproject/deployment.yaml", "Applying deployment")

# Wait a bit for pods to start
print("\nWaiting 20 seconds for pods to initialize...")
time.sleep(20)

# Check pods
run_cmd("kubectl get pods -l app=java -o wide", "Getting pod status")

# Check service
run_cmd("kubectl get svc java-service", "Getting service")

# Get pod name
returncode, output = run_cmd("kubectl get pods -l app=java -o jsonpath='{.items[0].metadata.name}'", "Getting first pod name")
pod_name = output.strip()

if pod_name:
    print(f"\nFound pod: {pod_name}")
    
    # Wait for pod to be ready (check if curl is available)
    print("\nWaiting for pod to be ready...")
    time.sleep(10)
    
    # Test liveness
    print("\n" + "="*60)
    print("Testing Liveness Probe")
    print("="*60)
    run_cmd(f"kubectl exec {pod_name} -- curl -v http://localhost:8080/actuator/health/liveness", "Liveness probe test")
    
    # Test readiness
    print("\n" + "="*60)
    print("Testing Readiness Probe")
    print("="*60)
    run_cmd(f"kubectl exec {pod_name} -- curl -v http://localhost:8080/actuator/health/readiness", "Readiness probe test")
    
    # Describe pod for probe details
    print("\n" + "="*60)
    print("Pod Details (Probe Info)")
    print("="*60)
    run_cmd(f"kubectl describe pod {pod_name}", "Pod description")
else:
    print("ERROR: No pods found!")

print("\n" + "="*60)
print("Deployment and Testing Complete")
print("="*60)
