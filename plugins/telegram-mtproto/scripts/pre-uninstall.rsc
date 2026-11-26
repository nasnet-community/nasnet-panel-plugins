# Remove only the rules older versions of pre-install.rsc added. The wizard's own rules
# carry different comments and stay, and the exit classes are every container's.
:log info "telegram-mtproto: removing routing rules added by the plugin"
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:domestic"] } on-error={}
:do { /ip/firewall/mangle remove [find where comment="nasnet:telegram-mtproto:foreign"] } on-error={}
