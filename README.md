# Inception of Things

Inception of Things is a 42 school team project where we discover Kubernetes, container orchestration and self-hosted infrastructure by setting up local clusters using K3d/K3s, Vagrant and Argo CD.

## Status

* Success
* Grade: 125/100

## Rules

### Part 1: K3s with Vagrant

We have to set up two virtual machines with **Vagrant** and **VirtualBox**, a **K3s server node** and a **K3s agent node**. The agent node has to be connected to the server node using a shared token.

### Part 2: K3s and three simple applications

We have to set up a **K3s server node** with **Vagrant** and **VirtualBox**. We must deploy **three different web applications** into the cluster using standard Kubernetes manifests (**Deployments** and **Services**) and **Ingress** controller to route external traffic to the correct applications based on hostnames or paths. We will configure **App 1** to run with **1 replica**, **App 2** to run with **3 replicas** and **App 3** as the **default fallback application**.

### Part 3 (with bonus): K3d with Argo CD and Local GitLab

We have to set up a continuous delivery workflow using **Argo CD** to automatically synchronize the deployment of the **wil-playground** application with an **internal local GitLab instance**.

## Usage

### Part 1: K3s with Vagrant

Create a ```.env``` file with a ```K3S_TOKEN``` key and use ```vagrant up``` to set up the cluster.

Use ```vagrant destroy -f``` to clean the cluster.

### Part 2: K3s and three simple applications

You only have to use ```vagrant up``` to set up the cluster.

Use ```vagrant destroy -f``` to clean the cluster.

### Part 3 (with bonus): K3d with Argo CD and Local GitLab

* Run ```install.sh``` to install all requirements.
* Run ```setup.sh``` to set up the cluster.
* Run ```clean.sh``` to clean the cluster.
***
Made by:
* Ismérie George: [@Ismerie](https://github.com/Ismerie) <ismerie.george@gmail.com>
* Thibaut Charpentier: <thibaut.charpentier42@gmail.com>
