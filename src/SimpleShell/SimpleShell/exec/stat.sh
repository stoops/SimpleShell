#!/bin/bash

cpu=$(top -l 1 | grep "^CPU usage:" | awk '{
  gsub(/%/, "", $3);
  gsub(/%/, "", $5);

  pct = int($3 + $5);

  leng = 15
  hashes = int(pct / leng);
  if (hashes > leng) hashes = leng;
  if (hashes < 0)  hashes = 0;

  for (i = 1; i <= hashes; i++) {
    printf "#";
  }

  for (i = hashes + 1; i <= leng; i++) {
    printf ".";
  }

  printf " %2d%%\n", pct;
}')
echo "CPU: $cpu"

ram=$(top -l 1 | grep "^PhysMem:" | awk '{
  gsub(/[^0-9GM.]/, "", $2);
  gsub(/[^0-9GM.]/, "", $4);
  gsub(/[^0-9GM.]/, "", $6);
  gsub(/[^0-9GM.]/, "", $6);

  used = ($2 ~ /M$/) ? substr($2,1,length($2)-1)/1024 : substr($2,1,length($2)-1)+0;
  wird = ($4 ~ /M$/) ? substr($4,1,length($4)-1)/1024 : substr($4,1,length($4)-1)+0;
  comp = ($6 ~ /M$/) ? substr($6,1,length($6)-1)/1024 : substr($6,1,length($6)-1)+0;
  unus = ($8 ~ /M$/) ? substr($8,1,length($8)-1)/1024 : substr($8,1,length($8)-1)+0;

  pct = int(((used - (wird + comp)) / (used + unus)) * 100);

  leng = 15
  hashes = int(pct / leng);
  if (hashes > leng) hashes = leng;
  if (hashes < 0)  hashes = 0;

  for (i = 1; i <= hashes; i++) {
    printf "#";
  }

  for (i = hashes + 1; i <= leng; i++) {
    printf ".";
  }

  printf " %2d%%\n", pct;
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
  while (bits_inp >= 1024 && i < 4) {
    bits_inp /= 1024;
    i++;
  }

  j = 1;
  while (bits_out >= 1024 && j < 4) {
      bits_out /= 1024;
    j++;
  }

  printf "%3d %-4s ↓ In • Up ↑ %3d %-4s\n", bits_inp, unit[i], bits_out, unit[j];
}')
echo "NET: $net"
