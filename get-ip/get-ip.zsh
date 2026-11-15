# Convert a 32-bit integer to dotted-quad notation
_get_ip_dotted() {
  printf '%d.%d.%d.%d' $(( $1 >> 24 & 255 )) $(( $1 >> 16 & 255 )) $(( $1 >> 8 & 255 )) $(( $1 & 255 ))
}

# Usage: get-ip [-w]
#   -w  include Wi-Fi radio details (signal, channel; takes ~15s).
#       Added automatically when Wi-Fi is up but has no valid IP.
get-ip() {
  local wifi_detail=0
  [[ $1 == -w ]] && wifi_detail=1

  local ports wifi_dev dev label ifc link ip mac problem o
  local mask broadcast vlans masknum cidr ipnum net bcast hosts range packet dhcp_server lease
  local radio gw gwif gwmac gw_rtt inet_rtt dns_ok web info pub4 pub6 isp host loc k
  local -a inactive problems

  ports=$(networksetup -listallhardwareports)
  wifi_dev=$(awk '/^Hardware Port: Wi-Fi$/ {getline; print $2}' <<<"$ports")

  for dev in ${(f)"$(awk '/^Device: en[0-9]+$/ {print $2}' <<<"$ports")"}; do
    label=$(awk -v d="$dev" '
      /^Hardware Port:/ {port=substr($0,16)}
      /^Device:/ && $2==d {print port; exit}
    ' <<<"$ports")
    [[ $label != *"($dev)" ]] && label="$label ($dev)"
    ifc=$(ifconfig "$dev" 2>/dev/null)
    link=$(awk '/status:/ {print $2}' <<<"$ifc")
    ip=$(ipconfig getifaddr "$dev" 2>/dev/null)

    # Unplugged wired ports are listed in one line at the end; Wi-Fi is always shown
    if [[ -z $ip && $link != active && $dev != $wifi_dev ]]; then
      inactive+=("$label")
      continue
    fi

    mac=$(awk '/ether / {print $2}' <<<"$ifc")
    printf '\n%s\n' "$label"
    printf 'Status:      %s\n' "${link:-unknown}"
    # Locally administered bit set means macOS is using a randomized "Private Wi-Fi Address"
    if [[ -n $mac ]] && (( 16#${mac%%:*} & 2 )); then
      printf 'MAC:         %s (private/randomized)\n' "$mac"
    else
      printf 'MAC:         %s\n' "${mac:-unknown}"
    fi

    problem=""
    if [[ $dev == $wifi_dev && $(networksetup -getairportpower "$dev") == *Off ]]; then
      problem="Wi-Fi is turned off."
    elif [[ $link != active ]]; then
      if [[ $dev == $wifi_dev ]]; then
        problem="Wi-Fi is on but not joined to a network."
      else
        problem="No link. Check the cable, port, or adapter."
      fi
    elif [[ -z $ip ]]; then
      problem="Link is up but no IP address. DHCP is still trying or has failed."
    elif [[ $ip == 169.254.* ]]; then
      problem="Self-assigned address: no DHCP server answered. Likely the router's DHCP, a wrong VLAN/port, or Wi-Fi auth/MAC filtering. Try: sudo ipconfig set $dev DHCP, rejoin the network, or restart the router."
    fi

    packet=$(ipconfig getpacket "$dev" 2>/dev/null)
    dhcp_server=$(awk '/server_identifier/ {print $NF}' <<<"$packet")
    lease=$(ipconfig getsummary "$dev" 2>/dev/null | awk -F' : ' '/LeaseExpirationTime/ {print $2; exit}')

    if [[ -n $problem ]]; then
      printf 'Private IP:  %s\n' "${ip:-none}"
      printf 'DHCP:        %s\n' "${${dhcp_server:+offer from $dhcp_server}:-no reply from a DHCP server}"
      printf 'Problem:     %s\n' "$problem"
      problems+=("${label%% *}: $problem")
      [[ $dev == $wifi_dev && $link == active ]] && wifi_detail=1
    else
      read -r mask broadcast < <(awk '/inet / {print $4, ($5=="broadcast" ? $6 : ""); exit}' <<<"$ifc")
      vlans=$(for v in $(ifconfig -l); do
        [[ $v == vlan* ]] && ifconfig "$v" | awk -v d="$dev" '/vlan:/ && $NF==d {print $2}'
      done | paste -sd, -)

      masknum=$(( 16#${mask#0x} ))
      cidr=0
      while (( cidr < 32 && (masknum >> (31 - cidr)) & 1 )); do (( cidr += 1 )); done
      ipnum=0
      for o in ${(s:.:)ip}; do (( ipnum = ipnum * 256 + o )); done
      (( net = ipnum & masknum, bcast = net | (~masknum & 0xFFFFFFFF) ))
      if (( cidr >= 31 )); then
        hosts=$(( 2 ** (32 - cidr) ))
        range="$(_get_ip_dotted $net) - $(_get_ip_dotted $bcast)"
      else
        hosts=$(( 2 ** (32 - cidr) - 2 ))
        range="$(_get_ip_dotted $(( net + 1 ))) - $(_get_ip_dotted $(( bcast - 1 )))"
      fi

      printf 'Private IP:  %s\n' "$ip"
      printf 'CIDR:        %s/%s\n' "$ip" "$cidr"
      printf 'Network:     %s/%s\n' "$(_get_ip_dotted $net)" "$cidr"
      printf 'Host range:  %s (%s usable)\n' "$range" "$hosts"
      printf 'Mask:        %s\n' "$(_get_ip_dotted $masknum)"
      printf 'Broadcast:   %s\n' "${broadcast:-None}"
      printf 'VLAN:        %s\n' "${vlans:-None}"
      if [[ -n $dhcp_server ]]; then
        printf 'DHCP:        from %s, lease expires %s\n' "$dhcp_server" "${lease:-unknown}"
      else
        printf 'DHCP:        not used (manual/static address)\n'
      fi
    fi

    if [[ $dev == $wifi_dev && $wifi_detail == 1 && $link == active ]]; then
      radio=$(system_profiler SPAirPortDataType 2>/dev/null |
        sed -n '/Current Network Information:/,/Other Local Wi-Fi Networks:/p')
      printf 'Wi-Fi:       %s, channel %s\n' \
        "$(awk -F': ' '/PHY Mode/ {print $2; exit}' <<<"$radio")" \
        "$(awk -F': ' '/Channel/ {print $2; exit}' <<<"$radio")"
      printf 'Security:    %s\n' "$(awk -F': ' '/Security/ {print $2; exit}' <<<"$radio")"
      awk -F': ' '/Signal \/ Noise/ {
        split($2, s, " "); q = s[1] >= -60 ? "good" : s[1] >= -70 ? "fair" : "weak"
        printf "Signal:      %s (%s)\n", $2, q; exit
      }' <<<"$radio"
      awk -F': ' '/Transmit Rate/ {printf "Link rate:   %s Mbps\n", $2; exit}' <<<"$radio"
    fi
  done

  (( ${#inactive} )) && printf '\nNo link:     %s\n' "${(j:, :)inactive}"

  # Router: the default gateway, its hardware address, and DNS servers handed out
  gw=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')
  gwif=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
  printf '\nRouter\n'
  if [[ -z $gw ]]; then
    printf 'Gateway:     none (no default route)\n'
  else
    # arp drops leading zeros (94:4:e3...), so pad each octet back to two digits
    gwmac=$(arp -n "$gw" 2>/dev/null | awk '$4 ~ /:/ {n = split($4, b, ":"); for (i = 1; i <= n; i++) printf "%s%02s", (i > 1 ? ":" : ""), b[i]}' | tr ' ' 0)
    gw_rtt=$(ping -c1 -t1 "$gw" 2>/dev/null | awk -F/ '/round-trip/ {print $5}')
    printf 'Gateway:     %s via %s\n' "$gw" "$gwif"
    printf 'Router MAC:  %s\n' "${gwmac:-unknown}"
    printf 'Admin page:  http://%s\n' "$gw"
    printf 'Ping:        %s\n' "${${gw_rtt:+$gw_rtt ms}:-no reply}"
  fi
  printf 'DNS servers: %s\n' "$(scutil --dns | awk '/nameserver\[/ {print $3}' | awk '!seen[$0]++' | paste -sd, - | sed 's/,/, /g')"

  # Connectivity checks, from nearest to farthest
  printf '\nInternet\n'
  inet_rtt=$(ping -c1 -t2 1.1.1.1 2>/dev/null | awk -F/ '/round-trip/ {print $5}')
  dig +short +time=2 +tries=1 apple.com 2>/dev/null | grep -q . && dns_ok=1
  web=$(curl -s --max-time 3 http://captive.apple.com/hotspot-detect.html)
  printf 'Ping 1.1.1.1: %s\n' "${${inet_rtt:+$inet_rtt ms}:-no reply}"
  printf 'DNS lookup:  %s\n' "${${dns_ok:+working}:-failing}"
  if [[ $web == *Success* ]]; then
    printf 'Web:         reachable\n'
  elif [[ -n $web ]]; then
    printf 'Web:         captive portal detected (a login page is intercepting traffic)\n'
  else
    printf 'Web:         unreachable\n'
  fi

  if [[ -n $inet_rtt || $web == *Success* ]]; then
    info=$(curl -4 -s --max-time 3 https://ipinfo.io/json)
    pub4=$(plutil -extract ip raw -o - - <<<"$info" 2>/dev/null)
    isp=$(plutil -extract org raw -o - - <<<"$info" 2>/dev/null)
    host=$(plutil -extract hostname raw -o - - <<<"$info" 2>/dev/null)
    loc=$(for k in city region country; do plutil -extract $k raw -o - - <<<"$info" 2>/dev/null; done | paste -sd, - | sed 's/,/, /g')
    pub6=$(curl -6 -s --max-time 3 https://v6.ipinfo.io/ip)
    printf 'Public IPv4: %s\n' "${pub4:-unavailable}"
    printf 'Public IPv6: %s\n' "${pub6:-none (no IPv6 internet)}"
    printf 'ISP:         %s\n' "${isp:-unavailable}"
    [[ -n $host ]] && printf 'ISP host:    %s\n' "$host"
    printf 'Location:    %s\n' "${loc:-unavailable}"
  fi

  # One-line verdict for troubleshooting
  printf '\nDiagnosis:   '
  if [[ -z $gw ]] && (( ${#problems} )); then
    print "No usable IP address, so there's no route out. See Problem above."
  elif [[ -z $gw ]]; then
    print "Not connected to any network (no gateway)."
  elif [[ -z $gw_rtt && -z $gwmac ]]; then
    print "Can't reach the router. Check Wi-Fi/cable, or restart the router."
  elif [[ -n $web && $web != *Success* ]]; then
    print "Captive portal. Open a browser and sign in to the network."
  elif [[ -z $inet_rtt && $web != *Success* ]]; then
    if [[ -z $dns_ok ]]; then
      print "Router is reachable but there's no internet. Likely the modem/router or an ISP outage."
    else
      print "DNS answers but the web is unreachable. Possibly a firewall, proxy, or VPN issue."
    fi
  elif [[ -z $dns_ok ]]; then
    print "Internet works but DNS is failing. Try other DNS servers (e.g. 1.1.1.1)."
  else
    print "All checks passed."
  fi
}
