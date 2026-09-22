:log info "nasnet-monitor: applying Safe Route configuration"

:if ([:len [/ip/firewall/address-list find where list="Safe" && address="192.168.50.15"]] = 0) do={

    /ip/firewall/address-list add \
        list="Safe" \
        address="192.168.50.15" \
        comment="Safe"
}
:log info "nasnet-monitor: applying Safe Route configuration completed"
