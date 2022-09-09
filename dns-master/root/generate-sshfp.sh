#!/bin/bash

ID=14
f=/var/cache/bind/$ID.nasa.sshfp

echo > $f

rr=$(dig @ns.$ID.nasa $ID.nasa AXFR +noall +answer)
while read line; do
    type=$(echo $line | cut -d' ' -f4)
    if [ $type = "A" ]; then
        domain=$(echo $line | cut -d' ' -f1)
        ssh-keyscan -D $domain >>$f
    fi
done <<<"$rr"
