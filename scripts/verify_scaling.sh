#!/bin/bash
# Script to verify K8s scaling by simulating load
echo "Verifying HPA status..."
kubectl get hpa swapi-backend-hpa

echo "Simulating load on backend..."
# Run a temporary pod to generate traffic
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://swapi-backend-service:8081; done" &

echo "Monitoring scaling behavior (Wait 2 minutes)..."
sleep 120

echo "Current replica count:"
kubectl get deployment swapi-backend

# Clean up
pkill -f wget
