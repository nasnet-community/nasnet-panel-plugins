:log info "nasnet-monitor: removing Safe Route configuration"

:do {
    /ip/firewall/address-list remove [find where list="Safe" && address="192.168.50.15" && comment="Safe"]
} on-error={}

:log info "nasnet-monitor: Safe Route configuration removed"

:do {
    /system/scheduler remove [find where comment="nasnet-monitor:daily-restart"]
} on-error={}
