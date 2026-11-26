# telegram-mtproto: the router routes the container by its exit class addresses
# (192.168.150.11 out the domestic link, 192.168.150.91 out the foreign one), which the
# panel sets up. 192.168.50.11 is only its page now, so the two rules older versions
# added for it go.
:log info "telegram-mtproto: removing the routing rules older versions added for 192.168.50.11"
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:domestic"] } on-error={}
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:foreign"] } on-error={}
