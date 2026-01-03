# 🚀 SSL Proxy Toolkit

A modular, zero-cost, and fully configurable Nginx reverse proxy setup for macOS. This toolkit allows you to intercept traffic for any production domain (e.g., `ssl-proxy-setup.net`) and route it to your local development server with fully trusted SSL.

## 1. Introduction & Purpose

When developing locally, you often need to simulate a production environment, specifically HTTPS and real domain names. 
This toolkit automates:

* **Local DNS:** Routing production domains to `127.0.0.1`.
* **SSL Orchestration:** Creating locally-trusted certificates using `mkcert`.
* **Reverse Proxying:** Forwarding specific paths or entire domains from port 443 to your local dev ports (e.g., `8083`).
* **Project Switching:** Instantly swapping between different proxy configurations.

## 2. Project Structure

The toolkit is self-contained. All configurations, certificates, and logs stay within this directory.

```text
.
├── manage.sh           # Main CLI controller
├── www/                # Static landing page (index.html)
├── conf/               # Store for all project-specific configs
│   ├── nginx.conf      # SYMLINK: Points to the active project
│   └── project-a.conf  # Actual config file
├── certs/              # Generated .pem certificates (Git ignored)
├── logs/               # Access/Error logs and PID files (Git ignored)
└── scripts/            # Internal automation logic (cert/host/switch)

```

### 2.1 Requirements

To run this setup, you must have the following installed via Homebrew:

1. **Nginx:** The core engine used for proxying.
2. **mkcert and nss:** A simple tool for making locally-trusted development certificates. It creates a local CA in your system keychain.

```bash
brew install nginx
brew install mkcert
brew install nss
```

**Crucial:** Run `mkcert -install` once after installing to trust the Root CA.
```bash
mkcert -install
```

## 3. Managing the Proxy

The toolkit uses a "Master" script (`manage.sh`) to control the Nginx lifecycle.

| Command | Action |
| --- | --- |
| `./manage.sh start` | Launches Nginx using the currently linked config (requires `sudo` for port 443). |
| `./manage.sh stop` | Gracefully shuts down the local Nginx instance. |
| `./manage.sh reload` | Reloads the configuration without dropping connections. |
| `./manage.sh logs` | Streams the "Flow Logs" (access logs) to your terminal. |

### 3.1 The Symlink System

The folder `conf/` acts as a library of configurations. Nginx is hard-coded to look for a file named `nginx.conf`. Instead of a real file, we use a **Symlink**:

* **Switching:** When you run `./manage.sh switch <project>.conf`, the script deletes the existing `nginx.conf` link and points it to your chosen project file.
* **Benefit:** This allows you to have 20 different project setups ready to go, but only one active at a time, keeping port 443 clean.

## 4. Creating a New Proxy Config

You don't need to write Nginx boilerplate by hand. Use the bootstrap command to generate everything at once.

### Step 1: Bootstrap

Run the create command with your desired domain and the local port your app is running on:

```bash
./manage.sh create ssl-proxy-setup.net 8083

```

**Boostrap handles this automatically:**

1. Adds `127.0.0.1 ssl-proxy-setup.net` to your `/etc/hosts`.
2. Generates SSL certificates in `/certs`.
3. Creates a new config file `conf/ssl-proxy-setup.net.conf` with optimized proxy headers.

### Step 2: Activate

Once created, link the config and start the service:

```bash
./manage.sh switch ssl-proxy-setup.net.conf
./manage.sh start

```

### Step3: Local DNS 

Make sure that your hosts file maps the new domain to your localhost

```bash
./manage.sh host ssl-proxy-setup.net.conf

# or edit it manually
# 
sudo vim /etc/hosts

# then add 
# 
127.0.0.1	ssl-proxy-setup.net

# and save with esc + :wq!
```

If you want to check your /etc/hosts file just run
```bash
cat /etc/hosts
```
and look for an entry link
```bash
127.0.0.1	ssl-proxy-setup.net
```

### Step 4: Verify

Visit `https://ssl-proxy-setup.net`.

* The **Root (/)** will show your custom landing page.
* All **Sub-paths (/*)** will be forwarded to your local server at `localhost:8083`.

# Troubleshooting

### 🛠 Chrome Setup 

Chrome uses the **macOS System Keychain** to verify certificates. Follow these steps to ensure Chrome trusts your local proxy:

1. **Trust the CA**: Ensure you have run `mkcert -install` once and entered your macOS password when prompted.
2. **Verify Keychain**:
* Open **Keychain Access**.
* Search for `mkcert`.
* Ensure `mkcert development CA` is present and marked with a **green checkmark** (Always Trust).


3. **Restart Chrome**: Completely quit Chrome (`Cmd+Q`) and relaunch it to clear the SSL cache.
4. **Flush Sockets**: If the "Not Secure" warning persists, go to `chrome://net-internals/#sockets` and click **Flush socket pools**.


# License

MIT

# How can I support the work
Ideas and pull requests are always welcome.

Same for coffee contributions 
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/thomashartm)
