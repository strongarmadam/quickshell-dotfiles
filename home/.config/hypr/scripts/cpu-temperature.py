#!/usr/bin/env python3
"""Read CPU temperature from AMD, Intel, or generic Linux thermal sensors."""
from pathlib import Path
values=[]
for h in Path('/sys/class/hwmon').glob('hwmon*'):
 try:name=(h/'name').read_text().strip()
 except OSError:continue
 if name not in ('k10temp','coretemp','zenpower','cpu_thermal','acpitz'):continue
 for p in h.glob('temp*_input'):
  try:
   value=int(p.read_text())
   if 0<value<150000:values.append((name!='acpitz',value))
  except (OSError,ValueError):pass
if not values:
 for p in Path('/sys/class/thermal').glob('thermal_zone*/temp'):
  try:
   value=int(p.read_text())
   if 0<value<150000:values.append((False,value))
  except (OSError,ValueError):pass
print(max(values)[1] if values else 0)
