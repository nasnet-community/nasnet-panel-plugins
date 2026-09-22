:log info "nasnet-panel: removing Safe 8015 DNAT configuration"

:do {
    /ip/firewall/nat remove [find where comment="nasnet:nasnet-monitor:dashboard-dnat"]
} on-error={}

:do {
    /ip/firewall/address-list remove [find where comment="nasnet:nasnet-monitor:safe-address"]
} on-error={}

:log info "nasnet-panel: Safe 8015 DNAT configuration removed"

:do {
    /system/scheduler remove [find where comment="nasnet:nasnet-monitor:daily-restart"]
} on-error={}
