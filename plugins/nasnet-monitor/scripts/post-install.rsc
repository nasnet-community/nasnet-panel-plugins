:log info "nasnet-panel: applying Safe 8015 DNAT configuration"

:if ([:len [/ip/firewall/address-list find where comment="nasnet:nasnet-monitor:safe-address"]] = 0) do={

    /ip/firewall/address-list add \
        list="Safe" \
        address="192.168.50.15" \
        comment="nasnet:nasnet-monitor:safe-address"
}

:if ([:len [/ip/firewall/nat find where comment="nasnet:nasnet-monitor:dashboard-dnat"]] = 0) do={

    /ip/firewall/nat add \
        chain=dstnat \
        protocol=tcp \
        dst-port=8015 \
        src-address-list=Safe \
        in-interface-list=!WAN \
        action=dst-nat \
        to-addresses=192.168.50.15 \
        to-ports=8080 \
        comment="nasnet:nasnet-monitor:dashboard-dnat"

    :log info "nasnet-panel: added Safe DNAT TCP 8015 to 192.168.50.15:8080"

} else={

    :log info "nasnet-panel: Safe DNAT rule already exists"
}

:log info "nasnet-panel: Safe 8015 DNAT configuration completed"

:if ([:len [/system/scheduler find where comment="nasnet:nasnet-monitor:daily-restart"]] = 0) do={

    /system/scheduler add \
        name="nasnet-monitor-daily-restart" \
        start-time=00:00:00 \
        interval=1d \
        on-event=":local c [/container find where comment=\"nasnet:nasnet-monitor\"]; /container stop \$c; :local i 0; :while ([/container get \$c status] != \"stopped\" && \$i < 30) do={:delay 1s; :set i (\$i + 1)}; /container start \$c" \
        comment="nasnet:nasnet-monitor:daily-restart"

    :log info "nasnet-panel: added nasnet-monitor daily restart scheduler"
}
