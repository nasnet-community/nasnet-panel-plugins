# telegram-mtproto: route the container (192.168.50.11) the way the panel's wizard does.
# The wizard adds both rules; this only fills in what a re-run of it or an older setup lost.
# Order matters: the domestic rule must come first, both end the chain (passthrough=no).
:log info "telegram-mtproto: checking the routing rules for 192.168.50.11"

:local foreign [/ip/firewall/mangle find where chain=prerouting src-address="192.168.50.11" new-routing-mark=to-Foreign]
:local domestic [/ip/firewall/mangle find where chain=prerouting src-address="192.168.50.11" new-routing-mark=to-Domestic]

:if ([:len $domestic] = 0 && [:len [/routing/table find where name=to-Domestic]] > 0) do={
    :if ([:len $foreign] > 0) do={
        /ip/firewall/mangle add chain=prerouting action=mark-routing src-address=192.168.50.11 \
            dst-address-list=DOMAddList new-routing-mark=to-Domestic passthrough=no \
            comment="nasnet:telegram-mtproto:domestic" place-before=($foreign->0)
    } else={
        /ip/firewall/mangle add chain=prerouting action=mark-routing src-address=192.168.50.11 \
            dst-address-list=DOMAddList new-routing-mark=to-Domestic passthrough=no \
            comment="nasnet:telegram-mtproto:domestic"
    }
}

:if ([:len $foreign] = 0) do={
    /ip/firewall/mangle add chain=prerouting action=mark-routing src-address=192.168.50.11 \
        dst-address-list=!LOCAL-IP new-routing-mark=to-Foreign passthrough=no \
        comment="nasnet:telegram-mtproto:foreign"
}
:log info "telegram-mtproto: routing rules ready"
