# Pengu — your persistent Linux buddy

**A drop-in Podman/Docker dev environment for any project.**

> 🧩 One repo → one Pengu container.
> Persistent. Portable. Zero config.

![Pengu](images/pengu-min.png)
---

## 🚀 Quick install

Add Pengu to your current project:

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- --org <your-org> --ref main -y
```

✅ This will:

* Download `Dockerfile` and `pengu` into your current directory.
* Make `pengu` executable.
* Print the next steps.

Then simply run:

```bash
./pengu up
./pengu shell
```

You’re now inside your own **Ubuntu 24.04 workspace**.
Your project is mounted at `/workspace`, and Pengu keeps your Linux home in a persistent volume (`<project>-pengu-home`).

---

## 📦 The installer (`pengu-install.sh`)

The installer automates setup — no manual file copying.

### Usage

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- [options]
```

### Options

| Option             | Description                                           |
| ------------------ | ----------------------------------------------------- |
| `-y`, `--yes`      | Overwrite existing files without asking               |
| `--org <org>`      | GitHub user/org hosting Pengu (default: `<your-org>`) |
| `--ref <ref>`      | Branch, tag, or commit to fetch (default: `main`)     |
| `--with-gitignore` | Also fetch `.gitignore`                               |
| `--files "A B C"`  | Custom list of files to fetch                         |
| `--dest <path>`    | Install Pengu into another directory                  |

Example (with `.gitignore`):

```bash
curl -fsSL https://raw.githubusercontent.com/<your-org>/pengu/main/pengu-install.sh | bash -s -- --org <your-org> --with-gitignore -y
```

---

## 💾 What persists

| Path                                   | Purpose                         | Persistence     |
| -------------------------------------- | ------------------------------- | --------------- |
| `/workspace`                           | Your project folder             | Host filesystem |
| `/home/pengu`                          | User home, pip installs, caches | Named volume    |
| `/var/cache/apt`, `/var/lib/apt/lists` | APT caches                      | Named volumes   |

Extra packages installed inside Pengu persist automatically.
To bake them into the image for everyone:

```bash
./pengu commit
```

---

## 🧱 One container per project

Each project automatically gets its own Pengu container and volumes, named from the folder (e.g., `myapp-pengu`).

**Why this design:**

* Isolated dependencies and caches
* No UID/GID or path collisions
* Easy cleanup (`./pengu nuke`)
* No shared config headaches

> Alternative: one shared Pengu across repos — possible, but not recommended.
> Stick with **one Pengu per project** for clarity and reproducibility.

---

## 🧰 Pengu commands

| Command           | Description                       |
| ----------------- | --------------------------------- |
| `./pengu up`      | Build & start Pengu               |
| `./pengu shell`   | Open shell as user `pengu`        |
| `./pengu root`    | Open root shell                   |
| `./pengu stop`    | Stop the container                |
| `./pengu rm`      | Remove container (keep data)      |
| `./pengu rebuild` | Rebuild from Dockerfile           |
| `./pengu commit`  | Save current state into the image |
| `./pengu nuke`    | Delete container **and** volumes  |

---

## 🧩 For templates and onboarding

Embed Pengu into any starter repo or onboarding doc with:

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- --org <your-org> --ref main -y
```

or with `.gitignore`:

```bash
curl -fsSL https://raw.githubusercontent.com/soyrochus/pengu/main/pengu-install.sh | bash -s -- --org <your-org> --with-gitignore -y
```

> 💡 “Run this command in your repo to get a ready-to-go Linux dev environment.”

---

## 🧠 Inside Pengu

When you open Pengu, you’ll see this banner:

```
🐧  Welcome to Pengu — your persistent Linux buddy
     /workspace is your project; /home/pengu persists.
     Need packages?  sudo apt update && sudo apt install <pkg>
```

You can install anything you like — Node, Java, Go, build tools, etc.
Everything behaves exactly as on a native Linux system.

---

## 🧯 Removing Pengu

To uninstall from a project:

```bash
rm -f Dockerfile pengu
podman volume rm -f $(basename "$PWD")-pengu-home || true
```

---

## 💡 Why teams love Pengu

* Same Linux everywhere (Mac, Windows, Linux)
* No “works on my machine” problems
* Persistent environments between sessions
* Fast onboarding — one line install
* Works offline after first build

---

## 🧊 Summary

| Feature       | Pengu                                  |
| ------------- | -------------------------------------- |
| OS            | Ubuntu 24.04                           |
| Default tools | ImageMagick, Python 3, sudo, curl, git |
| Persistence   | Per-project volumes                    |
| Engine        | Podman (preferred) or Docker           |
| Scope         | One container per project              |

---

## 🛠️ For maintainers

This section is for whoever maintains the **Pengu base repo** (`<your-org>/pengu`).

### 🧩 Structure

```
pengu/
├── Dockerfile         # Base image definition
├── pengu              # CLI helper
├── pengu-install.sh   # Installer script (used via curl | bash)
├── .gitignore
└── README.md
```

### 🔄 Update cycle

1. **Test locally**

   ```bash
   ./pengu up
   ./pengu shell
   ```

   Validate that Pengu still builds cleanly with Podman and Docker.

2. **Upgrade Ubuntu base**
   Change version in `Dockerfile` (e.g., `FROM ubuntu:24.10`),
   rebuild, and verify `apt` and `pip` still work.

3. **Commit + Tag a release**

   ```bash
   git commit -am "Update to Ubuntu 24.10"
   git tag v24.10.0
   git push --tags
   ```

   Users can then install a specific version:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/<your-org>/pengu/v24.10.0/pengu-install.sh | bash -s -- --org <your-org> --ref v24.10.0 -y
   ```

4. **(Optional)** Add a GitHub Action to:

   * Lint `pengu` and `pengu-install.sh` (shellcheck).
   * Build the image (`podman build -t pengu .`) to confirm validity.
   * Print the banner to ensure UTF-8 output is OK.

### 🧪 Local testing

You can test the installer without publishing:

```bash
bash pengu-install.sh --org . --dest /tmp/test-pengu --with-gitignore -y
cd /tmp/test-pengu
./pengu up && ./pengu shell
```

### 📦 Recommended release policy

* **Main branch** → Stable default install.
* **Tags** → Fixed Ubuntu versions (`v24.04`, `v24.10`, etc.).
* **Feature branches** → Experimental changes (don’t reference in curl commands).


## Principles of Participation

Everyone is invited and welcome to contribute: open issues, propose pull requests, share ideas, or help improve documentation.  
Participation is open to all, regardless of background or viewpoint.  

This project follows the [FOSS Pluralism Manifesto](./FOSS_PLURALISM_MANIFESTO.md),  
which affirms respect for people, freedom to critique ideas, and space for diverse perspectives.  


## License and Copyright

Copyright (c) 2025, Iwan van der Kleijn

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
