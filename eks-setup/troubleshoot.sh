#!/bin/bash

echo "=== Lumiatech Kubernetes Troubleshooting Script ==="
echo ""

# Check namespace
echo "1. Checking namespace..."
kubectl get ns | grep lumiatech
echo ""

# Check all resources in lumiatech namespace
echo "2. All resources in lumiatech namespace:"
kubectl get all -n lumiatech
echo ""

# Check pods with more details
echo "3. Pod status with details:"
kubectl get pods -n lumiatech -o wide
echo ""

# Check pending pods specifically
echo "4. Describing pending pods:"
PENDING_PODS=$(kubectl get pods -n lumiatech --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}')
if [ ! -z "$PENDING_PODS" ]; then
    for pod in $PENDING_PODS; do
        echo "--- Describing pod: $pod ---"
        kubectl describe pod $pod -n lumiatech
        echo ""
    done
else
    echo "No pending pods found"
fi
echo ""

# Check PVC status
echo "5. Persistent Volume Claims:"
kubectl get pvc -n lumiatech
echo ""

# Describe PVC if exists
echo "6. Describing PVC:"
kubectl describe pvc db-pv-claim -n lumiatech 2>/dev/null || echo "PVC db-pv-claim not found"
echo ""

# Check storage classes
echo "7. Available Storage Classes:"
kubectl get storageclass
echo ""

# Check services
echo "8. Services:"
kubectl get svc -n lumiatech
kubectl get svc -n ingress-nginx
echo ""

# Check ingress
echo "9. Ingress configuration:"
kubectl get ingress -n lumiatech
echo ""

# Describe ingress
echo "10. Ingress details:"
kubectl describe ingress lumia-ingress -n lumiatech 2>/dev/null || echo "Ingress lumia-ingress not found"
echo ""

# Check ingress controller
echo "11. Ingress Controller status:"
kubectl get pods -n ingress-nginx
echo ""

# Get ingress controller service
echo "12. Ingress Controller Service:"
kubectl get svc -n ingress-nginx ingress-nginx-controller
echo ""

# Check events
echo "13. Recent events in lumiatech namespace:"
kubectl get events -n lumiatech --sort-by='.lastTimestamp' | tail -20
echo ""

# Check node resources
echo "14. Node resources:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
echo ""

# Check if images can be pulled
echo "15. Checking image pull status:"
kubectl get pods -n lumiatech -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].state}{"\n"}{end}' 2>/dev/null || echo "No pods with container status found"
echo ""

echo "=== Troubleshooting Complete ==="
echo ""
echo "Common fixes:"
echo "1. For pending pods: Check PVC, storage class, and node resources"
echo "2. For ingress issues: Verify ingress controller and DNS/hosts file"
echo "3. For image issues: Check image names and registry access"