# Homebridge Migration to Kubernetes

This document outlines the steps to migrate the homebridge configuration from Docker to Kubernetes.

## Prerequisites

1. The homebridge deployment uses `hostNetwork: true` to ensure mDNS/Bonjour discovery works properly
2. A LoadBalancer service with IP `192.168.2.10` is configured for external access
3. The configuration is stored in a Longhorn PVC

## Migration Steps

### 1. Copy Configuration Data

Before applying the manifests, copy the existing homebridge configuration:

```bash
# Create a temporary pod to copy data
kubectl apply -f kubernetes/homebridge/namespace.yaml
kubectl apply -f kubernetes/homebridge/pvc.yaml

# Wait for PVC to be bound
kubectl wait --for=condition=Bound pvc/homebridge-config -n homebridge --timeout=60s

# Create a temporary pod to copy data
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: homebridge-data-copy
  namespace: homebridge
spec:
  containers:
  - name: copy
    image: busybox
    command: ['sleep', '3600']
    volumeMounts:
    - name: config
      mountPath: /homebridge
  volumes:
  - name: config
    persistentVolumeClaim:
      claimName: homebridge-config
EOF

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/homebridge-data-copy -n homebridge --timeout=60s

# Copy the configuration
kubectl cp /home/matt/homebridge/. homebridge/homebridge-data-copy:/homebridge/ -c copy

# Verify the copy
kubectl exec -n homebridge homebridge-data-copy -- ls -la /homebridge/

# Clean up the temporary pod
kubectl delete pod homebridge-data-copy -n homebridge
```

### 2. Apply Kubernetes Manifests

```bash
kubectl apply -k kubernetes/homebridge/
```

### 3. Verify Deployment

```bash
# Check pod status
kubectl get pods -n homebridge

# Check service and LoadBalancer IP
kubectl get svc -n homebridge

# View logs
kubectl logs -n homebridge -l app=homebridge -f

# Test the service
curl http://192.168.2.10:8581
```

### 4. Update Homepage

Update the homepage configuration to point to the new IP address `192.168.2.10:8581`.

### 5. Remove Docker Service

Once verified working, remove the homebridge service from `compose/docker-compose.yml` and restart docker-compose.

## Troubleshooting

- If mDNS/Bonjour discovery doesn't work, ensure `hostNetwork: true` is set
- Check that the LoadBalancer IP is properly assigned: `kubectl get svc -n homebridge`
- Verify configuration was copied correctly: `kubectl exec -n homebridge -it <pod-name> -- ls -la /homebridge/`
