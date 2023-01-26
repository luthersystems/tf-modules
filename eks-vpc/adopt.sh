#!/bin/bash
set -euo pipefail

HELM_RELEASE_NAME=aws-vpc-cni

# don't import the crd. Helm cant manage the lifecycle of it anyway.
for kind in daemonSet clusterRole clusterRoleBinding serviceAccount; do
  echo "setting annotations and labels on $kind/aws-node"
  kubectl -n kube-system annotate --overwrite $kind aws-node meta.helm.sh/release-name="$HELM_RELEASE_NAME"
  kubectl -n kube-system annotate --overwrite $kind aws-node meta.helm.sh/release-namespace=kube-system
  kubectl -n kube-system label --overwrite $kind aws-node app.kubernetes.io/managed-by=Helm
done

kubectl -n kube-system annotate --overwrite crd eniconfigs.crd.k8s.amazonaws.com meta.helm.sh/release-name="$HELM_RELEASE_NAME"
kubectl -n kube-system annotate --overwrite crd eniconfigs.crd.k8s.amazonaws.com meta.helm.sh/release-namespace=kube-system
kubectl -n kube-system label --overwrite crd eniconfigs.crd.k8s.amazonaws.com app.kubernetes.io/managed-by=Helm


daemonSet clusterRole clusterRoleBinding serviceAccount


aws-ebs-csi-driver

CSI role arn

kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/master/aws-k8s-cni.yaml 