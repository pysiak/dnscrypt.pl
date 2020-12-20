#!/bin/bash
echo "$(date +%c) Downloading"
BLOCKFILE_GUARDIAN=/etc/guardian.txt
BLOCKFILE_ARMADA=/etc/armada.txt

echo "$(date +%c) 01/14 (undelegated)"
wget -q https://github.com/jedisct1/encrypted-dns-server/raw/master/undelegated.txt -O /etc/undelegated.txt
echo "$(date +%c) 02/14"
wget -q https://hole.cert.pl/domains/domains.txt -O /tmp/cert.txt
echo "$(date +%c) 03/14"
wget -q https://phishing.army/download/phishing_army_blocklist_extended.txt -O /tmp/phishingarmy.txt
echo "$(date +%c) 04/14"
wget -q https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt -O /tmp/notrack.txt
echo "$(date +%c) 05/14"
wget -q https://joewein.net/dl/bl/dom-bl-base.txt -O /tmp/dombl.txt
echo "$(date +%c) 06/14"
wget -q https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/malware/domains -O /tmp/malware.txt
echo "$(date +%c) 07/14"
wget -q https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/phishing/domains -O /tmp/phishing.txt
echo "$(date +%c) 08/14"
wget -q https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADomains.txt -O /tmp/kad.txt
echo "$(date +%c) 09/14"
wget -q https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt -O /tmp/phishing_krogza.txt
echo "$(date +%c) 10/14"
wget -q https://malc0de.com/bl/BOOT -O /tmp/malc0de
echo "$(date +%c) 11/14"
wget -q https://openphish.com/feed.txt -O /tmp/openphish
echo "$(date +%c) 12/14"
wget -q https://v.firebog.net/hosts/Prigent-Malware.txt -O /tmp/prigent-malware
echo "$(date +%c) 13/14"
wget -q https://v.firebog.net/hosts/APT1Rep.txt -O /tmp/apt1
echo "$(date +%c) 14/14"
wget -q https://cybercrime-tracker.net/all.php -O /tmp/cybercrime
echo "$(date +%c) Manual Blocks"
wget -q https://raw.githubusercontent.com/pysiak/dnscrypt.pl/main/configs/manualblocks.conf -O /etc/unbound/manualblocks.conf

echo "$(date +%c) Merging guardian"
cat /tmp/cert.txt > ${BLOCKFILE_GUARDIAN}
grep -v \# /tmp/phishingarmy.txt >> ${BLOCKFILE_GUARDIAN}
grep -v \# /tmp/notrack.txt >> ${BLOCKFILE_GUARDIAN}
cat /tmp/malware.txt >> ${BLOCKFILE_GUARDIAN}
cat /tmp/phishing.txt >> ${BLOCKFILE_GUARDIAN}

echo "$(date +%c) Merging armada"
cat /tmp/cert.txt > ${BLOCKFILE_ARMADA}
grep -v \# /tmp/phishingarmy.txt >> ${BLOCKFILE_ARMADA}
grep -v \# /tmp/notrack.txt >> ${BLOCKFILE_ARMADA}
cat /tmp/dombl.txt >> ${BLOCKFILE_ARMADA}
cat /tmp/malware.txt >> ${BLOCKFILE_ARMADA}
cat /tmp/phishing.txt >> ${BLOCKFILE_ARMADA}
grep -v \# /tmp/kad.txt | grep \. >> ${BLOCKFILE_ARMADA}
cat /tmp/phishing_krogza.txt >> ${BLOCKFILE_ARMADA}
grep PRIMARY /tmp/malc0de | awk '{ print $2}' >> ${BLOCKFILE_ARMADA}
cat /tmp/openphish | awk -F/ '{ print $3}' >> ${BLOCKFILE_ARMADA}
cat /tmp/prigent-malware >> ${BLOCKFILE_ARMADA}
cat /tmp/apt1 >> ${BLOCKFILE_ARMADA}
cat /tmp/cybercrime |awk -F/ ' {print $1}' >> ${BLOCKFILE_ARMADA}
grep -v \# /etc/unbound/manualblocks.conf >> ${BLOCKFILE_ARMADA}

echo "$(date +%c) Unique only"
sort ${BLOCKFILE_GUARDIAN} | uniq > ${BLOCKFILE_GUARDIAN}.tmp
mv ${BLOCKFILE_GUARDIAN}.tmp ${BLOCKFILE_GUARDIAN}
sort ${BLOCKFILE_ARMADA} | uniq > ${BLOCKFILE_ARMADA}.tmp
mv ${BLOCKFILE_ARMADA}.tmp ${BLOCKFILE_ARMADA}

echo "$(date +%c) Removing whitelisted"
wget -q https://raw.githubusercontent.com/pysiak/dnscrypt.pl/main/configs/whitelist.conf -O /etc/unbound/whitelist.conf
grep -Fvx -f /etc/unbound/whitelist.conf ${BLOCKFILE_ARMADA} > ${BLOCKFILE_ARMADA}.tmp
mv ${BLOCKFILE_ARMADA}.tmp ${BLOCKFILE_ARMADA}
grep -Fvx -f /etc/unbound/whitelist.conf ${BLOCKFILE_GUARDIAN} > ${BLOCKFILE_GUARDIAN}.tmp
mv ${BLOCKFILE_GUARDIAN}.tmp ${BLOCKFILE_GUARDIAN}

echo "$(date +%c) $(wc -l ${BLOCKFILE_GUARDIAN})"
echo "$(date +%c) Restarting encrypted-dns"
systemctl restart encdns2054

echo "$(date +%c) $(wc -l ${BLOCKFILE_ARMADA})"
echo "$(date +%c) Restarting encrypted-dns"
systemctl restart encdns2055

echo "$(date +%c) Copying to website"
cp ${BLOCKFILE_ARMADA} /var/www/armada.txt
cat ${BLOCKFILE_ARMADA} | wc -l > /var/www/armada_count.txt
cp ${BLOCKFILE_GUARDIAN} /var/www/guardian.txt
cat ${BLOCKFILE_GUARDIAN} | wc -l > /var/www/guardian_count.txt

echo "$(date +%c) Done"
