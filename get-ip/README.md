# 🌐 get-ip – macOS Network Info & Troubleshooter

A zsh function that shows everything about your Mac's network connection in one command: private and public IPs, CIDR breakdown, router, ISP, and a set of connectivity checks that end in a one-line diagnosis. Built to stay useful when things are broken, like no IP or a self-assigned `169.254.x.x` address.

---

## 📦 Files Included

### `get-ip.zsh`
- Defines the `get-ip` function (plus a small `_get_ip_dotted` helper).
- Shows, per active interface (Wi-Fi is always shown):
    - Private IP, CIDR, network address, usable host range, mask, broadcast
    - MAC address (flags randomized "Private Wi-Fi Address")
    - DHCP server and lease expiry, VLAN
- **Router:** gateway, router MAC, admin page link, ping time, DNS servers
- **Internet:** public IPv4 and IPv6, ISP, ISP hostname, approximate location (via [ipinfo.io](https://ipinfo.io))
- **Connectivity checks:** router ping → internet ping → DNS lookup → web/captive portal check
- **Diagnosis:** one line saying where the chain breaks

---

## 🚀 How to Use

### 1. Install
Add it to your `~/.zshrc`:

```zsh
cat get-ip.zsh >> ~/.zshrc
source ~/.zshrc
```

Or keep the file separate and source it:

```zsh
echo 'source /path/to/get-ip.zsh' >> ~/.zshrc
```

### 2. Run

```zsh
get-ip       # full report
get-ip -w    # also show Wi-Fi radio details (signal, channel, link rate; ~15s)
```

Wi-Fi radio details are added automatically when Wi-Fi is connected but has no valid IP.

---

## 🩺 Troubleshooting Output

When something is wrong, the interface gets a `Problem:` line and the report ends with a diagnosis:

| Situation | What you'll see |
|---|---|
| Wi-Fi off / not joined | `Wi-Fi is turned off.` / `Wi-Fi is on but not joined to a network.` |
| Link up, no IP | `Link is up but no IP address. DHCP is still trying or has failed.` |
| `169.254.x.x` | Self-assigned warning with likely causes and fixes |
| Router unreachable | `Can't reach the router.` |
| Router OK, no internet | `Likely the modem/router or an ISP outage.` |
| DNS failing | `Internet works but DNS is failing.` |
| Hotel/airport login page | `Captive portal. Open a browser and sign in.` |

---

## ⚙️ Requirements

- macOS, zsh
- Built-in tools only: `networksetup`, `ipconfig`, `ifconfig`, `route`, `arp`, `scutil`, `system_profiler`, `curl`, `dig`, `plutil`
