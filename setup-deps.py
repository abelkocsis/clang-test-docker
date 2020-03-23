
#!/usr/bin/python

import sys
import re

projets = []
mode = []

input=''
sys.argv.pop(0)
input = ''.join(sys.argv)
print input

splittedArgs = re.findall(r'\[[^]]+\]', input)
if len(splittedArgs) != 2:
    print "ERROR!"

print splittedArgs[0]
mode = splittedArgs[0]
projets = splittedArgs[1]

mode = re.findall(r'[^\[\]\,]+', mode)
projets = re.findall(r'[^\[\]\,]+', projets)

