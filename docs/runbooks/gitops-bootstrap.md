# GitOps Bootstrap (Argo CD)

How platform services are installed **after** the one-time Argo CD bootstrap,
without Ansible. This is the procedure described in
`infra/ansible/playbooks/platform-bootstrap.yaml` and
`infra/ansible/roles/argocd_bootstrap/tasks/main.yaml`.

## Roles

| Layer | Installed by | Notes |
| --- | --- | --- |
| VMs, network, storage | Terraform | `infra/terraform/` |
| Node config, k3s runtime, CNI | Ansible | `infra/ansible/playbooks/site.yaml` |
| Argo CD | Ansible, **once** | `platform-bootstrap.yaml` |
| CRDs, operators, gateways, ingress, apps | **Argo CD from Git** | `platform/gitops/` |

Ansible's job ends at the Argo CD install. Running the platform playbook
again must not be used to push platform manifests.

## Current state

- Cluster: 3-node k3s, Argo CD `v3.5.3` in namespace `argocd`, all components
  healthy, no `Application` objects yet.
- Ingress: k3s ships Traefik as an addon (`IngressClass traefik`, default),
  deployed by the k3s `traefik` and `traefik-crd` HelmCharts in `kube-system`.
  It is *not* yet configured for Gateway API, and it is *not* yet owned by
  Argo CD.
- Those same k3s charts own the Gateway API CRDs and the `traefik.io` /
  `hub.traefik.io` CRDs. No `GatewayClass` exists until a Traefik with
  `providers.kubernetesGateway.enabled` is running.
- cert-manager is not installed.

## Procedure

Two constraints drive the order:

- **Ingress ownership changes hands exactly once.** The k3s `traefik` addon and
  the Argo CD `traefik` Application must never be installed at the same time,
  or two Helm releases fight over the same Deployment, Service and CRDs
  (`platform/gitops/apps/traefik.yaml`).
- **Argo CD must already be able to reach the repository** before the addon is
  removed, otherwise ingress stays down.

1. The repository is published at `https://github.com/adlisamy/homelab.git`
   (branch `main`). If it moves, update the `repoURL` in `root-app.yaml` and
   under `platform/gitops/apps/`. For a private remote, create the Argo CD
   repository credential (see `platform/gitops/README.md`).

2. **Maintenance window.** Run the Ansible k3s playbook so the
   `disable: traefik` setting in
   `infra/ansible/roles/k3s_server/tasks/main.yaml` takes effect:

   ```sh
   cd infra/ansible && ansible-playbook -i inventory/lab playbooks/site.yaml
   ```

   `k3s-server` restarts and uninstalls its `traefik` and `traefik-crd`
   releases. Ingress is down from here until step 3 completes.

3. Apply the app-of-apps root once:

   ```sh
   kubectl apply -f platform/gitops/root-app.yaml
   ```

   Argo CD then creates `cert-manager`, `traefik`, `platform-security` and
   `platform-gateways`; the `traefik` Application brings ingress back.

4. Watch it reconcile and confirm both APIs are served again:

   ```sh
   kubectl -n argocd get applications
   kubectl -n traefik get pods
   kubectl get ingressclass
   kubectl get gatewayclass
   ```

## What gets installed, and how ordering is enforced

| Application | Source | Destination | sync-wave |
| --- | --- | --- | --- |
| `gateway-api` | Gateway API CRDs from `https://github.com/kubernetes-sigs/gateway-api.git`, tag `v1.5.1`, path `config/crd/standard` | cluster-scoped | 0 |
| `cert-manager` | Helm chart `cert-manager` from `https://charts.jetstack.io`, pinned to `v1.21.2` | namespace `cert-manager` | 0 |
| `traefik` | Traefik Helm chart from `https://github.com/traefik/traefik-helm-chart.git`, tag `v40.3.0`, path `traefik` | namespace `traefik` | 1 |
| `platform-security` | `platform/security` | namespace `cert-manager` | 1 |
| `platform-gateways` | `apps/gateways` | namespace `default` | 2 |

`cert-manager` uses `ServerSideApply=true` because its CRDs exceed the
client-side `last-applied-configuration` annotation limit - the same
constraint that makes the `argocd_bootstrap` role install Argo CD with
`kubectl --server-side --force-conflicts`.

## Ingress and Gateway API (one Traefik data plane)

`platform/gitops/apps/traefik.yaml` installs the upstream Traefik chart with
Argo CD and is the only Helm release owning the ingress resources:

| Setting | Effect |
| --- | --- |
| `ingressClass.enabled: true`, `name: traefik`, `isDefaultClass: true` | keeps the `IngressClass traefik` that existing Ingress objects reference |
| `providers.kubernetesGateway.enabled: true` + `gatewayClass.enabled: true`, `name: traefik` | the chart creates the `GatewayClass traefik` |
| `gateway.enabled: false` | the `Gateway` and `HTTPRoute` objects stay in `apps/gateways/`, visible in Git |
| `image` pinned to `rancher/mirrored-library-traefik:3.7.4` | same image the k3s addon ran, already cached on the nodes |
| chart `crds/` | applied by Argo CD (`--include-crds` is the default), supplying the `traefik.io` and `hub.traefik.io` CRDs that the k3s `traefik-crd` release used to provide |
| Gateway API CRDs | not bundled by the chart any more; owned by the `gateway-api` Application (pinned to `v1.5.1`) |

`ServerSideApply=true` is required for the same reason as in `cert-manager`:
several Gateway API CRDs exceed the client-side
`last-applied-configuration` annotation limit - the constraint that also makes
`argocd_bootstrap` install Argo CD with `kubectl --server-side --force-conflicts`.

Confirm after sync:

```sh
kubectl get ingressclass                    # expect "traefik" (default)
kubectl get gatewayclass                    # expect "traefik"
kubectl -n default get gateway,httproute    # expect traefik-gateway + nginx-test
kubectl -n traefik get deploy,svc           # expect traefik + LoadBalancer with the node IPs
```

Because the controller now lives in namespace `traefik` and is no longer a k3s
addon, `kubectl -n kube-system get helmchart` should show no `traefik` or
`traefik-crd` entries, and `helm list -n traefik` is managed by Argo CD.

## Adding a new platform service

1. Add its manifests under the matching `platform/` or `apps/` directory.
2. Add an `Application` in `platform/gitops/apps/` pointing at that path.
3. Commit and push. Argo CD picks it up; nothing is run by hand and nothing is
   added to Ansible.

## Rollback

Revert the Git commit; Argo CD self-heals to the previous revision. For an
individual service, point the `Application` at an earlier `targetRevision`, or
delete the `Application` and let the root's prune remove its resources.
