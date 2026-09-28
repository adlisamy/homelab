# Platform GitOps

This directory is the hand-off point between imperative bootstrap and
continuous reconciliation.

- Ansible (and k3s) stop at the cluster runtime and the one-time Argo CD
  install. See `infra/ansible/playbooks/platform-bootstrap.yaml` and
  `infra/ansible/roles/argocd_bootstrap/tasks/main.yaml`.
- Everything after that - CRDs, operators, platform services, application
  manifests - is reconciled by Argo CD **from Git**, not pushed by Ansible.

## Layout

```
platform/gitops/
  root-app.yaml          # app-of-apps root; the only object applied by hand
  apps/                  # one Argo CD Application per platform area
    gateway-api.yaml     # Gateway API CRDs (cluster-scoped)
    cert-manager.yaml    # operator, from the upstream Helm chart
    monitoring.yaml      # Prometheus + Grafana, from kube-prometheus-stack
    traefik.yaml         # ingress + Gateway API controller (Helm chart)
    security.yaml        # -> platform/security  (ClusterIssuers / TLS)
    gateways.yaml        # -> apps/gateways      (Gateway / HTTPRoute)

platform/ingress/        # Traefik routing config (TLSOption, Middleware)
platform/security/       # cert-manager configuration (ClusterIssuer)
apps/gateways/           # Gateway API objects for applications
```

The split follows the repository's existing directory intent: Ansible remains
under `infra/`, in-cluster platform services under `platform/`, and workloads
under `apps/`.

## Why an app-of-apps

`root-app.yaml` points Argo CD at `platform/gitops/apps/`; each file there is
an `Application` for one area. Adding a platform service is therefore a Git
change (a new file plus its manifests), never an Ansible task. `sync-wave`
annotations order the roll-out: operators first (`0`), then their CRDs'
consumers (`1`), then Gateway API routes (`2`).

## Prerequisites before the first sync

1. **A Git remote Argo CD can reach.** The manifests point at
   `git@github.com:adlisamy/homelab.git` (SSH), branch `main`. If the repo
   moves, change it in `root-app.yaml` and under `apps/`:

   ```sh
   REPO_URL=git@github.com:<org>/<repo>.git
   grep -rl 'adlisamy/homelab' platform/gitops | xargs sed -i "s#git@github.com:adlisamy/homelab.git#${REPO_URL}#"
   ```

2. **Repository credential.** The repository is private, so Argo CD
   authenticates with an SSH deploy key:

   - the public half of `~/.ssh/argocd_homelab_deploy.pub` is added to the
     repository as a **read-only deploy key**;
   - the private half lives in the `repo-homelab` Secret in the `argocd`
     namespace, labelled `argocd.argoproj.io/secret-type=repository`:

     ```sh
     kubectl -n argocd create secret generic repo-homelab \
       --from-literal=type=git \
       --from-literal=url=git@github.com:adlisamy/homelab.git \
       --from-file=sshPrivateKey=$HOME/.ssh/argocd_homelab_deploy
     kubectl -n argocd label secret repo-homelab argocd.argoproj.io/secret-type=repository
     ```

   The private key is never committed (it lives outside the repository), and
   `ssh_known_hosts` is unnecessary because Argo CD's repo-server already
   bundles GitHub's host keys.

3. **The commit pushed to that branch.** Argo CD reads `targetRevision: main`,
   so the manifests above must exist on `main`.

## Bootstrap

Apply the root application once, from a host with cluster-admin access:

```sh
kubectl apply -f platform/gitops/root-app.yaml
```

Argo CD then creates `gateway-api`, `cert-manager`, `monitoring`, `traefik`,
`platform-security` and `platform-gateways` itself, and keeps them in sync.

## Verifying without applying

Every manifest here is a plain Kubernetes object. Validate against the live
cluster with a server-side dry run:

```sh
kubectl apply --dry-run=server -f platform/gitops/root-app.yaml
kubectl apply --dry-run=server -f platform/gitops/apps/
kubectl apply --dry-run=server -f apps/gateways/
```

## Ingress controller ownership

Traefik is **not** a k3s addon here. `traefik.yaml` installs the upstream
chart with Argo CD, and the addon is disabled in
`infra/ansible/roles/k3s_server/tasks/main.yaml`. Two Helm releases must never
manage the same ingress resources, so ownership changes hands exactly once and
the order matters:

1. Publish the repo and confirm the `traefik` Application renders (the k3s
   addon is still serving traffic at this point).
2. Apply the Ansible `disable: traefik` change and restart `k3s-server`. k3s
   uninstalls its `traefik` and `traefik-crd` releases; ingress is down.
3. Sync the `traefik` Application: it installs the controller, the
   `IngressClass`/`GatewayClass` named `traefik`, and the CRDs
   (the chart's `crds/` directory, applied by Argo CD via `--include-crds`).

Do steps 2 and 3 inside a maintenance window - the gap between them is real
downtime for every Ingress. See `docs/runbooks/gitops-bootstrap.md` for the
exact commands.

## What is deliberately not here yet

- `platform/observability/`, `platform/storage/`, `platform/rbac/` and
  `platform/ingress/` do not yet contain manifests reconciled from those paths.
  Monitoring is installed directly from its upstream chart by
  `apps/monitoring.yaml`; add a path-based `Application` alongside local
  manifests when a platform area needs them.
- No Argo CD `ApplicationSet` and no repository credentials: the platform set
  is small enough that explicit Applications are easier to reason about.

## Accessing monitoring

The Prometheus and Grafana Services are kept internal to the cluster. To open
Grafana locally, use:

```sh
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Then open `http://localhost:3000`. Grafana's admin password is stored in the
`kube-prometheus-stack-grafana` Secret in the `monitoring` namespace. Prometheus
can be reached locally with:

```sh
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090
```
