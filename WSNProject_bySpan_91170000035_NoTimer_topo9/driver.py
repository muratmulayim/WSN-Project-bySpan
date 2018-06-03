#! /usr/bin/python
from TOSSIM import *
import sys
import datetime

t = Tossim([])
r = t.radio()
f = open("topo9.txt", "r")
maxNodeID=0;
for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2]
    r.add(int(s[0]), int(s[1]), float(s[2]))
    r.add(int(s[1]), int(s[0]), float(s[2]))
    if maxNodeID < int(s[0]):
      maxNodeID=int(s[0]);
    if maxNodeID<int(s[1]):
      maxNodeID=int(s[1])


#t.addChannel("sendBroadcastMessage", sys.stdout)

#t.addChannel("sendDone", sys.stdout)
#t.addChannel("Timer0fired", sys.stdout)
t.addChannel("printColor", sys.stdout)
t.addChannel("printArray", sys.stdout)
#t.addChannel("printColor2", sys.stdout)
t.addChannel("receiveColor", sys.stdout)
t.addChannel("printStep", sys.stdout)



#t.addChannel("createMessage", sys.stdout)
t.addChannel("Error", sys.stderr)




#t.addChannel("Error", sys.stderr)
for i in range(10000):
    for i in range(1, maxNodeID+1):
      t.getNode(i).addNoiseTraceReading(-80)

for i in range(1, maxNodeID+1):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

for i in range(1, maxNodeID+1):
	t.getNode(i).bootAtTime(i);

for i in range(10000):
	#print "i: ", i
	t.runNextEvent()
  
  
