
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Bash/Shell](https://img.shields.io/badge/Bash/Shell-4EAA25.svg?logo=gnu-bash&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE.svg?logo=powershell&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED.svg?logo=docker&logoColor=white)
![OS: macOS | Linux | Windows](https://img.shields.io/badge/OS-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)
[![FOSS Pluralism Manifesto](https://img.shields.io/badge/Manifesto-FOSS%20Pluralism-8A2BE2.svg)](FOSS_PLURALISM_MANIFESTO.md)
[![Contributions welcome](https://img.shields.io/badge/Contributions-welcome-brightgreen.svg)](https://github.com/soyrochus/wormhole/issues)

# Pengu — your persistent Linux buddy

**Pengu** gives you a **real, persistent Linux environment** inside a container — instantly available from any operating system:  
✅ macOS ✅ Windows ✅ Linux

![Pengu](images/pengu-min.png)

It’s a lightweight way to have a *personal Ubuntu machine* always mapped to your project folder.  
Whatever you install or configure inside Pengu stays there — between runs, reboots, or even host restarts.

> 🧩 One project → one Pengu container (per profile).  
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

Copy this into any project folder (it doesn't need to be a git repo):

### Linux/macOS (Bash)

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.ps1 | iex
```

That's it!

Pengu keeps its config in `.pengu/`:
- `.pengu/Pengufile` is the default build file
- Add `.pengu/Pengufile.<name>` for extra profiles, then `./pengu up <name>`

**What gets downloaded:**

- **Bash install**: `.pengu/Pengufile` (Dockerfile syntax) and `pengu` (bash script)
- **PowerShell install**: `.pengu/Pengufile`, `pengu.ps1`, and `pengu` (for compatibility)

Then start Pengu:

**Linux/macOS:**

```bash
./pengu up
./pengu shell
```

**Windows:**

```powershell
.\pengu.ps1 up
.\pengu.ps1 shell
```

You're now inside Ubuntu 24.04 with your project mounted at `/workspace`.

---

## 🚀 Getting started

### Your first Pengu session

After installation, here's your typical workflow:

```bash
# Start Pengu (builds container on first run)
./pengu up

# Enter your Linux environment
./pengu shell

# You're now inside Ubuntu! Your project is at /workspace
cd /workspace
ls -la

# Install something for this project
pip install requests
sudo apt install htop

# Exit when done
exit

# Your installed packages persist between sessions
./pengu shell  # Everything you installed is still there!
```

### When to use each command

- **`./pengu shell`** - Your daily driver. Opens as regular user `pengu`
- **`./pengu root`** - When you need system privileges (installing packages with `apt`)
- **`./pengu stop`** - Pause Pengu when not needed (saves resources)
- **`./pengu rebuild`** - Start fresh but keep your data (useful after Pengufile changes)
- **`./pengu commit`** - Save current state as a new base image (for custom setups)
- **`./pengu nuke`** - Complete reset when you want to start over

### Common workflows

**Installing system packages:**

```bash
./pengu root
sudo apt update && sudo apt install nodejs npm
exit
./pengu shell  # Back to regular user with nodejs available
```

**Python development:**

```bash
./pengu shell
pip install django flask  # Installs to /home/pengu/.local/bin
python -m django startproject myapp
```

**Creating a custom base:**

```bash
./pengu shell
# Install everything you need...
exit
./pengu commit  # Saves current state
# Now `./pengu up` uses your customized image
```

---

## 📖 Reference

### Command reference

| Command                     | Description                        | Data preserved |
| --------------------------- | ---------------------------------- | -------------- |
| `./pengu up` [PROFILE]      | Build and start Pengu              | All            |
| `./pengu shell` [PROFILE]   | Enter Ubuntu shell as user `pengu` | All            |
| `./pengu root` [PROFILE]    | Enter as root                      | All            |
| `./pengu stop`              | Stop container                     | All            |
| `./pengu rm`                | Remove container (keep data)       | All volumes    |
| `./pengu rebuild` [PROFILE] | Rebuild from Pengufile             | All volumes    |
| `./pengu commit` [PROFILE]  | Save current state into image      | All            |
| `./pengu nuke`              | Delete container **and** volumes   | Nothing        |
| `./pengu profile list`      | List local profiles                | -              |
| `./pengu profile available` | Show available profiles            | -              |
| `./pengu profile install`   | Download profile from repository   | -              |
| `./pengu help`              | Show detailed help                 | -              |

### Profiles

Pengu supports multiple **profiles** per project. Each profile is a separate build configuration:

**Default profile:**
```bash
./pengu up              # Uses .pengu/Pengufile
./pengu shell           # Default profile
```

**Named profiles:**
```bash
./pengu up rust         # Uses .pengu/Pengufile.rust
./pengu shell rust      # Enter rust profile container

./pengu up python-ml    # Uses .pengu/Pengufile.python-ml
./pengu shell python-ml
```

**Manage profiles:**
```bash
./pengu profile list              # Show your local profiles
./pengu profile available         # Show profiles available from repository
./pengu profile install <name>    # Download a profile (e.g., 'rust')
```

Each profile has its own container instance and persistent volumes — no interference between profiles.

### Platform differences

**Linux/macOS:**
- Uses `./pengu` (bash script)
- SELinux labels applied automatically on Podman
- File permissions match your host user

**Windows:**
- Uses `.\pengu.ps1` (PowerShell script)
- Also installs `pengu` bash script for compatibility
- Fixed UID/GID (1000:1000) for consistency

---

## 🏗️ Technical Details

For in-depth information about Pengu's container architecture, volume strategy, security model, and performance characteristics, see [TECHSPEC.md](TECHSPEC.md).

Key topics covered:
- Container architecture and lifecycle
- 4-volume storage strategy
- Security model and isolation
- Performance characteristics
- Advanced multi-profile architecture
- Troubleshooting guide

---

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

## 🧩 Using Pengu with Visual Studio Code 

The recommended way to use Pengu with **Visual Studio Code** is to **attach VS Code to a running Pengu container**.

In this setup:

* VS Code runs **natively on your host**
* Your project files stay on the host filesystem
* All **tooling, terminals, language servers, and debuggers run inside Pengu**
* `/workspace` inside Pengu is used as the project root

This gives you full IDE support with clean, container-isolated environments.

---

### Requirements

* Visual Studio Code on the host
* VS Code extension: **Dev Containers**
* Pengu container running via Podman or Docker

---

### One-time setup (Podman)

VS Code connects via a Docker-compatible API.
If you use Podman, expose its socket:

```bash
podman system service --time=0 &
```

(Optional but recommended)

```bash
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
```

---

### Attach VS Code to a running Pengu container

1. Start Pengu:

   ```bash
   ./pengu up
   ```

2. Open VS Code
3. Open the Command Palette:

   * macOS: `Cmd + Shift + P`
   * Linux / Windows: `Ctrl + Shift + P`

4. Run:

   ```
   Dev Containers: Attach to Running Container
   ```
5. Select your Pengu container, for example:

   ```
   myproject-pengu-default
   myproject-pengu-java25
   myproject-pengu-rust
   ```

VS Code will reopen attached to the container and use `/workspace` automatically.

---

### Why this works well

* Native VS Code UX with container-isolated toolchains
* No file copying or rebuilding
* Works across macOS, Linux, and Windows
* Clean support for multiple Pengu profiles per project

This is the preferred way to use Pengu with Visual Studio Code.


---

## 🧩 For teams and templates

Add Pengu to any starter repo or onboarding doc with:

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y
```

That’s all your teammates need — no local setup, no WSL, no VMs.


## 📝 Incorporate minimal Pengu documentation in your README

To include a segment with explanation of and pointer to Pengu, you could add the following segment to your README.

````text
## 🐧 Development Environment

This project uses [Pengu](https://github.com/soyrochus/pengu) — a tool that gives you a persistent Linux environment in a container, instantly available from any operating system.

**Get started:**
```bash
# Install Pengu (Linux/macOS)
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- -y

# Start your Linux environment
./pengu up && ./pengu shell
```

**Windows:**

```powershell
iwr -useb https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.ps1 | iex
.\pengu.ps1 up; .\pengu.ps1 shell
```

Your project files are available at `/workspace` with all dependencies pre-configured. No local setup required.

````

## 🛠 Maintainers

This repo (`soyrochus/pengu`) contains:

```text
.pengu/Pengufile   # Default container definition (Dockerfile syntax)
pengu              # Bash helper script (symlinked to pengu.sh)
pengu.sh           # Bash helper script installed in projects  
pengu.ps1          # PowerShell helper script for Windows
pengu-install.sh   # Bash installer users run via curl | bash
pengu-install.ps1  # PowerShell installer for Windows
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


## Principles of Participation

Everyone is invited and welcome to contribute: open issues, propose pull requests, share ideas, or help improve documentation.  
Participation is open to all, regardless of background or viewpoint.  

This project follows the [FOSS Pluralism Manifesto](./FOSS_PLURALISM_MANIFESTO.md),  
which affirms respect for people, freedom to critique ideas, and space for diverse perspectives.  


## License and Copyright

Copyright (c) 2025, Iwan van der Kleijn

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
