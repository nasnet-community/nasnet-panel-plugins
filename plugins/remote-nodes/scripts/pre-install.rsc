# remote-nodes: the router's side of Remote Nodes.
# This file runs at install and again after a wizard run, which wipes every script and
# scheduler on the router. It only puts things back, so running it twice does no harm.
#
# It adds one script, nasnet-remote-nodes-facts, and two schedulers that run it: one at
# boot and one every 5 minutes. The script leaves the plugin what only the router knows
# in router/state under the plugin's data folder (container path /data/router/state),
# as key=value lines. The plugin reads exactly these keys:
#   domestic=1|0         a domestic link exists and is up: Domestic-WAN has an interface
#                        that is on and running, and the table to-Domestic exists
#   vpn=1|0              VPN-WAN has an interface that is on and running
#   vpn_kind=            wireguard, l2tp, openvpn or other; empty when VPN-WAN is empty
#   vpn_label=           name of that interface, the first one that is up or else the
#                        first one listed; empty when there is none
#   route_foreign=1|0    the table to-Foreign has an active default route that is not
#                        a blackhole
#   route_vpn=1|0        the same for to-VPN
#   route_domestic=1|0   the same for to-Domestic
#   ros=                 RouterOS version, like 7.24.5
#   free_mem=            free memory in bytes
#   free_disk=           free flash in bytes (free-hdd-space)
#   updated=             unix time of the last write, under 10 minutes ago while the script runs
# A value runs from the first equals sign to the end of its line. The keys above come
# in this order, and free_mem, free_disk and updated come last.
#
# The file is rewritten only when a fact changed or the last write is 10 minutes old,
# to spare the flash. RouterOS cannot replace a file atomically: it will not rename one
# over another, and before 7.15 it cannot rename at all, which also stops a script that
# spells it out from compiling. So the file is rewritten in place, and a reader that
# finds it empty, or without updated=, should look again.
#
# The script itself uses nothing newer than 7.11, which has no :tonsec and cannot add a folder with
# /file add, so the router folder is made by putting the first file into it.
#
# Every local is named rnf...: in a find where, a variable named like a property
# (list, name, address) reads as that property, which matches everything.
:log info "remote-nodes: setting up the router's side"

# the plugin needs 7.20 (several addresses on a veth, mount lists, container memory limits), so stop here
:local rnfVer [/system resource get version]
:local rnfMajor 0
:local rnfMinor 0
:local rnfDot [:find $rnfVer "."]
:if ([:typeof $rnfDot] = "num") do={
    :set rnfMajor [:tonum [:pick $rnfVer 0 $rnfDot]]
    :local rnfRest [:pick $rnfVer ($rnfDot + 1) [:len $rnfVer]]
    :local rnfDigits ""
    :local rnfDone false
    :if ([:len $rnfRest] > 0) do={
        :for rnfI from=0 to=([:len $rnfRest] - 1) do={
            :local rnfCh [:pick $rnfRest $rnfI ($rnfI + 1)]
            :if (($rnfDone = false) && ($rnfCh ~ "[0-9]")) do={ :set rnfDigits ($rnfDigits . $rnfCh) } else={ :set rnfDone true }
        }
    }
    :if ([:len $rnfDigits] > 0) do={ :set rnfMinor [:tonum $rnfDigits] }
}
:if ([:typeof $rnfMajor] != "num") do={ :set rnfMajor 0 }
:if ([:typeof $rnfMinor] != "num") do={ :set rnfMinor 0 }
:if (($rnfMajor < 7) || (($rnfMajor = 7) && ($rnfMinor < 20))) do={
    :log error ("remote-nodes: RouterOS " . $rnfVer . " is too old, 7.20 or newer is needed")
    :error ("Remote Nodes needs RouterOS 7.20 or newer, this router runs " . $rnfVer)
}

# start clean: either nothing of ours is here yet, or the wizard wiped it
:do { /system scheduler remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
:do { /system script remove [find where comment~"^nasnet:remote-nodes:"] } on-error={}
/system script add name="nasnet-remote-nodes-facts" policy=ftp,read,write,test comment="nasnet:remote-nodes:facts" source={
:local rnfMount [/container mounts find where list="remote-nodes-data"]
:if ([:len $rnfMount] > 0) do={
    :local rnfDir [/container mounts get ($rnfMount->0) src]
    :if (([:len $rnfDir] > 0) && ([:pick $rnfDir 0 1] = "/")) do={ :set rnfDir [:pick $rnfDir 1 [:len $rnfDir]] }

    # a domestic link: Domestic-WAN has an interface that is on and running, and its table exists
    # (these lists are short, only their first 16 entries are looked at)
    :local rnfDomestic 0
    :if ([:len [/routing table find where name="to-Domestic"]] > 0) do={
        :local rnfSeenD 0
        :foreach rnfM in=[/interface list member find where list="Domestic-WAN"] do={
            :set rnfSeenD ($rnfSeenD + 1)
            :if ($rnfSeenD <= 16) do={
                :local rnfIf [/interface list member get $rnfM interface]
                :do {
                    :if (([/interface get $rnfIf running] = true) && ([/interface get $rnfIf disabled] = false)) do={ :set rnfDomestic 1 }
                } on-error={}
            }
        }
    }

    # a VPN: VPN-WAN has an interface that is on and running; kind and label are the first
    # one that is up, or else the first one listed
    :local rnfVpn 0
    :local rnfVpnKind ""
    :local rnfVpnLabel ""
    :local rnfSeenV 0
    :foreach rnfV in=[/interface list member find where list="VPN-WAN"] do={
        :set rnfSeenV ($rnfSeenV + 1)
        :if ($rnfSeenV <= 16) do={
            :local rnfName [/interface list member get $rnfV interface]
            :local rnfUp false
            :do { :set rnfUp (([/interface get $rnfName running] = true) && ([/interface get $rnfName disabled] = false)) } on-error={}
            :if (($rnfVpn = 0) && (($rnfUp = true) || ([:len $rnfVpnLabel] = 0))) do={
                :local rnfType ""
                :do { :set rnfType [/interface get $rnfName type] } on-error={}
                :set rnfVpnLabel $rnfName
                :set rnfVpnKind "other"
                :if ($rnfType = "wg") do={ :set rnfVpnKind "wireguard" }
                :if ($rnfType = "l2tp-out") do={ :set rnfVpnKind "l2tp" }
                :if ($rnfType = "ovpn-out") do={ :set rnfVpnKind "openvpn" }
                :if ($rnfUp = true) do={ :set rnfVpn 1 }
            }
        }
    }

    # a usable default route per table: active, with a gateway, and not the wizard's blackhole;
    # a table that is missing has no routes, so it counts as 0
    :local rnfRoutes ""
    :foreach rnfRole in={"foreign";"vpn";"domestic"} do={
        :local rnfTable "to-Foreign"
        :if ($rnfRole = "vpn") do={ :set rnfTable "to-VPN" }
        :if ($rnfRole = "domestic") do={ :set rnfTable "to-Domestic" }
        :local rnfUsable 0
        :do {
            :if ([:len [/routing table find where name=$rnfTable]] > 0) do={
                :foreach rnfR in=[/ip route find where routing-table=$rnfTable && dst-address="0.0.0.0/0" && active=yes] do={
                    :local rnfGw ""
                    :local rnfBlack ""
                    :do { :set rnfGw [:tostr [/ip route get $rnfR gateway]] } on-error={}
                    :do { :set rnfBlack [:tostr [/ip route get $rnfR blackhole]] } on-error={}
                    :if (([:len $rnfGw] > 0) && ($rnfBlack != "true")) do={ :set rnfUsable 1 }
                }
            }
        } on-error={}
        :set rnfRoutes ($rnfRoutes . "route_" . $rnfRole . "=" . $rnfUsable . "\n")
    }

    # the router itself; the version comes as 7.24.5 (stable), keep the number
    :local rnfRos ""
    :do { :set rnfRos [/system resource get version] } on-error={}
    :local rnfSp [:find $rnfRos " "]
    :if ([:typeof $rnfSp] = "num") do={ :set rnfRos [:pick $rnfRos 0 $rnfSp] }
    :local rnfMem 0
    :local rnfDisk 0
    :do { :set rnfMem [/system resource get free-memory] } on-error={}
    :do { :set rnfDisk [/system resource get free-hdd-space] } on-error={}
    # unix time from :timestamp, which prints like 2965w1d16:30:11.7 and leaves the day
    # out on Thursdays; :tonsec would be shorter but is new in 7.12
    :local rnfNow 0
    :do {
        :local rnfT [:tostr [:timestamp]]
        :local rnfAtW [:find $rnfT "w"]
        :local rnfAtD [:find $rnfT "d"]
        :local rnfFrom ($rnfAtW + 1)
        :local rnfDays 0
        :if ([:typeof $rnfAtD] = "num") do={
            :set rnfDays [:tonum [:pick $rnfT ($rnfAtW + 1) $rnfAtD]]
            :set rnfFrom ($rnfAtD + 1)
        }
        :local rnfWeeks [:tonum [:pick $rnfT 0 $rnfAtW]]
        :local rnfHours [:tonum [:pick $rnfT $rnfFrom ($rnfFrom + 2)]]
        :local rnfMins [:tonum [:pick $rnfT ($rnfFrom + 3) ($rnfFrom + 5)]]
        :local rnfSecs [:tonum [:pick $rnfT ($rnfFrom + 6) ($rnfFrom + 8)]]
        :set rnfNow (((($rnfWeeks * 604800) + ($rnfDays * 86400)) + ($rnfHours * 3600)) + (($rnfMins * 60) + $rnfSecs))
    } on-error={}
    :if ([:typeof $rnfNow] != "num") do={ :set rnfNow 0 }

    # the facts, then what changes all the time
    :local rnfState ("domestic=" . $rnfDomestic . "\nvpn=" . $rnfVpn . "\nvpn_kind=" . $rnfVpnKind . "\nvpn_label=" . $rnfVpnLabel . "\n" . $rnfRoutes . "ros=" . $rnfRos . "\n")
    :local rnfText ($rnfState . "free_mem=" . $rnfMem . "\nfree_disk=" . $rnfDisk . "\nupdated=" . $rnfNow . "\n")

    # leave the file alone when the facts are the same and it was written under 10 minutes ago
    :local rnfFile ($rnfDir . "/router/state")
    :local rnfOld ""
    :local rnfCur [/file find where name=$rnfFile]
    :if ([:len $rnfCur] > 0) do={ :do { :set rnfOld [/file get ($rnfCur->0) contents] } on-error={} }
    :local rnfSame false
    :do {
        :local rnfAtMem [:find $rnfOld "free_mem="]
        :local rnfAtUp [:find $rnfOld "updated="]
        :if (([:typeof $rnfAtMem] = "num") && ([:typeof $rnfAtUp] = "num")) do={
            :local rnfWas [:tonum [:pick $rnfOld ($rnfAtUp + 8) ([:len $rnfOld] - 1)]]
            :if (([:typeof $rnfWas] = "num") && ($rnfNow >= $rnfWas) && (($rnfNow - $rnfWas) < 600) && ([:pick $rnfOld 0 $rnfAtMem] = $rnfState)) do={ :set rnfSame true }
        }
    } on-error={}
    :if ($rnfSame = false) do={
        :do {
            :if ([:len $rnfCur] > 0) do={ /file set ($rnfCur->0) contents=$rnfText } else={ /file add name=$rnfFile contents=$rnfText }
        } on-error={ :log warning "remote-nodes: could not write router/state" }
    }
}
}
/system scheduler add name="nasnet-remote-nodes-facts" interval=5m policy=ftp,read,write,test on-event="/system script run nasnet-remote-nodes-facts" comment="nasnet:remote-nodes:facts"
/system scheduler add name="nasnet-remote-nodes-facts-boot" start-time=startup policy=ftp,read,write,test on-event=":delay 60s; /system script run nasnet-remote-nodes-facts" comment="nasnet:remote-nodes:facts-boot"
:do { /system script run nasnet-remote-nodes-facts } on-error={ :log warning "remote-nodes: the facts script failed on its first run" }
:log info "remote-nodes: the router's side is ready"
