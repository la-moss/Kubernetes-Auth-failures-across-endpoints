# First-Timer Setup Guide

Use this guide if this is your first time running Kind or Kubernetes locally.

## What you are setting up

- A local Kubernetes cluster (Kind)
- `kubectl` access to that cluster
- This challenge repo running inside the cluster

## 1) Install prerequisites

Required:

- Docker Desktop (or another supported container runtime)
- `kind`
- `kubectl`
- `curl`
- At least 6 GB RAM available to Docker (8 GB recommended)

On macOS (Homebrew):

```bash
brew install kind kubectl
```

Check tools:

```bash
docker --version
kind version
kubectl version --client
curl --version
```

Pre-flight checks (important):

```bash
docker info
docker context ls
kind version
kubectl version --client
```

If `docker info` fails, start Docker Desktop before continuing.

## 2) Start Docker first

Kind uses containers as Kubernetes nodes.  
If Docker is not running, cluster creation will fail.

## 3) Create the cluster

From this repository root:

```bash
make up
```

Confirm cluster access:

```bash
kubectl cluster-info
kubectl get nodes
```

## 4) Run your first challenge

```bash
make start
make verify-ch1
```

If verification fails, that is expected for this game.  
Investigate, edit manifests, redeploy, and re-run verification.

## 5) Daily workflow

```bash
make deploy-ch1 && make verify-ch1
make deploy-ch2 && make verify-ch2
make deploy-ch3 && make verify-ch3
```

Notes:

- Always run deploy before verify for the same challenge.
- If you switch challenges, deploy that challenge again first.
- If results seem stale, re-run deploy + verify for that challenge.
- Quick health check:

```bash
kubectl -n incident-lab get pods
```

## 6) Cleanup

```bash
make down
```

Clean reset (recommended when stuck):

```bash
make down && make start
```

## Troubleshooting

- Cluster already exists: run `make down` then `make up`
- `kind: command not found`: ensure `kind` is installed and in your `PATH`
- `kubectl` cannot connect: check Docker is running, then re-run `make up`
- `failed to connect to docker.sock`: Docker daemon is not running; open Docker Desktop and wait until it is healthy
- Wrong Docker context: run `docker context use desktop-linux`, then retry
- Pods not ready: run `kubectl -n incident-lab get pods` and inspect logs

## Official Kind docs

Kind Quick Start:
https://kind.sigs.k8s.io/docs/user/quick-start/
