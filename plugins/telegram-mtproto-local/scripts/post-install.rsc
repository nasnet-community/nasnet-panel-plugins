# The container is up: one more run writes router/state for it at once,
# instead of within the minute. Nothing else is exposed.
:do { /system script run nasnet-mtproto-local } on-error={ :log warning "telegram-mtproto-local: the router script failed" }
:log info "telegram-mtproto-local: installed"
