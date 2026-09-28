# platform/ingress

The Traefik controller itself is **not** defined here. It is the
`traefik` Application in `platform/gitops/apps/traefik.yaml`, which installs
the upstream Traefik Helm chart (Ingress + Gateway API providers) into the
`traefik` namespace. The k3s traefik addon is disabled in
`infra/ansible/roles/k3s_server/tasks/main.yaml` so only one Helm release owns
the ingress resources.

This directory is for **platform-level Traefik routing configuration** that is
not tied to a single workload - for example:

- `TLSOption` / `TLSStore` defaults
- shared `Middleware` (security headers, rate limits)
- an `IngressRoute` for the Traefik dashboard

Object placement:

| Object | Where it lives |
| --- | --- |
| Traefik controller, `IngressClass`, `GatewayClass` | Argo CD Application `traefik` |
| `Gateway` / `HTTPRoute` for applications | `apps/gateways/` |
| `Ingress` next to its workload | alongside the workload, e.g. `apps/demo-services/` |

> There is currently no Argo CD `Application` pointing at this directory,
> because it has no manifests yet. An `Application` aimed at an empty path
> errors, so add one (`platform/gitops/apps/ingress.yaml`, path
> `platform/ingress`) together with the first manifest you put here -
> otherwise files dropped in this directory will never be applied.
