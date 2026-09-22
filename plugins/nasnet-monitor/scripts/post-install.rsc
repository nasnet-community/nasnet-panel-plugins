:if ([:len [/system/scheduler find where comment="nasnet:nasnet-monitor:daily-restart"]] = 0) do={

    /system/scheduler add \
        name="nasnet-monitor-daily-restart" \
        start-time=00:00:00 \
        interval=1d \
        on-event="/container restart [find where comment=\"nasnet:nasnet-monitor\"]" \
        comment="nasnet:nasnet-monitor:daily-restart"

    :log info "nasnet-monitor: added daily restart scheduler"
}
