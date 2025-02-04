#!/usr/bin/env bash
#kubectl certificate approve --kubeconfig admin.kubeconfig $(kubectl get csr --kubeconfig admin.kubeconfig -o json | jq -r '.items | .[]  | select(.spec.username == "system:node:node02") | .metadata.name')

# List of worker nodes to approve
WORKER_NODE_NAMES=("CloudNode" "EdgeNode")

for NODE in "${WORKER_NODE_NAMES[@]}"; do
  CSR_NAME=$(kubectl get csr --kubeconfig admin.kubeconfig -o json | jq -r ".items | .[] | select(.spec.username == \"system:node:${NODE}\") | .metadata.name")
  
  if [ -n "$CSR_NAME" ]; then
    echo "Approving CSR for ${NODE}..."
    kubectl certificate approve --kubeconfig admin.kubeconfig "$CSR_NAME"
  else
    echo "No pending CSR found for ${NODE}."
  fi
done
