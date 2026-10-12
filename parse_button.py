with open("secure_button_utf8.txt", "r", encoding="utf-8") as f:
    text = f.read()

import re

for target in ["performClick", "onFilterTouchEventForSecurity", "dispatchTouchEvent", "onTouchEvent", "logProgrammaticClickAttempt", "logFraudTouchAttempt"]:
    print(f"============================== {target} ==============================")
    pattern = rf"name\s+:\s+\x27{target}\x27.*?(?=(?:#\d+\s+:|Virtual methods|Direct methods|\Z))"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        lines = match.group(0).split("\n")
        for l in lines[:70]:
            print(l)
    print("\n")
