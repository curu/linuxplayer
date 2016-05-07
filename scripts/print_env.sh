#!/bin/bash
##########################################
# print_env.sh: print environment variable of a running process 
# 
# note:
# this script requires glibc debug symbol, so you need either:
# * for static built binary, need to compile with glibc debug info
# * for dynamic link binary, need to install glibc-debuginfo
#
# Author: Curu Wong
# Date:   2016-05-07
##########################################
pid=$1
if [[ -z "$pid" ]]; then
    echo "Usage: $0 pid"
    exit 1
fi
gdb_output=$(
gdb -q -p $pid 2>/dev/null <<'EOF'
set $i=0
define print_env
        while 1
                if environ[$i] == 0 
                        loop_break
                else
                    if $i == 0
                        printf "\n==BEGIN\n"
                    end
                    printf "%s\n", environ[$i]
                end
                set $i = $i + 1
        end
end
print_env
printf "==END\n"
EOF
)

echo "$gdb_output" | sed -ne '/==BEGIN/,/==END/ p' | sed -re '/BEGIN|END/ d'
