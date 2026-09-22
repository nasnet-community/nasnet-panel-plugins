:if ([:len [/system/scheduler find where comment="nasnet:nasnet-monitor:daily-restart"]] = 0) do={

    /system/scheduler add \
        name="nasnet-monitor-daily-restart" \
        start-time=00:00:00 \
        interval=1d \
        on-event=":local c [/container find where comment=\"nasnet:nasnet-monitor\"]; /container stop \$c; :local i 0; :while ([/container get \$c status] != \"stopped\" && \$i < 30) do={:delay 1s; :set i (\$i + 1)}; /container start \$c" \
        comment="nasnet:nasnet-monitor:daily-restart"

    :log info "nasnet-monitor: added daily restart scheduler"
}
