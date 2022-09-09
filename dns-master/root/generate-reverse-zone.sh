#!/bin/bash

ID="14"
prefix="172.16.$ID."
suffix="$ID.16.172.in-addr.arpa."
file="/var/cache/bind/rev.$ID.16.172"

if ! [ -e $file ]; then
    cat > $file << EOF
\$ORIGIN     .
\$TTL 3600       ; 1 hour
$ID.16.172.in-addr.arpa.        IN SOA  $ID.nasa. root.$ID.nasa. (
                                0          ; serial
                                86400      ; refresh (1 day)
                                1800       ; retry (30 minutes)
                                604800     ; expire (1 week)
                                7200       ; minimum (2 hours)
                                )
                        NS      ns1.$ID.nasa.
                        NS      ns2.$ID.nasa.
\$ORIGIN     $ID.16.172.in-addr.arpa.
EOF
    rndc reload
fi

rr=""
rr+=$(dig @172.16.$ID.1 axfr $ID.nasa +noall +answer)
rr+=$(dig @172.16.$ID.2 axfr $ID.nasa +noall +answer)

add=""
while read line; do
    type=$(echo $line | cut -d' ' -f4)
    if [ "$type" = "A" ]; then
        ip=$(echo $line | cut -d' ' -f5)
        domain=$(echo $line | cut -d' ' -f1)
        if [[ "$ip" = "$prefix"* ]]; then
            k=$(echo $ip | cut -d'.' -f4)
            add+="add $k.$suffix 3600 IN PTR $domain\n"
        fi
    fi
done <<<"$rr"

rr=""
rr+=$(dig @172.16.$ID.1 axfr $suffix +noall +answer)
# rr+=$(dig @172.16.$ID.2 axfr $suffix +noall +answer)
del=""
while read line; do
    type=$(echo $line | cut -d' ' -f4)
    if [ "$type" = "PTR" ]; then
        del+="del $line\n"
    fi
done <<<"$rr"

payload="server localhost\n"
payload+="$del"
add="$(echo -ne $add | sort -r | sort -h -u -k2,2)"
while read line; do
    payload+="$line\n"
done <<<"$add"
payload+="show\n"
payload+="send\n"

nsupdate < <(echo -ne $payload)
