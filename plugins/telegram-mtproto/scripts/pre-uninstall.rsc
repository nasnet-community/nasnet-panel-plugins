# Remove only what pre-install.rsc added. The wizard's own rules carry different comments and stay.
:log info "telegram-mtproto: removing routing rules added by the plugin"
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:domestic"] } on-error={}
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:foreign"] } on-error={}
