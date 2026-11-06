#!/bin/bash

pkill -f "port-forward svc/argocd-server" 2>/dev/null || true
k3d cluster delete tcharpen
