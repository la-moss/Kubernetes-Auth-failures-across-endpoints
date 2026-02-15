CLUSTER_NAME ?= incident-lab

.PHONY: up down \
	start deploy deploy-dev deploy-prod deploy-ch1 deploy-ch2 deploy-ch3 \
	verify-ready verify verify-ch1 verify-ch2 verify-ch3

up:
	kind create cluster --name $(CLUSTER_NAME) --config kind/kind-config.yaml

down:
	kind delete cluster --name $(CLUSTER_NAME)

start: up deploy verify-ready

deploy: deploy-ch1

deploy-dev:
	kubectl apply -k manifests/overlays/dev

deploy-prod:
	kubectl apply -k manifests/overlays/prod

deploy-ch1:
	kubectl apply -k manifests/overlays/challenge1
	kubectl -n incident-lab rollout restart deploy/papi

deploy-ch2:
	kubectl apply -k manifests/overlays/challenge2
	kubectl -n incident-lab rollout restart deploy/papi

deploy-ch3:
	kubectl apply -k manifests/overlays/challenge3
	kubectl -n incident-lab rollout restart deploy/papi

verify-ready:
	kubectl -n incident-lab rollout status deploy/sobrain --timeout=180s
	kubectl -n incident-lab rollout status deploy/papi --timeout=180s

verify:
	VERIFY_PROFILE=profile1 bash scripts/verify/verify.sh

verify-ch1:
	VERIFY_PROFILE=profile1 bash scripts/verify/verify.sh

verify-ch2:
	VERIFY_PROFILE=profile2 PROFILE2_MIN_SUCCESS_RATE=95 bash scripts/verify/verify.sh

verify-ch3:
	VERIFY_PROFILE=profile3 PROFILE3_MAX_AVG_LATENCY_MS=1300 bash scripts/verify/verify.sh
