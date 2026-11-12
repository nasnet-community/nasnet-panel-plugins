# Remove only what pre-install.rsc added: the facts script and its two schedulers, and
# the rules and address list its script keeps for the plugin's own entry. The data
# folder stays, router/state with it: it holds what the nodes trust, and the panel
# decides whether it goes. The routing rules are the panel's to remove.
:log info "remote-nodes: removing the router's side"
:do { /system scheduler remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
:do { /system script remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
:do { /ip firewall nat remove [find where comment~"^nasnet:remote-nodes:local:"] } on-error={}
:do { /ip firewall mangle remove [find where comment~"^nasnet:remote-nodes:local:"] } on-error={}
:do { /ip firewall address-list remove [find where list="nasnet-remote-nodes-local" && comment~"^nasnet:remote-nodes:local:"] } on-error={}
:log info "remote-nodes: the router's side is removed"
