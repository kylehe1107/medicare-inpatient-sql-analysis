#!/usr/bin/env python3
"""
Inject query results (outputs/results/all_results.json) into the
dashboard template and write dashboard.html at the project root.
Self-contained: works offline except for the Chart.js CDN.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = os.path.join(ROOT, "outputs", "results", "all_results.json")
TEMPLATE = os.path.join(ROOT, "scripts", "dashboard_template.html")
OUT = os.path.join(ROOT, "dashboard.html")

data = json.load(open(RESULTS))
html = open(TEMPLATE).read().replace("/*__DATA__*/", json.dumps(data))
open(OUT, "w").write(html)
print(f"Wrote {OUT} ({os.path.getsize(OUT)/1024:.0f} KB)")
