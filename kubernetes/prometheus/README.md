# Prometheus on K3s

This directory contains Kubernetes manifests for a plain Prometheus server, matching the style used for Grafana and Loki in this repo.

## Contents
- `_namespace.yaml`: Namespace `prometheus`
- `rbac.yaml`: ServiceAccount, ClusterRole, ClusterRoleBinding for K8s discovery
- `configmap.yaml`: Prometheus configuration (`prometheus.yml`)
- `deployment.yaml`: Prometheus Deployment and persistent volume claim
- `service.yaml`: LoadBalancer Service (port 9090)
- `ingress.yaml`: Traefik IngressRoute for HTTPS access
- `default-headers.yaml`: Traefik middleware for security headers

## Apply
You can apply everything at once (safe to run multiple times):

```bash
kubectl apply -f .
```

Validate first without making changes:

```bash
kubectl apply --dry-run=client -f .
```

## Notes
- Service uses `loadBalancerIP: 192.168.2.134` as a placeholder; adjust to your MetalLB range.
- Ingress host is `prometheus.tehmatt.com` and TLS secret `tehmatt-tls`; change to your domain/cert.
- Prometheus auto-discovers targets annotated with `prometheus.io/scrape: "true"`.
- To reload config without restart:

```bash
kubectl -n prometheus exec deploy/prometheus -- curl -X POST http://localhost:9090/-/reload
```
