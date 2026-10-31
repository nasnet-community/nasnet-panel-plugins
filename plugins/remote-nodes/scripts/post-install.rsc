# The container is up. Make sure both schedulers are there, the same two as in
# pre-install.rsc in case that run did not finish, then run the script once more so
# the first read of router/state is current. Nothing is exposed on the router.
:if ([:len [/system script find where comment="nasnet:remote-nodes:facts"]] > 0) do={
    :if ([:len [/system scheduler find where comment="nasnet:remote-nodes:facts"]] = 0) do={
        :do { /system scheduler add name="nasnet-remote-nodes-facts" interval=1m policy=ftp,read,write,test on-event="/system script run nasnet-remote-nodes-facts" comment="nasnet:remote-nodes:facts" } on-error={ :log warning "remote-nodes: could not add the 5 minute scheduler" }
    }
    :if ([:len [/system scheduler find where comment="nasnet:remote-nodes:facts-boot"]] = 0) do={
        :do { /system scheduler add name="nasnet-remote-nodes-facts-boot" start-time=startup policy=ftp,read,write,test on-event=":delay 60s; /system script run nasnet-remote-nodes-facts" comment="nasnet:remote-nodes:facts-boot" } on-error={ :log warning "remote-nodes: could not add the boot scheduler" }
    }
    :do { /system script run nasnet-remote-nodes-facts } on-error={ :log warning "remote-nodes: the facts script failed to run" }
    :log info "remote-nodes: installed"
} else={
    :log warning "remote-nodes: the facts script is missing, reinstall the plugin"
}
