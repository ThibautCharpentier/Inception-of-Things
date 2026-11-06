#!/bin/bash

# Meme chose que p3, mais Argo CD lit le repo dans un GitLab local
# qui tourne dans le cluster (namespace gitlab) au lieu de GitHub.

set -e

CLUSTER="tcharpen"
CONFS="$(cd "$(dirname "$0")/../confs" && pwd)"
ARGOCD_MANIFEST="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
GITLAB_LOCAL="localhost:8181"
GITLAB_INTERN="gitlab-service.gitlab.svc.cluster.local:8181"
REPO="root/igeorge-iot-argocd.git"

if ! docker info >/dev/null 2>&1; then
    echo "ERREUR : Docker n'est pas accessible. Lance scripts/install.sh."
    exit 1
fi

echo "==> Cluster K3d '${CLUSTER}'"
if k3d cluster list | grep -q "^${CLUSTER} "; then
    echo "Le cluster existe deja."
else
    k3d cluster create "${CLUSTER}" -p "8888:8888@loadbalancer" -p "8181:8181@loadbalancer" --wait
fi
kubectl config use-context "k3d-${CLUSTER}"

echo "==> Namespaces"
kubectl apply -f "${CONFS}/namespaces.yaml"

echo "==> GitLab"
if ! kubectl get secret gitlab-root-password -n gitlab >/dev/null 2>&1; then
    kubectl create secret generic gitlab-root-password -n gitlab \
        --from-literal=password="$(openssl rand -hex 16)"
fi
GITLAB_PASSWORD=$(kubectl get secret gitlab-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d)
kubectl apply -f "${CONFS}/gitlab.yaml"

echo "==> Argo CD"
kubectl apply -n argocd --server-side --force-conflicts -f "${ARGOCD_MANIFEST}"
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s

echo "==> Attente de GitLab"
TIMEOUT=900
ELAPSED=0
until curl -sf -o /dev/null "http://${GITLAB_LOCAL}/users/sign_in"; do
    sleep 10
    ELAPSED=$((ELAPSED + 10))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERREUR : GitLab n'a pas demarre apres ${TIMEOUT}s"
        echo "Regarde les logs : kubectl logs -n gitlab deploy/gitlab"
        exit 1
    fi
done

echo "==> Push de l'application dans GitLab"
TMP=$(mktemp -d)
cp "${CONFS}/app/deployment.yaml" "${CONFS}/app/service.yaml" "${TMP}/"
cd "${TMP}"
git init -q -b main
git add .
git -c user.name="tcharpen" -c user.email="tcharpen@student.42.fr" commit -q -m "v1"
if ! git push -q "http://root:${GITLAB_PASSWORD}@${GITLAB_LOCAL}/${REPO}" main 2>/dev/null; then
    echo "Le repo existe deja dans GitLab, on le garde tel quel."
fi
cd - >/dev/null
rm -rf "${TMP}"

echo "==> Acces d'Argo CD au repo GitLab"
kubectl apply -f - <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://${GITLAB_INTERN}/${REPO}
  username: root
  password: ${GITLAB_PASSWORD}
YAML

echo "==> Application Argo CD"
kubectl apply -f "${CONFS}/application.yaml"

TIMEOUT=180
ELAPSED=0
until kubectl get deployment wil-playground -n dev >/dev/null 2>&1; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERREUR : Argo CD n'a pas deploye l'application apres ${TIMEOUT}s"
        echo "Verifie l'URL du repo dans confs/application.yaml"
        exit 1
    fi
done
kubectl rollout status deployment/wil-playground -n dev --timeout="${TIMEOUT}s"

echo "==> Interface Argo CD sur https://localhost:8080"
pkill -f "port-forward svc/argocd-server" 2>/dev/null || true
nohup kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "Tout est pret."
echo "  Application : curl http://localhost:8888/"
echo "  GitLab      : http://localhost:8181  (user: root / mot de passe: ${GITLAB_PASSWORD})"
echo "  Repo        : http://localhost:8181/${REPO}"
echo "  Argo CD     : https://localhost:8080  (user: admin / mot de passe: ${ARGOCD_PASSWORD})"
