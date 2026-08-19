#
# model = C53UiG+5HPaxD2HPaxD
/interface bridge
add comment="Foreign Table Address Holder" name=FTAH
add comment=Domestic name=LANBridgeDomestic
add comment="Domestic-Domestic Link" name="LANBridgeDomestic-Domestic Link"
add comment=Foreign name=LANBridgeForeign
add comment="Foreign-Foreign Link" name="LANBridgeForeign-Foreign Link"
add comment=Split name=LANBridgeSplit
add comment=VPN name=LANBridgeVPN
/interface ethernet
set [ find default-name=ether1 ] comment="Split Network"
set [ find default-name=ether2 ] comment="WAN - Domestic Link"
set [ find default-name=ether3 ] comment="Split Network"
set [ find default-name=ether4 ] comment="WAN - Foreign Link"
set [ find default-name=ether5 ] comment="Split Network"
/interface macvlan
add comment="Domestic Link MACVLAN on ether2" interface=ether2 mac-address=\
    02:00:00:00:00:03 mode=private name="MacVLAN-ether2-Domestic Link"
add comment="Foreign Link MACVLAN on ether4" interface=ether4 mac-address=\
    02:00:00:00:00:04 mode=private name="MacVLAN-ether4-Foreign Link"
/interface list
add name=WAN
add name=LAN
add comment=Split name=Split-WAN
add comment=Split name=Split-LAN
add comment=Domestic name=Domestic-WAN
add comment=Domestic name=Domestic-LAN
add comment="Domestic-Domestic Link" name="Domestic-Domestic Link-WAN"
add comment="Domestic-Domestic Link" name="Domestic-Domestic Link-LAN"
add comment=Foreign name=Foreign-WAN
add comment=Foreign name=Foreign-LAN
add comment=VPN name=VPN-WAN
add comment=VPN name=VPN-LAN
add comment="Foreign-Foreign Link" name="Foreign-Foreign Link-WAN"
add comment="Foreign-Foreign Link" name="Foreign-Foreign Link-LAN"
/interface wifi steering
add comment=Steering disabled=no name=Steering neighbor-group=\
    wifi5-SplitLAN,wifi2.4-SplitLAN rrm=yes wnm=yes
/interface wifi
set [ find default-name=wifi2 ] channel.band=2ghz-ax .skip-dfs-channels=\
    10min-cac .width=20/40mhz comment="Split Network" configuration.country=\
    "United States" .hide-ssid=no .installation=indoor .mode=ap .ssid=NASNET \
    disabled=no name=wifi2.4-SplitLAN security.authentication-types=\
    wpa2-psk,wpa3-psk .ft=yes .ft-over-ds=yes steering=Steering
set [ find default-name=wifi1 ] channel.band=5ghz-ax .skip-dfs-channels=\
    10min-cac .width=20/40/80mhz comment="Split Network" \
    configuration.country="United States" .hide-ssid=no .installation=indoor \
    .mode=ap .ssid=NASNET disabled=no name=wifi5-SplitLAN \
    security.authentication-types=wpa2-psk,wpa3-psk .ft=yes .ft-over-ds=yes \
    steering=Steering
add comment="Management WiFi" configuration.mode=ap .ssid=NASNET-Management \
    disabled=no mac-address=02:00:00:00:00:02 master-interface=wifi5-SplitLAN \
    name=wifi-management security.authentication-types=wpa2-psk,wpa3-psk
/ip dns forwarders
add dns-servers=4.2.2.2 name=VPN verify-doh-cert=no
add dns-servers=217.218.127.127 name=Domestic verify-doh-cert=no
add dns-servers=4.2.2.1 name=Foreign verify-doh-cert=no
add dns-servers=4.2.2.2,217.218.127.127,4.2.2.1 name=General verify-doh-cert=\
    no
/ip pool
add comment=Split name=DHCP-pool-Split ranges=192.168.10.2-192.168.10.254
add comment="Management Wifi" name=DHCP-pool-management-wifi ranges=\
    192.168.210.2-192.168.210.254
add comment=Domestic name=DHCP-pool-Domestic ranges=\
    192.168.20.2-192.168.20.254
add comment="Domestic-Domestic Link" name="DHCP-pool-Domestic-Domestic Link" \
    ranges=192.168.21.2-192.168.21.254
add comment=Foreign name=DHCP-pool-Foreign ranges=192.168.30.2-192.168.30.254
add comment=VPN name=DHCP-pool-VPN ranges=192.168.40.2-192.168.40.254
add comment="Foreign-Foreign Link" name="DHCP-pool-Foreign-Foreign Link" \
    ranges=192.168.31.2-192.168.31.254
add comment="VPN-VPN client pool" name=VPN-VPN-pool ranges=\
    192.168.120.2-192.168.120.254
add comment="VPN-Split client pool" name=VPN-Split-pool ranges=\
    192.168.121.2-192.168.121.254
add comment="VPN-Foreign client pool" name=VPN-Foreign-pool ranges=\
    192.168.122.2-192.168.122.254
/ppp profile
add address-list=VPN-LAN comment="Inbound: VPN -> Outbound: VPN" dns-server=\
    192.168.120.1 interface-list=VPN-LAN local-address=192.168.120.1 name=\
    VPN-VPN remote-address=VPN-VPN-pool use-encryption=yes use-ipv6=no \
    use-upnp=yes
add address-list=Split-LAN comment="Inbound: VPN -> Outbound: Split" \
    dns-server=192.168.121.1 interface-list=Split-LAN local-address=\
    192.168.121.1 name=VPN-Split remote-address=VPN-Split-pool \
    use-encryption=yes use-ipv6=no use-upnp=yes
add address-list=Foreign-LAN comment="Inbound: VPN -> Outbound: Foreign" \
    dns-server=192.168.122.1 interface-list=Foreign-LAN local-address=\
    192.168.122.1 name=VPN-Foreign remote-address=VPN-Foreign-pool \
    use-encryption=yes use-ipv6=no use-upnp=yes
/routing table
add comment=Split fib name=to-Split
add comment=Domestic fib name=to-Domestic
add comment="Domestic-Domestic Link" fib name="to-Domestic-Domestic Link"
add comment=Foreign fib name=to-Foreign
add comment=VPN fib name=to-VPN
add comment="Foreign-Foreign Link" fib name="to-Foreign-Foreign Link"
/system logging action
add disk-file-count=10 disk-file-name=PanelLog disk-lines-per-file=100 \
    disk-stop-on-full=yes name=DiskC target=disk
/system script
add dont-require-permissions=no name=wizard owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=\
    ":execute script={import wizard.rsc}"
add dont-require-permissions=no name=VPNE-Routing-Manager owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    \_========================================================================\
    ====\r\
    \n# Script: VPNE Address List to Routing Rules Manager v7.0\r\
    \n# Description: Links domain entries with their dynamic IP entries and cr\
    eates\r\
    \n#              routing rules using WanInterface from the parent domain e\
    ntry\r\
    \n# Version: 7.0 - Uses format validation instead of :toip for IP detectio\
    n\r\
    \n# ======================================================================\
    ======\r\
    \n# Configuration variables\r\
    \n:local addressListName \"VPNE\"\r\
    \n:local scriptName \"VPNE-Route-Manager\"\r\
    \n:local debugMode false\r\
    \n:local quietMode false\r\
    \n:local tablePrefix \"to-\"\r\
    \n# Statistics counters\r\
    \n:local totalProcessed 0\r\
    \n:local rulesCreated 0\r\
    \n:local rulesUpdated 0\r\
    \n:local skipped 0\r\
    \n:local dynamicProcessed 0\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] ===== Starting VPNE routing rules update v7.\
    0 =====\"\r\
    \n:log debug \"[\$scriptName] Using format-based IP validation to avoid do\
    main resolution\"\r\
    \n}\r\
    \n# ======================================================================\
    ======\r\
    \n# Function to check if string is IP format (contains only digits and dot\
    s)\r\
    \n# ======================================================================\
    ======\r\
    \n:local isIPFormat do={\r\
    \n:local addr \$1\r\
    \n:local isIP true\r\
    \n# Check if it contains any letters (domains have letters, IPs don't)\r\
    \n:local letters \"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\"\
    \r\
    \n:for i from=0 to=([:len \$addr] - 1) do={\r\
    \n:local char [:pick \$addr \$i (\$i + 1)]\r\
    \n:if ([:find \$letters \$char] >= 0) do={\r\
    \n:set isIP false\r\
    \n}\r\
    \n}\r\
    \n# Additional check: must have at least one dot and start with a digit\r\
    \n:if (\$isIP && [:find \$addr \".\"] < 0) do={\r\
    \n:set isIP false\r\
    \n}\r\
    \n:return \$isIP\r\
    \n}\r\
    \n# ======================================================================\
    ======\r\
    \n# Step 1: First pass - collect domain entries with WanInterface\r\
    \n# ======================================================================\
    ======\r\
    \n:local domainMap [:toarray \"\"]\r\
    \n:foreach entry in=[/ip firewall address-list find list=\$addressListName\
    \_dynamic=no] do={\r\
    \n# Get entry properties\r\
    \n:local addr [/ip firewall address-list get \$entry address]\r\
    \n:local comment [/ip firewall address-list get \$entry comment]\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Checking domain entry: \$addr\"\r\
    \n}\r\
    \n# Extract WanInterface from comment\r\
    \n:local wanInterface \"\"\r\
    \n:local wanStartPos [:find \$comment \"WanInterface:\"]\r\
    \n:if ([:typeof \$wanStartPos] != \"nil\") do={\r\
    \n:local wanValueStart (\$wanStartPos + 13)\r\
    \n:local endpointMarkerPos [:find \$comment \" Endpoint:\" \$wanValueStart\
    ]\r\
    \n:if ([:typeof \$endpointMarkerPos] != \"nil\") do={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart \$endpointMarkerPos]\
    \r\
    \n} else={\r\
    \n:local dashPos [:find \$comment \" -\" \$wanValueStart]\r\
    \n:if ([:typeof \$dashPos] != \"nil\") do={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart \$dashPos]\r\
    \n} else={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart]\r\
    \n}\r\
    \n}\r\
    \n:if ([:len \$wanInterface] > 0) do={\r\
    \n# Store domain with its WanInterface\r\
    \n:set (\$domainMap->\$addr) \$wanInterface\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Found domain \$addr with WanInterface: \$wan\
    Interface\"\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# ======================================================================\
    ======\r\
    \n# Step 2: Process all entries (both static and dynamic)\r\
    \n# ======================================================================\
    ======\r\
    \n:foreach entry in=[/ip firewall address-list find list=\$addressListName\
    ] do={\r\
    \n:set totalProcessed (\$totalProcessed + 1)\r\
    \n# Get entry properties\r\
    \n:local addr [/ip firewall address-list get \$entry address]\r\
    \n:local comment [/ip firewall address-list get \$entry comment]\r\
    \n:local dynamic [/ip firewall address-list get \$entry dynamic]\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Processing entry: \$addr (dynamic=\$dynamic,\
    \_comment=\$comment)\"\r\
    \n}\r\
    \n# ========== NEW IP FORMAT VALIDATION ==========\r\
    \n:local isValidIP [\$isIPFormat \$addr]\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Format check for \$addr: isIP=\$isValidIP\"\
    \r\
    \n}\r\
    \n# If NOT a valid IP format, skip immediately\r\
    \n:if (!\$isValidIP) do={\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] >>> SKIPPING DOMAIN ENTRY: \$addr (contains \
    letters, not an IP)\"\r\
    \n}\r\
    \n:set skipped (\$skipped + 1)\r\
    \n} else={\r\
    \n# ===== ONLY PROCESS VALID IP ADDRESSES =====\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] >>> VALID IP FORMAT: \$addr - proceeding wit\
    h processing\"\r\
    \n}\r\
    \n:local wanInterface \"\"\r\
    \n:local endpoint \"\"\r\
    \n:if (\$dynamic = true) do={\r\
    \n# For dynamic entries, the comment is usually the domain name\r\
    \n:if ([:typeof (\$domainMap->\$comment)] != \"nil\") do={\r\
    \n:set wanInterface (\$domainMap->\$comment)\r\
    \n:set endpoint \$comment\r\
    \n:set dynamicProcessed (\$dynamicProcessed + 1)\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Dynamic entry \$addr linked to domain \$comm\
    ent with WanInterface: \$wanInterface\"\r\
    \n}\r\
    \n} else={\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Dynamic entry \$addr has no matching domain \
    entry, skipping\"\r\
    \n}\r\
    \n:set skipped (\$skipped + 1)\r\
    \n}\r\
    \n} else={\r\
    \n# For static IP entries, extract WanInterface from comment\r\
    \n:local wanStartPos [:find \$comment \"WanInterface:\"]\r\
    \n:if ([:typeof \$wanStartPos] != \"nil\") do={\r\
    \n:local wanValueStart (\$wanStartPos + 13)\r\
    \n:local endpointMarkerPos [:find \$comment \" Endpoint:\" \$wanValueStart\
    ]\r\
    \n:if ([:typeof \$endpointMarkerPos] != \"nil\") do={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart \$endpointMarkerPos]\
    \r\
    \n} else={\r\
    \n:local dashPos [:find \$comment \" -\" \$wanValueStart]\r\
    \n:if ([:typeof \$dashPos] != \"nil\") do={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart \$dashPos]\r\
    \n} else={\r\
    \n:set wanInterface [:pick \$comment \$wanValueStart]\r\
    \n}\r\
    \n}\r\
    \n# Extract endpoint\r\
    \n:local endpointStartPos [:find \$comment \"Endpoint:\"]\r\
    \n:if ([:typeof \$endpointStartPos] != \"nil\") do={\r\
    \n:local endpointValueStart (\$endpointStartPos + 9)\r\
    \n:local dashMarkerPos [:find \$comment \" -\" \$endpointValueStart]\r\
    \n:if ([:typeof \$dashMarkerPos] != \"nil\") do={\r\
    \n:set endpoint [:pick \$comment \$endpointValueStart \$dashMarkerPos]\r\
    \n} else={\r\
    \n:set endpoint [:pick \$comment \$endpointValueStart]\r\
    \n}\r\
    \n} else={\r\
    \n:set endpoint \$addr\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# Create/Update routing rules only if we have a WanInterface\r\
    \n:if ([:len \$wanInterface] > 0) do={\r\
    \n# Build routing table name\r\
    \n:local routingTable (\$tablePrefix . \$wanInterface)\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Using routing table: \$routingTable for IP: \
    \$addr\"\r\
    \n}\r\
    \n# Check if routing table exists\r\
    \n:local tableExists false\r\
    \n:do {\r\
    \n:local testTable [/routing table find name=\$routingTable]\r\
    \n:if ([:len \$testTable] > 0) do={\r\
    \n:set tableExists true\r\
    \n}\r\
    \n} on-error={\r\
    \n:set tableExists false\r\
    \n}\r\
    \n:if (!\$tableExists) do={\r\
    \n:if (!\$quietMode) do={\r\
    \n:log error \"[\$scriptName] Routing table '\$routingTable' does not exis\
    t, skipping \$addr\"\r\
    \n}\r\
    \n:set skipped (\$skipped + 1)\r\
    \n} else={\r\
    \n:local dstAddress \$addr\r\
    \n:local ruleComment \"VPNE-Resolved: \$endpoint\"\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Preparing rule: dst=\$dstAddress table=\$rou\
    tingTable\"\r\
    \n}\r\
    \n# Check if routing rule already exists\r\
    \n:local existingRule [/routing rule find dst-address=\$dstAddress table=\
    \$routingTable]\r\
    \n:if ([:len \$existingRule] > 0) do={\r\
    \n# Rule exists - verify configuration\r\
    \n:local ruleID [:pick \$existingRule 0]\r\
    \n:local currentAction [/routing rule get \$ruleID action]\r\
    \n:local currentDisabled [/routing rule get \$ruleID disabled]\r\
    \n:local currentComment [/routing rule get \$ruleID comment]\r\
    \n:local needsUpdate false\r\
    \n:if (\$currentAction != \"lookup-only-in-table\") do={\r\
    \n:set needsUpdate true\r\
    \n}\r\
    \n:if (\$currentDisabled = true) do={\r\
    \n:set needsUpdate true\r\
    \n}\r\
    \n:if (\$currentComment != \$ruleComment) do={\r\
    \n:set needsUpdate true\r\
    \n}\r\
    \n:if (\$needsUpdate) do={\r\
    \n:do {\r\
    \n/routing rule set \$ruleID \\\r\
    \naction=lookup-only-in-table \\\r\
    \ndisabled=no \\\r\
    \ncomment=\$ruleComment\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Updated routing rule for \$dstAddress in tab\
    le \$routingTable\"\r\
    \n}\r\
    \n:set rulesUpdated (\$rulesUpdated + 1)\r\
    \n} on-error={\r\
    \n:if (!\$quietMode) do={\r\
    \n:log error \"[\$scriptName] Failed to update routing rule for \$dstAddre\
    ss\"\r\
    \n}\r\
    \n}\r\
    \n} else={\r\
    \n:if (\$debugMode && !\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Routing rule for \$dstAddress in table \$rou\
    tingTable already correct\"\r\
    \n}\r\
    \n}\r\
    \n} else={\r\
    \n# Rule doesn't exist - create new one\r\
    \n:do {\r\
    \n/routing rule add \\\r\
    \ndst-address=\$dstAddress \\\r\
    \naction=lookup-only-in-table \\\r\
    \ntable=\$routingTable \\\r\
    \ndisabled=no \\\r\
    \ncomment=\$ruleComment\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Created routing rule: dst=\$dstAddress table\
    =\$routingTable\"\r\
    \n}\r\
    \n:set rulesCreated (\$rulesCreated + 1)\r\
    \n} on-error={\r\
    \n:if (!\$quietMode) do={\r\
    \n:log error \"[\$scriptName] Failed to create routing rule for \$dstAddre\
    ss in table \$routingTable\"\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# ======================================================================\
    ======\r\
    \n# Step 4: Clean up orphaned routing rules\r\
    \n# ======================================================================\
    ======\r\
    \n:local orphansRemoved 0\r\
    \n:foreach rule in=[/routing rule find comment~\"VPNE-Resolved:\"] do={\r\
    \n:local ruleDst [/routing rule get \$rule dst-address]\r\
    \n:local ruleComment [/routing rule get \$rule comment]\r\
    \n# The IP is now stored without /32\r\
    \n:local ruleIP \$ruleDst\r\
    \n# Check if this IP exists in current address list\r\
    \n:local found false\r\
    \n:foreach entry in=[/ip firewall address-list find list=\$addressListName\
    ] do={\r\
    \n:local entryAddr [/ip firewall address-list get \$entry address]\r\
    \n:if (\$entryAddr = \$ruleIP) do={\r\
    \n:set found true\r\
    \n}\r\
    \n}\r\
    \n:if (!\$found) do={\r\
    \n:do {\r\
    \n/routing rule remove \$rule\r\
    \n:set orphansRemoved (\$orphansRemoved + 1)\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] Removed orphaned routing rule for \$ruleDst\
    \"\r\
    \n}\r\
    \n} on-error={\r\
    \n:if (!\$quietMode) do={\r\
    \n:log warning \"[\$scriptName] Failed to remove orphaned rule for \$ruleD\
    st\"\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# ======================================================================\
    ======\r\
    \n# Final Statistics and Logging\r\
    \n# ======================================================================\
    ======\r\
    \n:if (!\$quietMode) do={\r\
    \n:log debug \"[\$scriptName] ===== VPNE routing rules update completed ==\
    ===\"\r\
    \n:log debug \"[\$scriptName] Statistics: Total=\$totalProcessed Created=\
    \$rulesCreated Updated=\$rulesUpdated\"\r\
    \n:log debug \"[\$scriptName] Dynamic entries processed: \$dynamicProcesse\
    d\"\r\
    \n:log debug \"[\$scriptName] Orphans removed: \$orphansRemoved Skipped=\$\
    skipped\"\r\
    \n}\r\
    \n# End of script"
add dont-require-permissions=no name=DomesticIPUpdate-OneTime owner=admin \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source=":delay 120s\r\
    \n# ======================================================================\
    ========\r\
    \n#  MikroTik Dynamic Address List Updater - Resilient Mode\r\
    \n# ======================================================================\
    ========\r\
    \n# ======================================================================\
    ========\r\
    \n# CONFIGURATION SECTION\r\
    \n# ======================================================================\
    ========\r\
    \n# API Configuration\r\
    \n# TODO(nice-to-have): baseURL is hardcoded per-deployment - lift to a fn\
    \_arg\r\
    \n:local baseURL \"https://s4i.co/irip\"\r\
    \n:local listName \"DOMAddList\"\r\
    \n:local stagingListName (\$listName . \"-new\")\r\
    \n:local logPrefix \"SecureListUpdate\"\r\
    \n# User Tracking Configuration\r\
    \n# Leave empty to disable tracking\r\
    \n:local userId \"4972616e-6973-746f-6265-7265626f726e\"\r\
    \n# ========== SOURCE ROUTING CONFIGURATION ==========\r\
    \n# Specify source address for all HTTP/HTTPS requests\r\
    \n# This forces all fetch operations through the interface with this IP\r\
    \n# TODO(nice-to-have): also hardcoded - should be a generator fn arg\r\
    \n:local sourceAddress \"192.168.39.12\"\r\
    \n# ==================================================\r\
    \n# Pagination Configuration\r\
    \n:local pageSize 1000\r\
    \n:local maxPages 50\r\
    \n:local batchSize 50\r\
    \n# Retry Configuration\r\
    \n:local maxRetries 4\r\
    \n:local retryBaseDelay 5\r\
    \n:local retryMaxDelay 30\r\
    \n# Validation Configuration\r\
    \n# TODO(nice-to-have): expose these as fn args. If upstream legitimately\
    \r\
    \n# shrinks by >30% we'll silently keep stale data forever with no overrid\
    e.\r\
    \n:local minSafeCount 100\r\
    \n:local minBootstrapCount 1000\r\
    \n:local minRetentionPercent 70\r\
    \n# ======================================================================\
    ========\r\
    \n# HELPER FUNCTIONS\r\
    \n# ======================================================================\
    ========\r\
    \n# Function: Clean line endings\r\
    \n:global cleanLine do={\r\
    \n:local line \$1\r\
    \n:if ([:len \$line] = 0) do={ :return \"\" }\r\
    \n# Remove CR\r\
    \n:if ([:pick \$line ([:len \$line] - 1)] = \"\\r\") do={\r\
    \n:set line [:pick \$line 0 ([:len \$line] - 1)]\r\
    \n}\r\
    \n# Trim leading spaces\r\
    \n:while (([:len \$line] > 0) and ([:pick \$line 0 1] = \" \")) do={\r\
    \n:set line [:pick \$line 1 [:len \$line]]\r\
    \n}\r\
    \n# Trim trailing spaces\r\
    \n:while (([:len \$line] > 0) and ([:pick \$line ([:len \$line] - 1)] = \"\
    \_\")) do={\r\
    \n:set line [:pick \$line 0 ([:len \$line] - 1)]\r\
    \n}\r\
    \n:return \$line\r\
    \n}\r\
    \n# Function: Validate address\r\
    \n:global validateAddr do={\r\
    \n:local addr \$1\r\
    \n:local valid false\r\
    \n# Check for CIDR\r\
    \n:if ([:find \$addr \"/\"] > 0) do={\r\
    \n:local slashPos [:find \$addr \"/\"]\r\
    \n:local ipPart [:pick \$addr 0 \$slashPos]\r\
    \n:local maskPart [:pick \$addr (\$slashPos + 1) [:len \$addr]]\r\
    \n:do {\r\
    \n[:toip \$ipPart]\r\
    \n:local maskNum [:tonum \$maskPart]\r\
    \n:if ((\$maskNum >= 0) and (\$maskNum <= 32)) do={\r\
    \n:set valid true\r\
    \n}\r\
    \n} on-error={}\r\
    \n} else={\r\
    \n# Plain IP\r\
    \n:do {\r\
    \n[:toip \$addr]\r\
    \n:set valid true\r\
    \n} on-error={}\r\
    \n}\r\
    \n:return \$valid\r\
    \n}\r\
    \n# Function: Build URL with parameters\r\
    \n:global buildURL do={\r\
    \n:local base \$1\r\
    \n:local format \$2\r\
    \n:local limit \$3\r\
    \n:local offset \$4\r\
    \n:local user \$5\r\
    \n# Start with base URL and required parameters\r\
    \n:local url \"\$base\\\?format=\$format&limit=\$limit&offset=\$offset\"\r\
    \n# Add user_id if provided\r\
    \n:if ([:len \$user] > 0) do={\r\
    \n:set url \"\$url&user_id=\$user\"\r\
    \n}\r\
    \n:return \$url\r\
    \n}\r\
    \n# Function: Calculate retry delay\r\
    \n:global calcRetryDelay do={\r\
    \n:local attempt \$1\r\
    \n:local baseDelay \$2\r\
    \n:local maxDelay \$3\r\
    \n:local delayValue (\$baseDelay * \$attempt)\r\
    \n:if (\$delayValue > \$maxDelay) do={\r\
    \n:set delayValue \$maxDelay\r\
    \n}\r\
    \n:return \$delayValue\r\
    \n}\r\
    \n# ======================================================================\
    ========\r\
    \n# MAIN SCRIPT\r\
    \n# ======================================================================\
    ========\r\
    \n# Prevent concurrent runs (scheduler + manual execution overlap)\r\
    \n# TODO(nice-to-have): pair with a :global domesticIPUpdateStartedAt and\
    \r\
    \n# treat the lock as stale after ~30 min. Today, a manually-killed run\r\
    \n# leaves the lock 'true' until the next reboot clears :global state.\r\
    \n:global domesticIPUpdateRunning\r\
    \n:if ([:typeof \$domesticIPUpdateRunning] = \"nothing\") do={\r\
    \n:set domesticIPUpdateRunning false\r\
    \n}\r\
    \n:if (\$domesticIPUpdateRunning = true) do={\r\
    \n:log warning \"\$logPrefix: Another update is already running, skipping \
    this execution\"\r\
    \n:error \"\$logPrefix: lock already held\"\r\
    \n}\r\
    \n:set domesticIPUpdateRunning true\r\
    \n# Initialize state\r\
    \n:local importSuccessful false\r\
    \n:local startTime [/system clock get time]\r\
    \n:local endTime \"\"\r\
    \n:local previousCount [:len [/ip firewall address-list find list=\$listNa\
    me]]\r\
    \n:local finalCount \$previousCount\r\
    \n:local stagedCount 0\r\
    \n:local minRequired \$minSafeCount\r\
    \n:local totalAdded 0\r\
    \n:local totalInvalid 0\r\
    \n:local successfulPages 0\r\
    \n:local currentOffset 0\r\
    \n:local pageNum 0\r\
    \n:local hasMore true\r\
    \n:local sourceValid false\r\
    \n:do {\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n:log info \"\$logPrefix: Starting Dynamic Address List Import\"\r\
    \n:log info \"\$logPrefix: Using source address: \$sourceAddress\"\r\
    \n:log info \"\$logPrefix: Existing \$listName count before update: \$prev\
    iousCount\"\r\
    \n# Verify source address exists\r\
    \n:set sourceValid false\r\
    \n:do {\r\
    \n:local testIP [/ip address find where address~\"^\$sourceAddress/\"]\r\
    \n:if ([:len \$testIP] > 0) do={\r\
    \n:set sourceValid true\r\
    \n:log info \"\$logPrefix: Source address \$sourceAddress verified\"\r\
    \n}\r\
    \n} on-error={}\r\
    \n:if (\$sourceValid = false) do={\r\
    \n:log warning \"\$logPrefix: Source address \$sourceAddress not found on \
    any interface!\"\r\
    \n:log warning \"\$logPrefix: Proceeding with default routing...\"\r\
    \n}\r\
    \n# Log user tracking status\r\
    \n:if ([:len \$userId] > 0) do={\r\
    \n:log info \"\$logPrefix: User tracking enabled: \$userId\"\r\
    \n} else={\r\
    \n:log info \"\$logPrefix: User tracking disabled (no user_id configured)\
    \"\r\
    \n}\r\
    \n# Prepare staging list\r\
    \n:log info \"\$logPrefix: Cleaning stale staging list entries...\"\r\
    \n/ip firewall address-list remove [find list=\$stagingListName]\r\
    \n# ======================================================================\
    ========\r\
    \n# MAIN PROCESSING LOOP\r\
    \n# ======================================================================\
    ========\r\
    \n:while ((\$pageNum < \$maxPages) and (\$hasMore = true)) do={\r\
    \n# Progress reporting\r\
    \n:if ((\$pageNum % 5) = 0) do={\r\
    \n:log info \"\$logPrefix: Processing pages \$pageNum-\$(\$pageNum + 4)...\
    \_Total: \$totalAdded\"\r\
    \n}\r\
    \n# Build URL with user_id parameter\r\
    \n:local pageURL [\$buildURL \$baseURL \"addresses\" \$pageSize \$currentO\
    ffset \$userId]\r\
    \n# Log the URL for first page (for debugging)\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:log info \"\$logPrefix: First request URL: \$pageURL\"\r\
    \n:log info \"\$logPrefix: Routing through: \$sourceAddress\"\r\
    \n}\r\
    \n# Fetch with retry logic\r\
    \n:local attempt 0\r\
    \n:local fetchSuccess false\r\
    \n:local pageContent \"\"\r\
    \n# Retry loop\r\
    \n:while ((\$attempt < \$maxRetries) and (\$fetchSuccess = false)) do={\r\
    \n:set attempt (\$attempt + 1)\r\
    \n:log info \"\$logPrefix: Fetching page \$pageNum (attempt \$attempt/\$ma\
    xRetries)...\"\r\
    \n:do {\r\
    \n# Fetch command with source address\r\
    \n# NOTE: check-certificate=no is pragmatic for the Iran TLS\r\
    \n# fingerprinting context; flip to =yes if running elsewhere.\r\
    \n:local fetchResult\r\
    \n:if (\$sourceValid = true) do={\r\
    \n# Use source address if valid\r\
    \n:set fetchResult [/tool fetch url=\$pageURL \\\r\
    \nmode=https \\\r\
    \ncheck-certificate=no \\\r\
    \noutput=user \\\r\
    \nsrc-address=\$sourceAddress \\\r\
    \nhttp-max-redirect-count=10 \\\r\
    \nas-value]\r\
    \n} else={\r\
    \n# Fall back to default routing\r\
    \n:set fetchResult [/tool fetch url=\$pageURL \\\r\
    \nmode=https \\\r\
    \ncheck-certificate=no \\\r\
    \noutput=user \\\r\
    \nhttp-max-redirect-count=10 \\\r\
    \nas-value]\r\
    \n}\r\
    \n:if ((\$fetchResult->\"status\") = \"finished\") do={\r\
    \n:set pageContent (\$fetchResult->\"data\")\r\
    \n:set fetchSuccess true\r\
    \n:log info \"\$logPrefix: Page \$pageNum fetched successfully\"\r\
    \n# Check response headers if available (for debugging)\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:log info \"\$logPrefix: First page fetched, checking for pagination hea\
    ders...\"\r\
    \n}\r\
    \n}\r\
    \n} on-error={\r\
    \n:if (\$attempt < \$maxRetries) do={\r\
    \n# Linear backoff with cap\r\
    \n:local delayTime [\$calcRetryDelay \$attempt \$retryBaseDelay \$retryMax\
    Delay]\r\
    \n:log warning \"\$logPrefix: Page \$pageNum failed, retry in \$delayTime \
    seconds...\"\r\
    \n:delay (\$delayTime . \"s\")\r\
    \n} else={\r\
    \n:log error \"\$logPrefix: Page \$pageNum failed after all attempts\"\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# Process page if successful\r\
    \n:if (\$fetchSuccess = true) do={\r\
    \n# Process content\r\
    \n:local batchCmd \"/ip firewall address-list\\r\\n\"\r\
    \n:local batchCount 0\r\
    \n:local pageAdded 0\r\
    \n:local pageInvalid 0\r\
    \n:local lastEnd 0\r\
    \n:local contentSize [:len \$pageContent]\r\
    \n:while (\$lastEnd < \$contentSize) do={\r\
    \n# Find line end\r\
    \n:local lineEnd [:find \$pageContent \"\\n\" \$lastEnd]\r\
    \n:if ([:typeof \$lineEnd] = \"nil\") do={\r\
    \n:set lineEnd \$contentSize\r\
    \n}\r\
    \n# Extract line\r\
    \n:local line [:pick \$pageContent \$lastEnd \$lineEnd]\r\
    \n:set lastEnd (\$lineEnd + 1)\r\
    \n# Clean line\r\
    \n:set line [\$cleanLine \$line]\r\
    \n# Skip empty lines and comments\r\
    \n:if ([:len \$line] > 0) do={\r\
    \n:if ([:pick \$line 0 1] != \"#\") do={\r\
    \n# Validate address\r\
    \n:if ([\$validateAddr \$line] = true) do={\r\
    \n:set batchCmd (\$batchCmd . \"add list=\$stagingListName address=\$line \
    comment=\\\"\$logPrefix-p\$pageNum\\\"\\r\\n\")\r\
    \n:set batchCount (\$batchCount + 1)\r\
    \n:set pageAdded (\$pageAdded + 1)\r\
    \n# Execute batch when full\r\
    \n:if (\$batchCount >= \$batchSize) do={\r\
    \n:do {\r\
    \n[:parse \$batchCmd]\r\
    \n} on-error={\r\
    \n:error \"\$logPrefix: Batch add failed on page \$pageNum\"\r\
    \n}\r\
    \n:set batchCmd \"/ip firewall address-list\\r\\n\"\r\
    \n:set batchCount 0\r\
    \n}\r\
    \n} else={\r\
    \n:set pageInvalid (\$pageInvalid + 1)\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# Execute remaining batch\r\
    \n:if (\$batchCount > 0) do={\r\
    \n:do {\r\
    \n[:parse \$batchCmd]\r\
    \n} on-error={\r\
    \n:error \"\$logPrefix: Final batch failed on page \$pageNum\"\r\
    \n}\r\
    \n}\r\
    \n:set totalAdded (\$totalAdded + \$pageAdded)\r\
    \n:set totalInvalid (\$totalInvalid + \$pageInvalid)\r\
    \n:set successfulPages (\$successfulPages + 1)\r\
    \n:log info \"\$logPrefix: Page \$pageNum complete (added=\$pageAdded, inv\
    alid=\$pageInvalid)\"\r\
    \n# Detect end of data using parsed entry count\r\
    \n:if (\$pageAdded = 0) do={\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:error \"\$logPrefix: First page returned zero valid entries\"\r\
    \n}\r\
    \n:set hasMore false\r\
    \n:log info \"\$logPrefix: End of data reached at page \$pageNum (0 entrie\
    s)\"\r\
    \n} else={\r\
    \n:if (\$pageAdded < \$pageSize) do={\r\
    \n:set hasMore false\r\
    \n:log info \"\$logPrefix: End of data reached at page \$pageNum (\$pageAd\
    ded entries)\"\r\
    \n}\r\
    \n}\r\
    \n} else={\r\
    \n:error \"\$logPrefix: Page \$pageNum could not be fetched\"\r\
    \n}\r\
    \n# Next page\r\
    \n:set currentOffset (\$currentOffset + \$pageSize)\r\
    \n:set pageNum (\$pageNum + 1)\r\
    \n# Small delay between pages\r\
    \n:delay 10ms\r\
    \n}\r\
    \n:if (\$successfulPages = 0) do={\r\
    \n:error \"\$logPrefix: No pages imported successfully\"\r\
    \n}\r\
    \n:set stagedCount [:len [/ip firewall address-list find list=\$stagingLis\
    tName]]\r\
    \n# Dynamic threshold: keep old list unless new data is sane\r\
    \n:if (\$previousCount = 0) do={\r\
    \n:set minRequired \$minBootstrapCount\r\
    \n} else={\r\
    \n:local retentionFloor ((\$previousCount * \$minRetentionPercent) / 100)\
    \r\
    \n:if (\$retentionFloor > \$minRequired) do={\r\
    \n:set minRequired \$retentionFloor\r\
    \n}\r\
    \n}\r\
    \n:if (\$minRequired < \$minSafeCount) do={\r\
    \n:set minRequired \$minSafeCount\r\
    \n}\r\
    \n:if (\$stagedCount < \$minRequired) do={\r\
    \n:error \"\$logPrefix: Validation failed - staged=\$stagedCount required=\
    \$minRequired (existing kept)\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: Validation passed - staged=\$stagedCount requir\
    ed=\$minRequired\"\r\
    \n:log info \"\$logPrefix: Swapping \$stagingListName into \$listName\"\r\
    \n/ip firewall address-list remove [find list=\$listName]\r\
    \n/ip firewall address-list set [find list=\$stagingListName] list=\$listN\
    ame\r\
    \n:set finalCount [:len [/ip firewall address-list find list=\$listName]]\
    \r\
    \n# NOTE: by this point the OLD list is already gone (swap above). If\r\
    \n# this tripwire fires, the on-error message 'existing list preserved'\r\
    \n# is technically a lie - the old list was removed, the new (possibly\r\
    \n# short) list is live. In practice RouterOS shouldn't lose entries\r\
    \n# between remove+set, so this is a paranoia check. The FINAL SUMMARY\r\
    \n# below re-reads finalCount so logs still show the actual state.\r\
    \n:if (\$finalCount < \$minRequired) do={\r\
    \n:error \"\$logPrefix: Post-swap validation failed - final=\$finalCount r\
    equired=\$minRequired\"\r\
    \n}\r\
    \n:set importSuccessful true\r\
    \n} on-error={\r\
    \n:log error \"\$logPrefix: Import failed, existing list preserved\"\r\
    \n}\r\
    \n# TODO(nice-to-have): persist a 'last good import' marker so downstream\
    \r\
    \n# consumers (and ops) can answer 'when did this last actually succeed\?'\
    \r\
    \n# without scraping logs. e.g.:\r\
    \n#   /system note set note=\"DOMAddList-last-good=\$endTime:\$finalCount\
    \"\r\
    \n# ======================================================================\
    ========\r\
    \n# FINAL SUMMARY\r\
    \n# ======================================================================\
    ========\r\
    \n:set endTime [/system clock get time]\r\
    \n:if (\$importSuccessful = false) do={\r\
    \n:set finalCount [:len [/ip firewall address-list find list=\$listName]]\
    \r\
    \n}\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n:if (\$importSuccessful = true) do={\r\
    \n:log info \"\$logPrefix: IMPORT COMPLETE!\"\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: IMPORT FAILED (old list kept)\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: Pages processed: \$pageNum\"\r\
    \n:log info \"\$logPrefix: Successful pages: \$successfulPages\"\r\
    \n:log info \"\$logPrefix: Valid entries added: \$totalAdded\"\r\
    \n:log info \"\$logPrefix: Invalid entries skipped: \$totalInvalid\"\r\
    \n:log info \"\$logPrefix: Required minimum entries: \$minRequired\"\r\
    \n:log info \"\$logPrefix: Staged entries: \$stagedCount\"\r\
    \n:log info \"\$logPrefix: Previous firewall count: \$previousCount\"\r\
    \n:log info \"\$logPrefix: Actual firewall count: \$finalCount\"\r\
    \n:log info \"\$logPrefix: Processing time: \$startTime to \$endTime\"\r\
    \n# Routing summary\r\
    \n:if (\$sourceValid = true) do={\r\
    \n:log info \"\$logPrefix: Source address used: \$sourceAddress\"\r\
    \n} else={\r\
    \n:log info \"\$logPrefix: Default routing used (source address not found)\
    \"\r\
    \n}\r\
    \n# User tracking summary\r\
    \n:if ([:len \$userId] > 0) do={\r\
    \n:log info \"\$logPrefix: User ID: \$userId\"\r\
    \n}\r\
    \n:if (\$importSuccessful = true) do={\r\
    \n:if (\$finalCount >= \$minBootstrapCount) do={\r\
    \n:log info \"\$logPrefix: SUCCESS: Healthy import size detected\"\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: SUCCESS: Imported with low-but-acceptable si\
    ze\"\r\
    \n}\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: WARNING: Update failed, previous list retain\
    ed\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n# Always cleanup staging list and release lock\r\
    \n/ip firewall address-list remove [find list=\$stagingListName]\r\
    \n:set domesticIPUpdateRunning false\r\
    \n# Cleanup functions\r\
    \n:set cleanLine\r\
    \n:set validateAddr\r\
    \n:set buildURL\r\
    \n:set calcRetryDelay\r\
    \n\r\
    \n/system scheduler\r\
    \nremove [find name=DomesticIPUpdate-OneTime];"
add dont-require-permissions=no name=DomesticIPUpdate owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    \_========================================================================\
    ======\r\
    \n#  MikroTik Dynamic Address List Updater - Resilient Mode\r\
    \n# ======================================================================\
    ========\r\
    \n# ======================================================================\
    ========\r\
    \n# CONFIGURATION SECTION\r\
    \n# ======================================================================\
    ========\r\
    \n# API Configuration\r\
    \n# TODO(nice-to-have): baseURL is hardcoded per-deployment - lift to a fn\
    \_arg\r\
    \n:local baseURL \"https://s4i.co/irip\"\r\
    \n:local listName \"DOMAddList\"\r\
    \n:local stagingListName (\$listName . \"-new\")\r\
    \n:local logPrefix \"SecureListUpdate\"\r\
    \n# User Tracking Configuration\r\
    \n# Leave empty to disable tracking\r\
    \n:local userId \"6e6e7001-7631-6d6b-dfd0-f77f38aa3ac0\"\r\
    \n# ========== SOURCE ROUTING CONFIGURATION ==========\r\
    \n# Specify source address for all HTTP/HTTPS requests\r\
    \n# This forces all fetch operations through the interface with this IP\r\
    \n# TODO(nice-to-have): also hardcoded - should be a generator fn arg\r\
    \n:local sourceAddress \"192.168.39.12\"\r\
    \n# ==================================================\r\
    \n# Pagination Configuration\r\
    \n:local pageSize 1000\r\
    \n:local maxPages 50\r\
    \n:local batchSize 50\r\
    \n# Retry Configuration\r\
    \n:local maxRetries 4\r\
    \n:local retryBaseDelay 5\r\
    \n:local retryMaxDelay 30\r\
    \n# Validation Configuration\r\
    \n# TODO(nice-to-have): expose these as fn args. If upstream legitimately\
    \r\
    \n# shrinks by >30% we'll silently keep stale data forever with no overrid\
    e.\r\
    \n:local minSafeCount 100\r\
    \n:local minBootstrapCount 1000\r\
    \n:local minRetentionPercent 70\r\
    \n# ======================================================================\
    ========\r\
    \n# HELPER FUNCTIONS\r\
    \n# ======================================================================\
    ========\r\
    \n# Function: Clean line endings\r\
    \n:global cleanLine do={\r\
    \n:local line \$1\r\
    \n:if ([:len \$line] = 0) do={ :return \"\" }\r\
    \n# Remove CR\r\
    \n:if ([:pick \$line ([:len \$line] - 1)] = \"\\r\") do={\r\
    \n:set line [:pick \$line 0 ([:len \$line] - 1)]\r\
    \n}\r\
    \n# Trim leading spaces\r\
    \n:while (([:len \$line] > 0) and ([:pick \$line 0 1] = \" \")) do={\r\
    \n:set line [:pick \$line 1 [:len \$line]]\r\
    \n}\r\
    \n# Trim trailing spaces\r\
    \n:while (([:len \$line] > 0) and ([:pick \$line ([:len \$line] - 1)] = \"\
    \_\")) do={\r\
    \n:set line [:pick \$line 0 ([:len \$line] - 1)]\r\
    \n}\r\
    \n:return \$line\r\
    \n}\r\
    \n# Function: Validate address\r\
    \n:global validateAddr do={\r\
    \n:local addr \$1\r\
    \n:local valid false\r\
    \n# Check for CIDR\r\
    \n:if ([:find \$addr \"/\"] > 0) do={\r\
    \n:local slashPos [:find \$addr \"/\"]\r\
    \n:local ipPart [:pick \$addr 0 \$slashPos]\r\
    \n:local maskPart [:pick \$addr (\$slashPos + 1) [:len \$addr]]\r\
    \n:do {\r\
    \n[:toip \$ipPart]\r\
    \n:local maskNum [:tonum \$maskPart]\r\
    \n:if ((\$maskNum >= 0) and (\$maskNum <= 32)) do={\r\
    \n:set valid true\r\
    \n}\r\
    \n} on-error={}\r\
    \n} else={\r\
    \n# Plain IP\r\
    \n:do {\r\
    \n[:toip \$addr]\r\
    \n:set valid true\r\
    \n} on-error={}\r\
    \n}\r\
    \n:return \$valid\r\
    \n}\r\
    \n# Function: Build URL with parameters\r\
    \n:global buildURL do={\r\
    \n:local base \$1\r\
    \n:local format \$2\r\
    \n:local limit \$3\r\
    \n:local offset \$4\r\
    \n:local user \$5\r\
    \n# Start with base URL and required parameters\r\
    \n:local url \"\$base\\\?format=\$format&limit=\$limit&offset=\$offset\"\r\
    \n# Add user_id if provided\r\
    \n:if ([:len \$user] > 0) do={\r\
    \n:set url \"\$url&user_id=\$user\"\r\
    \n}\r\
    \n:return \$url\r\
    \n}\r\
    \n# Function: Calculate retry delay\r\
    \n:global calcRetryDelay do={\r\
    \n:local attempt \$1\r\
    \n:local baseDelay \$2\r\
    \n:local maxDelay \$3\r\
    \n:local delayValue (\$baseDelay * \$attempt)\r\
    \n:if (\$delayValue > \$maxDelay) do={\r\
    \n:set delayValue \$maxDelay\r\
    \n}\r\
    \n:return \$delayValue\r\
    \n}\r\
    \n# ======================================================================\
    ========\r\
    \n# MAIN SCRIPT\r\
    \n# ======================================================================\
    ========\r\
    \n# Prevent concurrent runs (scheduler + manual execution overlap)\r\
    \n# TODO(nice-to-have): pair with a :global domesticIPUpdateStartedAt and\
    \r\
    \n# treat the lock as stale after ~30 min. Today, a manually-killed run\r\
    \n# leaves the lock 'true' until the next reboot clears :global state.\r\
    \n:global domesticIPUpdateRunning\r\
    \n:if ([:typeof \$domesticIPUpdateRunning] = \"nothing\") do={\r\
    \n:set domesticIPUpdateRunning false\r\
    \n}\r\
    \n:if (\$domesticIPUpdateRunning = true) do={\r\
    \n:log warning \"\$logPrefix: Another update is already running, skipping \
    this execution\"\r\
    \n:error \"\$logPrefix: lock already held\"\r\
    \n}\r\
    \n:set domesticIPUpdateRunning true\r\
    \n# Initialize state\r\
    \n:local importSuccessful false\r\
    \n:local startTime [/system clock get time]\r\
    \n:local endTime \"\"\r\
    \n:local previousCount [:len [/ip firewall address-list find list=\$listNa\
    me]]\r\
    \n:local finalCount \$previousCount\r\
    \n:local stagedCount 0\r\
    \n:local minRequired \$minSafeCount\r\
    \n:local totalAdded 0\r\
    \n:local totalInvalid 0\r\
    \n:local successfulPages 0\r\
    \n:local currentOffset 0\r\
    \n:local pageNum 0\r\
    \n:local hasMore true\r\
    \n:local sourceValid false\r\
    \n:do {\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n:log info \"\$logPrefix: Starting Dynamic Address List Import\"\r\
    \n:log info \"\$logPrefix: Using source address: \$sourceAddress\"\r\
    \n:log info \"\$logPrefix: Existing \$listName count before update: \$prev\
    iousCount\"\r\
    \n# Verify source address exists\r\
    \n:set sourceValid false\r\
    \n:do {\r\
    \n:local testIP [/ip address find where address~\"^\$sourceAddress/\"]\r\
    \n:if ([:len \$testIP] > 0) do={\r\
    \n:set sourceValid true\r\
    \n:log info \"\$logPrefix: Source address \$sourceAddress verified\"\r\
    \n}\r\
    \n} on-error={}\r\
    \n:if (\$sourceValid = false) do={\r\
    \n:log warning \"\$logPrefix: Source address \$sourceAddress not found on \
    any interface!\"\r\
    \n:log warning \"\$logPrefix: Proceeding with default routing...\"\r\
    \n}\r\
    \n# Log user tracking status\r\
    \n:if ([:len \$userId] > 0) do={\r\
    \n:log info \"\$logPrefix: User tracking enabled: \$userId\"\r\
    \n} else={\r\
    \n:log info \"\$logPrefix: User tracking disabled (no user_id configured)\
    \"\r\
    \n}\r\
    \n# Prepare staging list\r\
    \n:log info \"\$logPrefix: Cleaning stale staging list entries...\"\r\
    \n/ip firewall address-list remove [find list=\$stagingListName]\r\
    \n# ======================================================================\
    ========\r\
    \n# MAIN PROCESSING LOOP\r\
    \n# ======================================================================\
    ========\r\
    \n:while ((\$pageNum < \$maxPages) and (\$hasMore = true)) do={\r\
    \n# Progress reporting\r\
    \n:if ((\$pageNum % 5) = 0) do={\r\
    \n:log info \"\$logPrefix: Processing pages \$pageNum-\$(\$pageNum + 4)...\
    \_Total: \$totalAdded\"\r\
    \n}\r\
    \n# Build URL with user_id parameter\r\
    \n:local pageURL [\$buildURL \$baseURL \"addresses\" \$pageSize \$currentO\
    ffset \$userId]\r\
    \n# Log the URL for first page (for debugging)\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:log info \"\$logPrefix: First request URL: \$pageURL\"\r\
    \n:log info \"\$logPrefix: Routing through: \$sourceAddress\"\r\
    \n}\r\
    \n# Fetch with retry logic\r\
    \n:local attempt 0\r\
    \n:local fetchSuccess false\r\
    \n:local pageContent \"\"\r\
    \n# Retry loop\r\
    \n:while ((\$attempt < \$maxRetries) and (\$fetchSuccess = false)) do={\r\
    \n:set attempt (\$attempt + 1)\r\
    \n:log info \"\$logPrefix: Fetching page \$pageNum (attempt \$attempt/\$ma\
    xRetries)...\"\r\
    \n:do {\r\
    \n# Fetch command with source address\r\
    \n# NOTE: check-certificate=no is pragmatic for the Iran TLS\r\
    \n# fingerprinting context; flip to =yes if running elsewhere.\r\
    \n:local fetchResult\r\
    \n:if (\$sourceValid = true) do={\r\
    \n# Use source address if valid\r\
    \n:set fetchResult [/tool fetch url=\$pageURL \\\r\
    \nmode=https \\\r\
    \ncheck-certificate=no \\\r\
    \noutput=user \\\r\
    \nsrc-address=\$sourceAddress \\\r\
    \nhttp-max-redirect-count=10 \\\r\
    \nas-value]\r\
    \n} else={\r\
    \n# Fall back to default routing\r\
    \n:set fetchResult [/tool fetch url=\$pageURL \\\r\
    \nmode=https \\\r\
    \ncheck-certificate=no \\\r\
    \noutput=user \\\r\
    \nhttp-max-redirect-count=10 \\\r\
    \nas-value]\r\
    \n}\r\
    \n:if ((\$fetchResult->\"status\") = \"finished\") do={\r\
    \n:set pageContent (\$fetchResult->\"data\")\r\
    \n:set fetchSuccess true\r\
    \n:log info \"\$logPrefix: Page \$pageNum fetched successfully\"\r\
    \n# Check response headers if available (for debugging)\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:log info \"\$logPrefix: First page fetched, checking for pagination hea\
    ders...\"\r\
    \n}\r\
    \n}\r\
    \n} on-error={\r\
    \n:if (\$attempt < \$maxRetries) do={\r\
    \n# Linear backoff with cap\r\
    \n:local delayTime [\$calcRetryDelay \$attempt \$retryBaseDelay \$retryMax\
    Delay]\r\
    \n:log warning \"\$logPrefix: Page \$pageNum failed, retry in \$delayTime \
    seconds...\"\r\
    \n:delay (\$delayTime . \"s\")\r\
    \n} else={\r\
    \n:log error \"\$logPrefix: Page \$pageNum failed after all attempts\"\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# Process page if successful\r\
    \n:if (\$fetchSuccess = true) do={\r\
    \n# Process content\r\
    \n:local batchCmd \"/ip firewall address-list\\r\\n\"\r\
    \n:local batchCount 0\r\
    \n:local pageAdded 0\r\
    \n:local pageInvalid 0\r\
    \n:local lastEnd 0\r\
    \n:local contentSize [:len \$pageContent]\r\
    \n:while (\$lastEnd < \$contentSize) do={\r\
    \n# Find line end\r\
    \n:local lineEnd [:find \$pageContent \"\\n\" \$lastEnd]\r\
    \n:if ([:typeof \$lineEnd] = \"nil\") do={\r\
    \n:set lineEnd \$contentSize\r\
    \n}\r\
    \n# Extract line\r\
    \n:local line [:pick \$pageContent \$lastEnd \$lineEnd]\r\
    \n:set lastEnd (\$lineEnd + 1)\r\
    \n# Clean line\r\
    \n:set line [\$cleanLine \$line]\r\
    \n# Skip empty lines and comments\r\
    \n:if ([:len \$line] > 0) do={\r\
    \n:if ([:pick \$line 0 1] != \"#\") do={\r\
    \n# Validate address\r\
    \n:if ([\$validateAddr \$line] = true) do={\r\
    \n:set batchCmd (\$batchCmd . \"add list=\$stagingListName address=\$line \
    comment=\\\"\$logPrefix-p\$pageNum\\\"\\r\\n\")\r\
    \n:set batchCount (\$batchCount + 1)\r\
    \n:set pageAdded (\$pageAdded + 1)\r\
    \n# Execute batch when full\r\
    \n:if (\$batchCount >= \$batchSize) do={\r\
    \n:do {\r\
    \n[:parse \$batchCmd]\r\
    \n} on-error={\r\
    \n:error \"\$logPrefix: Batch add failed on page \$pageNum\"\r\
    \n}\r\
    \n:set batchCmd \"/ip firewall address-list\\r\\n\"\r\
    \n:set batchCount 0\r\
    \n}\r\
    \n} else={\r\
    \n:set pageInvalid (\$pageInvalid + 1)\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n}\r\
    \n# Execute remaining batch\r\
    \n:if (\$batchCount > 0) do={\r\
    \n:do {\r\
    \n[:parse \$batchCmd]\r\
    \n} on-error={\r\
    \n:error \"\$logPrefix: Final batch failed on page \$pageNum\"\r\
    \n}\r\
    \n}\r\
    \n:set totalAdded (\$totalAdded + \$pageAdded)\r\
    \n:set totalInvalid (\$totalInvalid + \$pageInvalid)\r\
    \n:set successfulPages (\$successfulPages + 1)\r\
    \n:log info \"\$logPrefix: Page \$pageNum complete (added=\$pageAdded, inv\
    alid=\$pageInvalid)\"\r\
    \n# Detect end of data using parsed entry count\r\
    \n:if (\$pageAdded = 0) do={\r\
    \n:if (\$pageNum = 0) do={\r\
    \n:error \"\$logPrefix: First page returned zero valid entries\"\r\
    \n}\r\
    \n:set hasMore false\r\
    \n:log info \"\$logPrefix: End of data reached at page \$pageNum (0 entrie\
    s)\"\r\
    \n} else={\r\
    \n:if (\$pageAdded < \$pageSize) do={\r\
    \n:set hasMore false\r\
    \n:log info \"\$logPrefix: End of data reached at page \$pageNum (\$pageAd\
    ded entries)\"\r\
    \n}\r\
    \n}\r\
    \n} else={\r\
    \n:error \"\$logPrefix: Page \$pageNum could not be fetched\"\r\
    \n}\r\
    \n# Next page\r\
    \n:set currentOffset (\$currentOffset + \$pageSize)\r\
    \n:set pageNum (\$pageNum + 1)\r\
    \n# Small delay between pages\r\
    \n:delay 10ms\r\
    \n}\r\
    \n:if (\$successfulPages = 0) do={\r\
    \n:error \"\$logPrefix: No pages imported successfully\"\r\
    \n}\r\
    \n:set stagedCount [:len [/ip firewall address-list find list=\$stagingLis\
    tName]]\r\
    \n# Dynamic threshold: keep old list unless new data is sane\r\
    \n:if (\$previousCount = 0) do={\r\
    \n:set minRequired \$minBootstrapCount\r\
    \n} else={\r\
    \n:local retentionFloor ((\$previousCount * \$minRetentionPercent) / 100)\
    \r\
    \n:if (\$retentionFloor > \$minRequired) do={\r\
    \n:set minRequired \$retentionFloor\r\
    \n}\r\
    \n}\r\
    \n:if (\$minRequired < \$minSafeCount) do={\r\
    \n:set minRequired \$minSafeCount\r\
    \n}\r\
    \n:if (\$stagedCount < \$minRequired) do={\r\
    \n:error \"\$logPrefix: Validation failed - staged=\$stagedCount required=\
    \$minRequired (existing kept)\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: Validation passed - staged=\$stagedCount requir\
    ed=\$minRequired\"\r\
    \n:log info \"\$logPrefix: Swapping \$stagingListName into \$listName\"\r\
    \n/ip firewall address-list remove [find list=\$listName]\r\
    \n/ip firewall address-list set [find list=\$stagingListName] list=\$listN\
    ame\r\
    \n:set finalCount [:len [/ip firewall address-list find list=\$listName]]\
    \r\
    \n# NOTE: by this point the OLD list is already gone (swap above). If\r\
    \n# this tripwire fires, the on-error message 'existing list preserved'\r\
    \n# is technically a lie - the old list was removed, the new (possibly\r\
    \n# short) list is live. In practice RouterOS shouldn't lose entries\r\
    \n# between remove+set, so this is a paranoia check. The FINAL SUMMARY\r\
    \n# below re-reads finalCount so logs still show the actual state.\r\
    \n:if (\$finalCount < \$minRequired) do={\r\
    \n:error \"\$logPrefix: Post-swap validation failed - final=\$finalCount r\
    equired=\$minRequired\"\r\
    \n}\r\
    \n:set importSuccessful true\r\
    \n} on-error={\r\
    \n:log error \"\$logPrefix: Import failed, existing list preserved\"\r\
    \n}\r\
    \n# TODO(nice-to-have): persist a 'last good import' marker so downstream\
    \r\
    \n# consumers (and ops) can answer 'when did this last actually succeed\?'\
    \r\
    \n# without scraping logs. e.g.:\r\
    \n#   /system note set note=\"DOMAddList-last-good=\$endTime:\$finalCount\
    \"\r\
    \n# ======================================================================\
    ========\r\
    \n# FINAL SUMMARY\r\
    \n# ======================================================================\
    ========\r\
    \n:set endTime [/system clock get time]\r\
    \n:if (\$importSuccessful = false) do={\r\
    \n:set finalCount [:len [/ip firewall address-list find list=\$listName]]\
    \r\
    \n}\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n:if (\$importSuccessful = true) do={\r\
    \n:log info \"\$logPrefix: IMPORT COMPLETE!\"\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: IMPORT FAILED (old list kept)\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: Pages processed: \$pageNum\"\r\
    \n:log info \"\$logPrefix: Successful pages: \$successfulPages\"\r\
    \n:log info \"\$logPrefix: Valid entries added: \$totalAdded\"\r\
    \n:log info \"\$logPrefix: Invalid entries skipped: \$totalInvalid\"\r\
    \n:log info \"\$logPrefix: Required minimum entries: \$minRequired\"\r\
    \n:log info \"\$logPrefix: Staged entries: \$stagedCount\"\r\
    \n:log info \"\$logPrefix: Previous firewall count: \$previousCount\"\r\
    \n:log info \"\$logPrefix: Actual firewall count: \$finalCount\"\r\
    \n:log info \"\$logPrefix: Processing time: \$startTime to \$endTime\"\r\
    \n# Routing summary\r\
    \n:if (\$sourceValid = true) do={\r\
    \n:log info \"\$logPrefix: Source address used: \$sourceAddress\"\r\
    \n} else={\r\
    \n:log info \"\$logPrefix: Default routing used (source address not found)\
    \"\r\
    \n}\r\
    \n# User tracking summary\r\
    \n:if ([:len \$userId] > 0) do={\r\
    \n:log info \"\$logPrefix: User ID: \$userId\"\r\
    \n}\r\
    \n:if (\$importSuccessful = true) do={\r\
    \n:if (\$finalCount >= \$minBootstrapCount) do={\r\
    \n:log info \"\$logPrefix: SUCCESS: Healthy import size detected\"\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: SUCCESS: Imported with low-but-acceptable si\
    ze\"\r\
    \n}\r\
    \n} else={\r\
    \n:log warning \"\$logPrefix: WARNING: Update failed, previous list retain\
    ed\"\r\
    \n}\r\
    \n:log info \"\$logPrefix: ========================================\"\r\
    \n# Always cleanup staging list and release lock\r\
    \n/ip firewall address-list remove [find list=\$stagingListName]\r\
    \n:set domesticIPUpdateRunning false\r\
    \n# Cleanup functions\r\
    \n:set cleanLine\r\
    \n:set validateAddr\r\
    \n:set buildURL\r\
    \n:set calcRetryDelay"
/certificate settings
set builtin-trust-store=all crl-download=yes crl-store=system
/disk settings
set auto-media-interface=*9 auto-media-sharing=yes auto-smb-sharing=yes
/interface bridge port
add bridge=LANBridgeSplit comment=Split interface=ether1
add bridge=LANBridgeSplit comment=Split interface=ether3
add bridge=LANBridgeSplit comment=Split interface=ether5
add bridge=LANBridgeSplit comment=Split interface=wifi5-SplitLAN
add bridge=LANBridgeSplit comment=Split interface=wifi2.4-SplitLAN
/ip neighbor discovery-settings
set discover-interface-list=*2000011
/ipv6 settings
set disable-ipv6=yes
/interface list member
add comment="Foreign WAN" interface="MacVLAN-ether4-Foreign Link" list=WAN
add comment="Foreign WAN" interface="MacVLAN-ether4-Foreign Link" list=\
    Foreign-WAN
add comment="Domestic WAN" interface="MacVLAN-ether2-Domestic Link" list=WAN
add comment=Domestic interface=LANBridgeDomestic list=LAN
add comment=Domestic interface=LANBridgeDomestic list=Domestic-LAN
add comment="Domestic-Domestic Link" interface=\
    "LANBridgeDomestic-Domestic Link" list=LAN
add comment="Domestic-Domestic Link" interface=\
    "LANBridgeDomestic-Domestic Link" list="Domestic-Domestic Link-LAN"
add comment=SplitLAN interface=wifi5-SplitLAN list=Split-LAN
add comment=SplitLAN interface=wifi5-SplitLAN list=LAN
add comment=SplitLAN interface=wifi2.4-SplitLAN list=Split-LAN
add comment=SplitLAN interface=wifi2.4-SplitLAN list=LAN
add comment=Split interface=LANBridgeSplit list=LAN
add comment=Split interface=LANBridgeSplit list=Split-LAN
add comment=Foreign interface=LANBridgeForeign list=LAN
add comment=Foreign interface=LANBridgeForeign list=Foreign-LAN
add comment=VPN interface=LANBridgeVPN list=LAN
add comment=VPN interface=LANBridgeVPN list=VPN-LAN
add comment="Foreign-Foreign Link" interface="LANBridgeForeign-Foreign Link" \
    list=LAN
add comment="Foreign-Foreign Link" interface="LANBridgeForeign-Foreign Link" \
    list="Foreign-Foreign Link-LAN"
/ip address
add address=192.168.200.1/24 comment="Ethernet Static Management Port" \
    interface=ether5 network=192.168.200.0
add address=192.168.210.1/24 comment="WiFi Static Management Port" interface=\
    wifi-management network=192.168.210.0
add address=192.168.10.1/24 comment=Split interface=LANBridgeSplit network=\
    192.168.10.0
add address=192.168.20.1/24 comment=Domestic interface=LANBridgeDomestic \
    network=192.168.20.0
add address=192.168.21.1/24 comment="Domestic-Domestic Link" interface=\
    "LANBridgeDomestic-Domestic Link" network=192.168.21.0
add address=192.168.30.1/24 comment=Foreign interface=LANBridgeForeign \
    network=192.168.30.0
add address=192.168.40.1/24 comment=VPN interface=LANBridgeVPN network=\
    192.168.40.0
add address=192.168.31.1/24 comment="Foreign-Foreign Link" interface=\
    "LANBridgeForeign-Foreign Link" network=192.168.31.0
add address=192.168.39.12 comment="Foreign Table Address Holder" interface=\
    FTAH network=192.168.39.12
/ip cloud
set ddns-enabled=yes ddns-update-interval=1m
/ip dhcp-client
# Interface not active
add add-default-route=no comment="Foreign Link to Foreign" interface=\
    "MacVLAN-ether4-Foreign Link" name=client1 script=":if (\$bound=1) do={\
    \n:local gw (\$\"gateway-address\" . \"%\" . \$interface)\
    \n:local routeCount [/ip route print count-only where comment=\"Route-to-F\
    oreign-Foreign Link\"]\
    \n:if (\$routeCount > 0) do={\
    \n    /ip route set [ find comment=\"Route-to-Foreign-Foreign Link\" gatew\
    ay!=\$gw ] gateway=\$gw\
    \n}\
    \n:local routeCount1 [/ip route print count-only where comment=\"Route-to-\
    Foreign-Foreign Link 1\"]\
    \n:local gw1 (\$\"gateway-address\")\
    \n:if (\$routeCount1 > 0) do={\
    \n    /ip route set [ find comment=\"Route-to-Foreign-Foreign Link 1\" gat\
    eway!=\$gw1 ] gateway=\$gw1\
    \n}\
    \n}" use-peer-dns=no use-peer-ntp=no
# Interface not active
add add-default-route=no comment="Domestic Link to Domestic" interface=\
    "MacVLAN-ether2-Domestic Link" name=client2 script=":if (\$bound=1) do={\r\
    \n:local gw (\$\"gateway-address\" . \"%\" . \$interface)\r\
    \n:local routeCount [/ip route print count-only where comment=\"Route-to-D\
    omestic-Domestic Link\"]\r\
    \n:if (\$routeCount > 0) do={\r\
    \n    /ip route set [ find comment=\"Route-to-Domestic-Domestic Link\" gat\
    eway!=\$gw ] gateway=\$gw\r\
    \n}\r\
    \n}" use-peer-dns=no use-peer-ntp=no
/ip dhcp-server
# Interface not running
add address-pool=DHCP-pool-management-wifi comment=Management interface=\
    wifi-management name=DHCP-Management-wifi
add address-pool=DHCP-pool-Split comment=Split interface=LANBridgeSplit name=\
    DHCP-Split
add address-pool=DHCP-pool-Domestic comment=Domestic interface=\
    LANBridgeDomestic name=DHCP-Domestic
add address-pool="DHCP-pool-Domestic-Domestic Link" comment=\
    "Domestic-Domestic Link" interface="LANBridgeDomestic-Domestic Link" \
    name="DHCP-Domestic-Domestic Link"
add address-pool=DHCP-pool-Foreign comment=Foreign interface=LANBridgeForeign \
    name=DHCP-Foreign
add address-pool=DHCP-pool-VPN comment=VPN interface=LANBridgeVPN name=\
    DHCP-VPN
add address-pool="DHCP-pool-Foreign-Foreign Link" comment=\
    "Foreign-Foreign Link" interface="LANBridgeForeign-Foreign Link" name=\
    "DHCP-Foreign-Foreign Link"
/ip dhcp-server network
add address=192.168.10.0/24 comment=Split dns-server=192.168.10.1 gateway=\
    192.168.10.1
add address=192.168.20.0/24 comment=Domestic dns-server=192.168.20.1 gateway=\
    192.168.20.1
add address=192.168.21.0/24 comment="Domestic-Domestic Link" dns-server=\
    192.168.21.1 gateway=192.168.21.1
add address=192.168.30.0/24 comment=Foreign dns-server=192.168.30.1 gateway=\
    192.168.30.1
add address=192.168.31.0/24 comment="Foreign-Foreign Link" dns-server=\
    192.168.31.1 gateway=192.168.31.1
add address=192.168.40.0/24 comment=VPN dns-server=192.168.40.1 gateway=\
    192.168.40.1
add address=192.168.210.0/24 comment=Management dns-server=192.168.210.1 \
    gateway=192.168.210.1
/ip dns
set allow-remote-requests=yes cache-size=20480KiB doh-max-concurrent-queries=\
    500 doh-max-server-connections=50 max-concurrent-queries=500 \
    max-concurrent-tcp-sessions=50 servers=4.2.2.2,217.218.127.127,4.2.2.1 \
    use-doh-server=https://8.8.8.8/dns-query
/ip dns static
add comment="Forward .ir TLD queries via domestic DNS" forward-to=Domestic \
    regexp="\\.ir" type=FWD
add address=8.8.8.8 comment=DOH-Domain-Static-Entry name=dns.google type=A
add address=8.8.4.4 comment=DOH-Domain-Static-Entry name=dns.google type=A
add address=2001:4860:4860::8888 comment=DOH-Domain-Static-Entry name=\
    dns.google type=AAAA
add address=2001:4860:4860::8844 comment=DOH-Domain-Static-Entry name=\
    dns.google type=AAAA
add address=1.1.1.1 comment=DOH-Domain-Static-Entry name=cloudflare-dns.com \
    type=A
add address=1.0.0.1 comment=DOH-Domain-Static-Entry name=cloudflare-dns.com \
    type=A
add address=2606:4700:4700::1111 comment=DOH-Domain-Static-Entry name=\
    cloudflare-dns.com type=AAAA
add address=2606:4700:4700::1001 comment=DOH-Domain-Static-Entry name=\
    cloudflare-dns.com type=AAAA
add address=45.90.28.140 comment=DOH-Domain-Static-Entry name=dns.nextdns.io \
    type=A
add address=45.90.30.140 comment=DOH-Domain-Static-Entry name=dns.nextdns.io \
    type=A
add address=2a07:a8c0::abcd:1234 comment=DOH-Domain-Static-Entry name=\
    dns.nextdns.io type=AAAA
add address=2a07:a8c1::abcd:1234 comment=DOH-Domain-Static-Entry name=\
    dns.nextdns.io type=AAAA
add comment="Forward s4i.co via Foreign DNS" forward-to=Foreign \
    match-subdomain=yes name=s4i.co type=FWD
add comment="Forward starlink4iran.com via Foreign DNS" forward-to=Foreign \
    match-subdomain=yes name=starlink4iran.com type=FWD
add comment="Forward curl.se via General DNS" forward-to=General name=curl.se \
    type=FWD
add comment="Forward pki.goog via General DNS" forward-to=General name=\
    pki.goog type=FWD
add comment="Forward cacerts.digicert.com via General DNS" forward-to=General \
    name=cacerts.digicert.com type=FWD
add comment="Forward crl.d-trust.net via General DNS" forward-to=General \
    name=crl.d-trust.net type=FWD
add comment="Forward d-trust.net via General DNS" forward-to=General name=\
    d-trust.net type=FWD
add comment="Forward accv.es via General DNS" forward-to=General name=accv.es \
    type=FWD
add comment="Forward crl.certigna.fr via General DNS" forward-to=General \
    name=crl.certigna.fr type=FWD
add comment="Forward crl.dhimyotis.com via General DNS" forward-to=General \
    name=crl.dhimyotis.com type=FWD
add comment="Forward crl.securetrust.com via General DNS" forward-to=General \
    name=crl.securetrust.com type=FWD
add comment="Forward crl.comodoca.com via General DNS" forward-to=General \
    name=crl.comodoca.com type=FWD
add comment="Forward pool.ntp.org via General DNS for NTP" forward-to=General \
    name=pool.ntp.org type=FWD
add comment="Forward time.cloudflare.com via General DNS for NTP" forward-to=\
    General name=time.cloudflare.com type=FWD
add comment="Forward time.google.com via General DNS for NTP" forward-to=\
    General name=time.google.com type=FWD
/ip firewall address-list
add address=192.168.0.0/16 comment=LOCAL-IP list=LOCAL-IP
add address=172.16.0.0/12 comment=LOCAL-IP list=LOCAL-IP
add address=10.0.0.0/8 comment=LOCAL-IP list=LOCAL-IP
add address=192.168.10.0/24 comment=Split list=Split-LAN
add address=192.168.20.0/24 comment=Domestic list=Domestic-LAN
add address=192.168.21.0/24 comment="Domestic-Domestic Link" list=\
    "Domestic-Domestic Link-LAN"
add address=192.168.30.0/24 comment=Foreign list=Foreign-LAN
add address=192.168.40.0/24 comment=VPN list=VPN-LAN
add address=192.168.31.0/24 comment="Foreign-Foreign Link" list=\
    "Foreign-Foreign Link-LAN"
add address=192.168.120.0/24 comment="VPN-VPN subnet" list=VPN-LAN
add address=192.168.121.0/24 comment="VPN-Split subnet" list=Split-LAN
add address=192.168.122.0/24 comment="VPN-Foreign subnet" list=Foreign-LAN
add address=cloud2.mikrotik.com comment=\
    "Dynamic list for MikroTik Cloud DDNS" list=MikroTik-Cloud-Services
add address=cloud.mikrotik.com comment="Legacy endpoint for completeness" \
    list=MikroTik-Cloud-Services
/ip firewall filter
add action=drop chain=input comment="Block Open Recursive DNS" dst-port=53 \
    in-interface-list=WAN protocol=tcp
add action=drop chain=input comment="Block Open Recursive DNS" dst-port=53 \
    in-interface-list=WAN protocol=udp
add action=drop chain=input comment="Block WAN access to management ports" \
    dst-port=80,443,8080,8443,22 in-interface-list=WAN protocol=tcp
/ip firewall mangle
add action=accept chain=prerouting comment=Accept dst-address-list=LOCAL-IP \
    src-address-list=LOCAL-IP
add action=accept chain=postrouting comment=Accept dst-address-list=LOCAL-IP \
    src-address-list=LOCAL-IP
add action=accept chain=output comment=Accept dst-address-list=LOCAL-IP \
    src-address-list=LOCAL-IP
add action=accept chain=input comment=Accept dst-address-list=LOCAL-IP \
    src-address-list=LOCAL-IP
add action=accept chain=forward comment=Accept dst-address-list=LOCAL-IP \
    src-address-list=LOCAL-IP
add action=mark-connection chain=output comment="VPN Endpoint" \
    dst-address-list=VPNE new-connection-mark=conn-VPNE
add action=mark-routing chain=output comment="VPN Endpoint" connection-mark=\
    conn-VPNE dst-address-list=VPNE new-routing-mark=to-Foreign passthrough=\
    no
add action=mark-routing chain=output comment="VPN Endpoint" dst-address-list=\
    VPNE new-routing-mark=to-Foreign passthrough=no
add action=mark-routing chain=output comment="S4I Route" content=s4i.co \
    new-routing-mark=to-Foreign passthrough=no
add action=mark-routing chain=output comment="S4I Route" new-routing-mark=\
    to-Foreign passthrough=no src-address=192.168.39.12
add action=mark-routing chain=output comment=\
    "Force IP/Cloud DDNS traffic via Domestic WAN" dst-address-list=\
    MikroTik-Cloud-Services new-routing-mark=to-Domestic passthrough=no
add action=mark-routing chain=output comment=\
    "Force IP/Cloud DDNS traffic via Domestic WAN" dst-address-list=\
    MikroTik-Cloud-Services dst-port=15252 new-routing-mark=to-Domestic \
    passthrough=no protocol=udp
add action=mark-routing chain=prerouting comment=Split-DOM dst-address-list=\
    SplitDOMAddList new-routing-mark=to-Domestic passthrough=no \
    src-address-list=Split-LAN
add action=mark-routing chain=prerouting comment=Split-DOM dst-address-list=\
    DOMAddList new-routing-mark=to-Domestic passthrough=no src-address-list=\
    Split-LAN
add action=mark-routing chain=prerouting comment=Split-!DOM dst-address-list=\
    !DOMAddList new-routing-mark=to-VPN passthrough=no src-address-list=\
    Split-LAN
add action=mark-routing chain=prerouting comment="Domestic Routing" \
    new-routing-mark=to-Domestic passthrough=no src-address-list=Domestic-LAN
add action=mark-routing chain=prerouting comment=\
    "Domestic-Domestic Link Routing" new-routing-mark=\
    "to-Domestic-Domestic Link" passthrough=no src-address-list=\
    "Domestic-Domestic Link-LAN"
add action=mark-routing chain=prerouting comment=Split-VPN dst-address-list=\
    SplitVPNAddList new-routing-mark=to-VPN passthrough=no src-address-list=\
    Split-LAN
add action=mark-routing chain=prerouting comment=Split-FRN dst-address-list=\
    SplitFRNAddList new-routing-mark=to-Foreign passthrough=no \
    src-address-list=Split-LAN
add action=mark-routing chain=prerouting comment="VPN Routing" \
    new-routing-mark=to-VPN passthrough=no src-address-list=VPN-LAN
add action=mark-routing chain=prerouting comment=\
    "Foreign-Foreign Link Routing" new-routing-mark="to-Foreign-Foreign Link" \
    passthrough=no src-address-list="Foreign-Foreign Link-LAN"
add action=mark-routing chain=prerouting comment="Foreign Routing" \
    new-routing-mark=to-Foreign passthrough=no src-address-list=Foreign-LAN
/ip firewall nat
add action=masquerade chain=srcnat comment=\
    "MASQUERADE the traffic go to WAN Interfaces" out-interface-list=WAN
add action=dst-nat chain=dstnat comment="DNS Split" disabled=yes dst-port=53 \
    protocol=udp src-address-list=Split-LAN to-addresses=4.2.2.2
add action=dst-nat chain=dstnat comment="DNS Split" disabled=yes dst-port=53 \
    protocol=tcp src-address-list=Split-LAN to-addresses=4.2.2.2
add action=dst-nat chain=dstnat comment="DNS Domestic" disabled=yes dst-port=\
    53 protocol=udp src-address-list=Domestic-LAN to-addresses=\
    217.218.127.127
add action=dst-nat chain=dstnat comment="DNS Domestic" disabled=yes dst-port=\
    53 protocol=tcp src-address-list=Domestic-LAN to-addresses=\
    217.218.127.127
add action=dst-nat chain=dstnat comment="DNS Domestic-Domestic Link" \
    disabled=yes dst-port=53 protocol=udp src-address-list=\
    "Domestic-Domestic Link-LAN" to-addresses=217.218.127.127
add action=dst-nat chain=dstnat comment="DNS Domestic-Domestic Link" \
    disabled=yes dst-port=53 protocol=tcp src-address-list=\
    "Domestic-Domestic Link-LAN" to-addresses=217.218.127.127
add action=dst-nat chain=dstnat comment="DNS Foreign" disabled=yes dst-port=\
    53 protocol=udp src-address-list=Foreign-LAN to-addresses=4.2.2.1
add action=dst-nat chain=dstnat comment="DNS Foreign" disabled=yes dst-port=\
    53 protocol=tcp src-address-list=Foreign-LAN to-addresses=4.2.2.1
add action=dst-nat chain=dstnat comment="DNS VPN" disabled=yes dst-port=53 \
    protocol=udp src-address-list=VPN-LAN to-addresses=4.2.2.2
add action=dst-nat chain=dstnat comment="DNS VPN" disabled=yes dst-port=53 \
    protocol=tcp src-address-list=VPN-LAN to-addresses=4.2.2.2
add action=dst-nat chain=dstnat comment="DNS Foreign-Foreign Link" disabled=\
    yes dst-port=53 protocol=udp src-address-list="Foreign-Foreign Link-LAN" \
    to-addresses=4.2.2.1
add action=dst-nat chain=dstnat comment="DNS Foreign-Foreign Link" disabled=\
    yes dst-port=53 protocol=tcp src-address-list="Foreign-Foreign Link-LAN" \
    to-addresses=4.2.2.1
add action=redirect chain=dstnat comment="Redirect DNS" dst-port=53 protocol=\
    tcp
add action=redirect chain=dstnat comment="Redirect DNS" dst-port=53 protocol=\
    udp
/ip nat-pmp
set enabled=yes
/ip nat-pmp interfaces
add interface=LANBridgeSplit type=internal
add interface=LANBridgeDomestic type=internal
add interface="LANBridgeDomestic-Domestic Link" type=internal
add interface=LANBridgeForeign type=internal
add interface=LANBridgeVPN type=internal
add interface="LANBridgeForeign-Foreign Link" type=internal
/ip route
add comment="Route-to-Foreign-Foreign Link" dst-address=0.0.0.0/0 gateway=\
    "100.64.0.1%MacVLAN-ether4-Foreign Link" routing-table=\
    "to-Foreign-Foreign Link"
add check-gateway=ping comment="Route-to-Foreign-Foreign Link" distance=1 \
    dst-address=4.2.2.1 gateway="100.64.0.1%MacVLAN-ether4-Foreign Link" \
    routing-table="to-Foreign-Foreign Link" target-scope=11
add comment="Route-to-Foreign-Foreign Link" dst-address=0.0.0.0/0 gateway=\
    "100.64.0.1%MacVLAN-ether4-Foreign Link" routing-table=to-Foreign
add check-gateway=ping comment="Route-to-Foreign-Foreign Link" distance=1 \
    dst-address=4.2.2.1 gateway="100.64.0.1%MacVLAN-ether4-Foreign Link" \
    routing-table=to-Foreign target-scope=11
add comment="Route-to-Domestic-Domestic Link" dst-address=0.0.0.0/0 gateway=\
    "192.168.1.1%MacVLAN-ether2-Domestic Link" routing-table=\
    "to-Domestic-Domestic Link"
add check-gateway=ping comment="Route-to-Domestic-Domestic Link" distance=1 \
    dst-address=217.218.127.127 gateway=\
    "192.168.1.1%MacVLAN-ether2-Domestic Link" routing-table=\
    "to-Domestic-Domestic Link" target-scope=11
add comment="Route-to-Domestic-Domestic Link" dst-address=0.0.0.0/0 gateway=\
    "192.168.1.1%MacVLAN-ether2-Domestic Link" routing-table=to-Domestic
add check-gateway=ping comment="Route-to-Domestic-Domestic Link" distance=1 \
    dst-address=217.218.127.127 gateway=\
    "192.168.1.1%MacVLAN-ether2-Domestic Link" routing-table=to-Domestic \
    target-scope=11
add comment="Route-to-Domestic-Domestic Link" dst-address=217.218.127.127 \
    gateway="192.168.1.1%MacVLAN-ether2-Domestic Link" routing-table=main \
    scope=10
add check-gateway=ping comment="CheckIP-Route-to-Domestic-Domestic Link" \
    distance=5 dst-address=0.0.0.0/0 gateway=217.218.127.127 routing-table=\
    main target-scope=11
add comment="Route-to-Foreign-Foreign Link" dst-address=4.2.2.1 gateway=\
    "100.64.0.1%MacVLAN-ether4-Foreign Link" routing-table=main scope=10
add check-gateway=ping comment="CheckIP-Route-to-Foreign-Foreign Link" \
    distance=10 dst-address=0.0.0.0/0 gateway=4.2.2.1 routing-table=main \
    target-scope=11
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table=to-Split
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table=to-Domestic
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table="to-Domestic-Domestic Link"
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table=to-Foreign
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table=to-VPN
add comment="Route-to-Foreign-Foreign Link 1" distance=1 dst-address=\
    192.168.100.0/24 gateway=100.64.0.1 routing-table=to-VPN
add blackhole comment=Blackhole disabled=no distance=99 dst-address=0.0.0.0/0 \
    gateway="" routing-table="to-Foreign-Foreign Link"
/ip service
set ftp address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set ssh address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set telnet address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set www address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set www-ssl address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set winbox address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set api address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
set api-ssl address=192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
/ip upnp
set enabled=yes
/ipv6 firewall address-list
add address=::/128 comment="defconf: unspecified address" list=bad_ipv6
add address=::1/128 comment="defconf: lo" list=bad_ipv6
add address=fec0::/10 comment="defconf: site-local" list=bad_ipv6
add address=::ffff:0.0.0.0/96 comment="defconf: ipv4-mapped" list=bad_ipv6
add address=::/96 comment="defconf: ipv4 compat" list=bad_ipv6
add address=100::/64 comment="defconf: discard only " list=bad_ipv6
add address=2001:db8::/32 comment="defconf: documentation" list=bad_ipv6
add address=2001:10::/28 comment="defconf: ORCHID" list=bad_ipv6
add address=3ffe::/16 comment="defconf: 6bone" list=bad_ipv6
/ipv6 firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=input comment="defconf: accept UDP traceroute" \
    dst-port=33434-33534 protocol=udp
add action=accept chain=input comment=\
    "defconf: accept DHCPv6-Client prefix delegation." dst-port=546 protocol=\
    udp src-address=fe80::/10
add action=accept chain=input comment="defconf: accept IKE" dst-port=500,4500 \
    protocol=udp
add action=accept chain=input comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=input comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=input comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=input comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !*2000011
add action=fasttrack-connection chain=forward comment="defconf: fasttrack6" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop packets with bad src ipv6" src-address-list=bad_ipv6
add action=drop chain=forward comment=\
    "defconf: drop packets with bad dst ipv6" dst-address-list=bad_ipv6
add action=drop chain=forward comment="defconf: rfc4890 drop hop-limit=1" \
    hop-limit=equal:1 protocol=icmpv6
add action=accept chain=forward comment="defconf: accept ICMPv6" protocol=\
    icmpv6
add action=accept chain=forward comment="defconf: accept HIP" protocol=139
add action=accept chain=forward comment="defconf: accept IKE" dst-port=\
    500,4500 protocol=udp
add action=accept chain=forward comment="defconf: accept ipsec AH" protocol=\
    ipsec-ah
add action=accept chain=forward comment="defconf: accept ipsec ESP" protocol=\
    ipsec-esp
add action=accept chain=forward comment=\
    "defconf: accept all that matches ipsec policy" ipsec-policy=in,ipsec
add action=drop chain=forward comment=\
    "defconf: drop everything else not coming from LAN" in-interface-list=\
    !*2000011
add action=drop chain=input
add action=drop chain=forward
/routing rule
add action=lookup-only-in-table comment="Routing the Domestic SRC Address" \
    disabled=no src-address=192.168.20.0/24 table=to-Domestic
add action=lookup-only-in-table comment="Routing the Domestic Routing Mark" \
    disabled=no routing-mark=to-Domestic table=to-Domestic
add action=lookup-only-in-table comment=\
    "Routing the Domestic-Domestic Link SRC Address" disabled=no src-address=\
    192.168.21.0/24 table="to-Domestic-Domestic Link"
add action=lookup-only-in-table comment=\
    "Routing the Domestic-Domestic Link Routing Mark" disabled=no \
    routing-mark="to-Domestic-Domestic Link" table=\
    "to-Domestic-Domestic Link"
add action=lookup-only-in-table comment="Routing the Foreign SRC Address" \
    disabled=no src-address=192.168.30.0/24 table=to-Foreign
add action=lookup-only-in-table comment="Routing the Foreign Routing Mark" \
    disabled=no routing-mark=to-Foreign table=to-Foreign
add action=lookup-only-in-table comment="Routing the VPN SRC Address" \
    disabled=no src-address=192.168.40.0/24 table=to-VPN
add action=lookup-only-in-table comment="Routing the VPN Routing Mark" \
    disabled=no routing-mark=to-VPN table=to-VPN
add action=lookup-only-in-table comment=\
    "Routing the Foreign-Foreign Link SRC Address" disabled=no src-address=\
    192.168.31.0/24 table="to-Foreign-Foreign Link"
add action=lookup-only-in-table comment=\
    "Routing the Foreign-Foreign Link Routing Mark" disabled=no routing-mark=\
    "to-Foreign-Foreign Link" table="to-Foreign-Foreign Link"
/system clock
set time-zone-autodetect=no time-zone-name=Asia/Tehran
/system identity
set name=NASNET
/system logging
set 0 topics=info,!netwatch
add action=DiskC topics=critical,error,info,warning
/system ntp client
set enabled=yes
/system ntp server
set broadcast=yes enabled=yes manycast=yes multicast=yes
/system ntp client servers
add address=pool.ntp.org
add address=time.cloudflare.com
add address=time.google.com
/system routerboard mode-button
set enabled=yes on-event=dark-mode
/system routerboard wps-button
set enabled=yes on-event=wps-accept
/tool mac-server
set allowed-interface-list=*2000011
/tool mac-server mac-winbox
set allowed-interface-list=*2000011
