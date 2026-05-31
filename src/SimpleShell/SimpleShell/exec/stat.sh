#!/bin/bash

export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

cpu=$(top -l 1 | grep "^CPU usage:" | awk '{
  gsub(/%/, "", $3);
  gsub(/%/, "", $5);

  prct = int($3 + $5);

  leng = 15
  mark = int((prct * leng) / 100);
  if (mark > leng) mark = leng;
  if (mark < 0)  mark = 0;

  bars = "";
  for (i = 1; i <= mark; i++) bars = bars "#";
  for (i = mark + 1; i <= leng; i++) bars = bars ".";

  printf "%s %2d%%\n", bars, prct;
  fflush();
}')
echo "CPU: $cpu"

ram=$(vm_stat | awk -v pagesize=$(pagesize) -v total_mem=$(sysctl -n hw.memsize) '
/Pages wired down/ {wired=$4}
/Anonymous pages/ {anonymous=$3}
/Pages purgeable/ {purgeable=$3}
/Pages occupied by compressor/ {compressed=$5}
END {
  app = (anonymous - purgeable);
  used_bytes = (app + wired + compressed) * pagesize;
  used_gb = used_bytes / (1024^3);
  total_gb = total_mem / (1024^3);

  prct = int(((used_bytes / total_mem) * 100) + 1);

  leng = 15
  mark = int((prct * leng) / 100);
  if (mark > leng) mark = leng;
  if (mark < 0)  mark = 0;

  bars = "";
  for (i = 1; i <= mark; i++) bars = bars "#";
  for (i = mark + 1; i <= leng; i++) bars = bars ".";

  printf "%s %2d%%\n", bars, prct;
  fflush();
}')
echo "RAM: $ram"

net=$((
  netstat -bi -I en0 | awk 'NR==2{print $7, $10}'
  sleep 1
  netstat -bi -I en0 | awk 'NR==2{print $7, $10}'
) | awk '
NR == 1 {
  inp1 = $1;
  out1 = $2;
}
NR == 2 {
  bits_inp = (($1 - inp1) * 8);
  bits_out = (($2 - out1) * 8);

  split(" b/s,Kb/s,Mb/s,Gb/s", unit, ",");

  i = 1;
  while ((bits_inp >= 1000) && (i < 4)) {
    bits_inp /= 1000;
    i++;
  }

  j = 1;
  while ((bits_out >= 1000) && (j < 4)) {
    bits_out /= 1000;
    j++;
  }

  printf "%3d %-4s In %%d • %%u Up %3d %-4s\n", bits_inp, unit[i], bits_out, unit[j];
  fflush();
}')
echo "NET: $net"
