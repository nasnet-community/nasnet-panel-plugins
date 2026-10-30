# Remove only what pre-install.rsc added: the facts script and its two schedulers.
# The data folder stays, router/state with it: it holds what the nodes trust, and the
# panel decides whether it goes. The routing rules are the panel's to remove.
:log info "remote-nodes: removing the router's side"
:do { /system scheduler remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
:do { /system script remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
:log info "remote-nodes: the router's side is removed"
