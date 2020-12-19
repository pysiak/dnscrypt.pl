# DNSCrypt Poland
This page is maintained by @dnscryptpl for visibility of blocklists, scripts and configuration as means of transparency for [DNSCrypt Poland](https://dnscrypt.pl)
This is pure open source spirit.

## Transparency
*config* folder contains the official configuration for [transparency](https://dnscrypt.pl/transparency/ "Transparency page of DNSCrypt Poland")

*scripts* folder contains the official scripts for [transparency](https://dnscrypt.pl/transparency/ "Transparency page of DNSCrypt Poland")

## Setup
dnscrypt.pl runs 3 services:
* dnscrypt.pl -> no blocklists
* dnscrypt.pl-guardian (undelegated + 5 blocklists - whitelist)
  * encrypted-dns-server undelegated domains: https://github.com/jedisct1/encrypted-dns-server/raw/master/undelegated.txt
  * cert: https://hole.cert.pl/domains/domains.txt
  * phishing army: https://phishing.army/download/phishing_army_blocklist_extended.txt
  * notrack malware: https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt
  * ut1 malware domains: https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/malware/domains
  * ut1 phishing domains: https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/phishing/domains
  * WHITELIST: https://github.com/pysiak/dnscrypt.pl/blob/main/configs/whitelist.conf
  
* dnscrypt.pl-armada: (undelegated + 5 blocklists + 7 other blocklists + 1 manually main
  * all of dnscrypt.pl-guardian
  * manually maintained list added as I observe them through twitter and other sources: https://github.com/pysiak/dnscrypt.pl/blob/main/configs/manualblocks.conf
  * Polish Filters Team: https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADomains.txt
  * dom-bl-base: https://joewein.net/dl/bl/dom-bl-base.txt
  * mitchellkrogza phishing database: https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt
  * malc0de: http://malc0de.com/bl/BOOT
  * openphish: https://openphish.com/feed.txt
  * firebog prigent-malware: https://v.firebog.net/hosts/Prigent-Malware.txt
  * firebog apt1: https://v.firebog.net/hosts/APT1Rep.txt
  * WHITELIST: https://github.com/pysiak/dnscrypt.pl/blob/main/configs/whitelist.conf
