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

ram=$(vm_stat | tr 'A-Z' 'a-z' | tr '.' ' ' | awk -v page=$(pagesize) -v memb=$(sysctl -n hw.memsize) '
/wired down/      {wire=$NF}
/anonymous pages/ {anon=$NF}
/pages purgeable/ {purg=$NF}
/pages occupied/  {comp=$NF}
END {
  apps = (anon - purg);
  useb = ((apps + wire + comp) * page);
  used = (useb / (1024^3));
  totl = (memb / (1024^3));

  prct = int(((useb / memb) * 100) + 1);

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
  inpb = (($1 - inp1) * 8);
  outb = (($2 - out1) * 8);

  split(" b/s,Kb/s,Mb/s,Gb/s", unit, ",");

  i = 1;
  while ((inpb >= 1000) && (i < 4)) {
    inpb /= 1000; i++;
  }
  if (i == 1) {
    inps = sprintf("%0.1f", inpb / 1000); i++;
  } else {
    inps = sprintf("%3d", inpb);
  }

  j = 1;
  while ((outb >= 1000) && (j < 4)) {
    outb /= 1000; j++;
  }
  if (j == 1) {
    outs = sprintf("%0.1f", outb / 1000); j++;
  } else {
    outs = sprintf("%3d", outb);
  }

  printf "%s %-4s D %%d • %%u U %s %-4s\n", inps, unit[i], outs, unit[j];
  fflush();
}')
echo "NET: $net"
