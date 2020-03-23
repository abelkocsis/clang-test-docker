
#!/usr/bin/python

import sys
import re
import subprocess

projects = []
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
projects = splittedArgs[1]

mode = re.findall(r'[^\[\]\,]+', mode)
projects = re.findall(r'[^\[\]\,]+', projects)
projects.append("codechecker")

for p in projects:
    print "./requirements/" + p + "_debian.txt"
    bashCommand = "#!/bin/bash \n cat ./requirements/" + p + "_debian.txt | xargs apt-get -yqq install"
    print bashCommand
    p = subprocess.Popen(bashCommand.split(), shell=True, stdout=subprocess.PIPE)
    for line in p.stdout:
        print line
    p.wait()
    print p.returncode
print "done"

