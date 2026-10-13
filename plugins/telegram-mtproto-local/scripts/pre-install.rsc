# telegram-mtproto-local: the router's side of Local MTProto, as a script that runs
# every minute. It keeps the proxy's rules in place (192.168.50.13, telemt on 8443),
# picks a random port for it on the domestic link, moves it when the plugin asks,
# and leaves the plugin what only the router knows in router/state. It writes that
# file only when something changed, to spare the flash.
# Every local is named mtl...: in a "find where", a variable named like a property
# (list, name, port) reads as that property, which matches everything.
:log info "telegram-mtproto-local: setting up the router's side"
:do { /system scheduler remove [find where name="nasnet-mtproto-local"] } on-error={}
:do { /system script remove [find where name="nasnet-mtproto-local"] } on-error={}
/system script add name="nasnet-mtproto-local" policy=ftp,read,write,test comment="nasnet:telegram-mtproto-local:sync" source={
:local mtlTag "nasnet:telegram-mtproto-local"
:local mtlList "nasnet-mtproto-local-public"
:local mtlProxy "192.168.50.13"
:local mtlCover "192.168.50.14"
:local mtlInner 8443

:local mtlMount [/container mounts find where list="mtproto-local-data"]
:if ([:len $mtlMount] > 0) do={
    :local mtlDir [/container mounts get ($mtlMount->0) src]
    :if ([:pick $mtlDir 0 1] = "/") do={ :set mtlDir [:pick $mtlDir 1 [:len $mtlDir]] }
    :do { /file add name=($mtlDir . "/router") type=directory } on-error={}

    # phones come in on the domestic link; Telegram goes out the foreign one
    :local mtlDomestic ([:len [/interface list member find where list="Domestic-WAN"]] > 0 && [:len [/routing table find where name="to-Domestic"]] > 0 && [:len [/routing table find where name="to-Foreign"]] > 0)

    # the port: the forward's, else the last one written down (a firewall reset loses the rule)
    :local mtlPort 0
    :local fwd [/ip firewall nat find where comment=($mtlTag . ":forward")]
    :if ([:len $fwd] > 0) do={ :set mtlPort [:tonum [/ip firewall nat get ($fwd->0) dst-port]] }
    :local stateFile [/file find where name=($mtlDir . "/router/state")]
    :if ($mtlPort = 0 && [:len $stateFile] > 0) do={
        :local old [/file get ($stateFile->0) contents]
        :local at [:find $old "port="]
        :if ([:typeof $at] = "num") do={ :set mtlPort [:tonum [:pick $old ($at + 5) [:find $old "\n" $at]]] }
        :if ([:typeof $mtlPort] != "num") do={ :set mtlPort 0 }
    }

    :local renew false
    :local req [/file find where name=($mtlDir . "/router/request")]
    :if ([:len $req] > 0) do={
        :if ([/file get ($req->0) contents] ~ "^new-port") do={ :set renew true }
        /file remove $req
    }

    :if ($mtlDomestic) do={
        :if ($mtlPort = 0 || $renew) do={
            :local next 0
            :for i from=1 to=50 do={
                :if ($next = 0) do={
                    :local p [:rndnum from=20000 to=60000]
                    :if ($p != $mtlPort && [:len [/ip firewall nat find where dst-port=[:tostr $p]]] = 0) do={ :set next $p }
                }
            }
            :if ($next != 0) do={
                :if ($mtlPort != 0) do={ :log info ("telegram-mtproto-local: the proxy moves from port " . $mtlPort . " to " . $next) }
                :set mtlPort $next
            }
        }

        # dstnat: the forward from the domestic link, and the hairpin for phones at home
        :local firstNat [/ip firewall nat find where chain=dstnat && !(comment~("^" . $mtlTag))]
        :foreach role in={"forward";"hairpin"} do={
            :local id [/ip firewall nat find where comment=($mtlTag . ":" . $role)]
            :if ([:len $id] > 0) do={
                :if ([:tonum [/ip firewall nat get ($id->0) dst-port]] != $mtlPort) do={ /ip firewall nat set $id dst-port=$mtlPort }
            } else={
                :local id2
                :if ($role = "forward") do={
                    :set id2 [/ip firewall nat add chain=dstnat action=dst-nat protocol=tcp in-interface-list=Domestic-WAN dst-port=$mtlPort to-addresses=$mtlProxy to-ports=$mtlInner comment=($mtlTag . ":forward")]
                } else={
                    :set id2 [/ip firewall nat add chain=dstnat action=dst-nat protocol=tcp in-interface-list=!WAN dst-address-list=$mtlList dst-port=$mtlPort to-addresses=$mtlProxy to-ports=$mtlInner comment=($mtlTag . ":hairpin")]
                }
                :if ([:len $firstNat] > 0) do={ /ip firewall nat move $id2 destination=($firstNat->0) }
            }
        }

        # mangle, ahead of the wizard's rules: the hairpin is not routed away, replies and
        # cover-site fetches (from .14) go back out the domestic link, the rest (Telegram) out the foreign one
        :local firstMangle [/ip firewall mangle find where chain=prerouting && !(comment~("^" . $mtlTag))]
        :foreach role in={"hairpin";"replies";"cover";"foreign"} do={
            :local id [/ip firewall mangle find where comment=($mtlTag . ":" . $role)]
            :if ([:len $id] > 0) do={
                :if ($role = "hairpin" && [:tonum [/ip firewall mangle get ($id->0) dst-port]] != $mtlPort) do={ /ip firewall mangle set $id dst-port=$mtlPort }
            } else={
                :local id2
                :if ($role = "hairpin") do={ :set id2 [/ip firewall mangle add chain=prerouting action=accept protocol=tcp in-interface-list=!WAN dst-address-list=$mtlList dst-port=$mtlPort comment=($mtlTag . ":hairpin")] }
                :if ($role = "replies") do={ :set id2 [/ip firewall mangle add chain=prerouting action=mark-routing new-routing-mark=to-Domestic passthrough=no protocol=tcp src-address=$mtlProxy src-port=$mtlInner dst-address-list=!LOCAL-IP comment=($mtlTag . ":replies")] }
                :if ($role = "cover") do={ :set id2 [/ip firewall mangle add chain=prerouting action=mark-routing new-routing-mark=to-Domestic passthrough=no src-address=$mtlCover dst-address-list=!LOCAL-IP comment=($mtlTag . ":cover")] }
                :if ($role = "foreign") do={ :set id2 [/ip firewall mangle add chain=prerouting action=mark-routing new-routing-mark=to-Foreign passthrough=no src-address=$mtlProxy dst-address-list=!LOCAL-IP comment=($mtlTag . ":foreign")] }
                :if ([:len $firstMangle] > 0) do={ /ip firewall mangle move $id2 destination=($firstMangle->0) }
            }
        }
    }

    # what only the router knows
    :local mtlCloudName ""
    :local mtlPublic ""
    :local mtlCloud ""
    :do { :set mtlCloudName [/ip cloud get dns-name] } on-error={}
    :do { :set mtlPublic [/ip cloud get public-address] } on-error={}
    :do { :set mtlCloud [/ip cloud get status] } on-error={}
    :local mtlWan ""
    :foreach m in=[/interface list member find where list="Domestic-WAN"] do={
        :local ifn [/interface list member get $m interface]
        :foreach a in=[/ip address find where interface=$ifn] do={
            :if ($mtlWan = "") do={
                :local cidr [/ip address get $a address]
                :set mtlWan [:pick $cidr 0 [:find $cidr "/"]]
            }
        }
    }

    # the hairpin catches what phones at home dial: the public address, the router's own, an address set by hand
    :local mtlWant [:toarray ""]
    :if ([:len $mtlPublic] > 0) do={ :set mtlWant ($mtlWant, $mtlPublic) }
    :if ([:len $mtlWan] > 0) do={ :set mtlWant ($mtlWant, $mtlWan) }
    :local hostFile [/file find where name=($mtlDir . "/router/host")]
    :if ([:len $hostFile] > 0) do={
        :local mtlHost [/file get ($hostFile->0) contents]
        :local nl [:find $mtlHost "\n"]
        :if ([:typeof $nl] = "num") do={ :set mtlHost [:pick $mtlHost 0 $nl] }
        :if ([:len $mtlHost] > 0) do={ :do { :set mtlWant ($mtlWant, [:resolve $mtlHost]) } on-error={} }
    }
    # only entries this script added, whatever goes wrong above
    :foreach e in=[/ip firewall address-list find where list=$mtlList && comment=($mtlTag . ":public")] do={
        :if ([:len [:find $mtlWant [/ip firewall address-list get $e address]]] = 0) do={ /ip firewall address-list remove $e }
    }
    :foreach ip in=$mtlWant do={
        :if ([:len [/ip firewall address-list find where list=$mtlList && address=$ip && comment=($mtlTag . ":public")]] = 0) do={
            :do { /ip firewall address-list add list=$mtlList address=$ip comment=($mtlTag . ":public") } on-error={}
        }
    }

    :local mtlDom "no"
    :if ($mtlDomestic) do={ :set mtlDom "yes" }
    :local mtlState ("port=" . $mtlPort . "\naddress=" . $mtlCloudName . "\npublic=" . $mtlPublic . "\nwan=" . $mtlWan . "\ncloud=" . $mtlCloud . "\ndomestic=" . $mtlDom . "\nscript=1\n")
    :set stateFile [/file find where name=($mtlDir . "/router/state")]
    :if ([:len $stateFile] = 0) do={
        /file add name=($mtlDir . "/router/state") contents=$mtlState
    } else={
        :if ([/file get ($stateFile->0) contents] != $mtlState) do={ /file set ($stateFile->0) contents=$mtlState }
    }
}
}
/system scheduler add name="nasnet-mtproto-local" interval=1m policy=ftp,read,write,test on-event="/system script run nasnet-mtproto-local" comment="nasnet:telegram-mtproto-local:sync"
:do { /system script run nasnet-mtproto-local } on-error={ :log warning "telegram-mtproto-local: the router script failed its first run" }
:log info "telegram-mtproto-local: the router's side is ready"
