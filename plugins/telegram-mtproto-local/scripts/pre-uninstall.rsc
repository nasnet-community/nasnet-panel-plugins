# Remove only what pre-install.rsc added: the script, its schedule, and the rules
# and address list it keeps. The panel then removes the container and its data.
:log info "telegram-mtproto-local: removing the router's side"
:do { /system scheduler remove [find where name="nasnet-mtproto-local"] } on-error={}
:do { /system script remove [find where name="nasnet-mtproto-local"] } on-error={}
:do { /ip firewall nat remove [find where comment~"^nasnet:telegram-mtproto-local:"] } on-error={}
:do { /ip firewall mangle remove [find where comment~"^nasnet:telegram-mtproto-local:"] } on-error={}
:do { /ip firewall address-list remove [find where list="nasnet-mtproto-local-public"] } on-error={}
