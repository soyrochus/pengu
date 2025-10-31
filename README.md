# Pengu — your persistent Linux buddy

**Pengu** gives you a **real, persistent Linux environment** inside a container — instantly available from any operating system:  
✅ macOS ✅ Windows ✅ Linux

![Pengu](images/pengu-min.png)

It’s a lightweight way to have a *personal Ubuntu machine* always mapped to your project folder.  
Whatever you install or configure inside Pengu stays there — between runs, reboots, or even host restarts.

> 🧩 One project → one Pengu container.  
> Persistent. Portable. Zero configuration.

---

## 🚀 What Pengu does

- **Runs Ubuntu in a container** (via Podman or Docker).  
- **Mounts your current folder** at `/workspace` so your code stays local.  
- **Keeps its own Linux home directory** in a persistent volume (`<project>-pengu-home`).  
- Lets you **install anything** (`apt install`, `pip install`, etc.) and keep it between sessions.  
- Works seamlessly across operating systems — same setup for everyone.  

In short:  
> Pengu gives you a *personal Linux buddy* for every project — always ready, always clean, always yours.

---

## 🧩 Why it’s useful

| Without Pengu | With Pengu |
|----------------|------------|
| “Works on my machine” issues | Same Linux everywhere |
| Needing WSL or dual boot | Runs natively via Podman/Docker |
| Losing installed tools after rebuild | Everything persists |
| Team setup differences | Identical, reproducible environment |

---

## 🪄 Quick install (one line)

Copy this into any project folder (it doesn’t need to be a git repo):

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
````

That’s it!
It downloads two files (`Dockerfile` and `pengu`) into your current directory.

Then start Pengu:

```bash
./pengu up
./pengu shell
```

You’re now inside Ubuntu 24.04 with your project mounted at `/workspace`.

---

## 💾 What persists

| Location                               | Purpose                                   | Persists between runs |
| -------------------------------------- | ----------------------------------------- | --------------------- |
| `/workspace`                           | Your local project folder                 | ✅ (on your host)      |
| `/home/pengu`                          | Pengu user’s home (pip, caches, dotfiles) | ✅ (named volume)      |
| `/var/cache/apt`, `/var/lib/apt/lists` | apt caches                                | ✅ (named volumes)     |

Anything installed inside Pengu (via `sudo apt install` or `pip install`) will stay available for that project.

---

## 🧱 One Pengu per project (by design)

Each project gets its own Pengu container and volumes, automatically named after the folder (e.g. `myapp-pengu`).
This design keeps your environments clean, isolated, and disposable.

> Want a fresh start?
> Run `./pengu nuke` — all gone, instantly.

---

## 🧰 Pengu commands

| Command           | Description                        |
| ----------------- | ---------------------------------- |
| `./pengu up`      | Build and start Pengu              |
| `./pengu shell`   | Enter Ubuntu shell as user `pengu` |
| `./pengu root`    | Enter as root                      |
| `./pengu stop`    | Stop container                     |
| `./pengu rm`      | Remove container (keep data)       |
| `./pengu rebuild` | Rebuild from Dockerfile            |
| `./pengu commit`  | Save current state into image      |
| `./pengu nuke`    | Delete container **and** volumes   |

---

## 🧯 Remove Pengu from a project

```bash
rm -f Dockerfile pengu
podman volume rm -f "$(basename "$PWD")-pengu-home" || true
```

---

## 🧩 For teams and templates

Add Pengu to any starter repo or onboarding doc with:

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
```

That’s all your teammates need — no local setup, no WSL, no VMs.

---

## 🛠 Maintainers

This repo (`soyrochus/pengu`) contains:

```
Dockerfile         # Base Ubuntu + banner
pengu              # Local helper script installed in projects
pengu-install.sh   # Installer users run via curl | bash
.gitignore
README.md
```

When you update Pengu:

1. Test locally with Podman and Docker.
2. Tag a release (`git tag v24.10.0 && git push --tags`).
3. Users can install a specific version:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/v24.10.0/pengu-install.sh | bash -s -- -y
   ```

---

[![Install Pengu](https://img.shields.io/badge/Install-Pengu-blue?logo=gnu-bash\&style=for-the-badge)](https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh)

**Pengu** — a penguin in your pocket. 🐧

