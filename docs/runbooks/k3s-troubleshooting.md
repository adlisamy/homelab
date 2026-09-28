# K3s Troubleshooting

## `WARN[0000] open /etc/rancher/k3s/config.yaml: permission denied`

`/usr/local/bin/kubectl` is a link to the K3s binary. Before running the
`kubectl` subcommand, K3s tries to read its node configuration at
`/etc/rancher/k3s/config.yaml`. That file is intentionally root-only because
agent configurations contain the join token.

This warning does not prevent `kubectl` from using the user's kubeconfig. The
Ansible `common` role sets `K3S_CONFIG_FILE=/dev/null` in the SSH user's
`~/.profile`, so a new SSH login uses `~/.kube/config` without the warning.

For an existing shell, run:

```sh
export K3S_CONFIG_FILE=/dev/null
```

## Node bootstrap failures seen in this lab

### Package-manager lock on a new VM

`apt.systemd.daily` and `unattended-upgrades` can hold the dpkg lock while a VM
is first provisioned. This caused package installation to fail on
`k3s-node-02`; it was not a K3s join failure.



The `common` role now waits up to five minutes for
`/var/lib/dpkg/lock-frontend` to be released before installing packages. Do not
delete lock files. If the lock is held unusually long, identify the holder with
`sudo fuser -v /var/lib/dpkg/lock-frontend` before taking action.



### Nodes are `Ready`, but pods stay `ContainerCreating`

K3s was configured to use the host's external containerd. K3s selected the
`cgroupfs` kubelet driver, while containerd was configured with
`SystemdCgroup = true`. The mismatch made containerd reject pod sandbox cgroup

paths, producing `FailedCreatePodSandBox` events for Traefik and Calico pods.



The recommended long-term configuration on Ubuntu 24.04 (cgroup v2) is to
align both drivers on `systemd`. The K3s runtime role now sets
`SystemdCgroup = true` in containerd, and both the server and agent K3s configs

pass `kubelet-arg: "cgroup-driver=systemd"` to the kubelet. Verify the
alignment with:

```sh
grep SystemdCgroup /etc/containerd/config.toml
grep cgroupDriver /var/lib/rancher/k3s/agent/etc/kubelet.conf.d/00-k3s-defaults.conf
```

Both must use `systemd` for this configuration.



> **Note:** Changing cgroup drivers on nodes already in a cluster is sensitive.
> Kubernetes recommends recreating worker nodes after the change. Since this
> cluster is brand new, it is practical to do now, but ideally the worker nodes
> should be recreated after applying the new configuration.



### Agent access to `kubectl`

Agents do not run the Kubernetes API server, so they do not receive the
server's administrator kubeconfig. The `k3s_agent` role instead writes a
dedicated `~/.kube/config` for `ubuntu` on each worker.



Its service account has cluster-wide read-only access and can read node and
namespace metadata. It cannot create resources, execute into pods, read
secrets, or administer the cluster. Treat the file as a credential and keep its
permissions at `0600`. To revoke the worker credential:



```sh
sudo k3s kubectl -n kube-system delete secret worker-kubectl-token
```



Run the Ansible K3s playbook afterward to create and distribute a replacement.