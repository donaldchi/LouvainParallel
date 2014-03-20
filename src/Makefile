#!/bin/bash

CC=x10c++
EXEC=commtest community community_pre convert test copy PsudoBP psm countedge sgconvert

CFLAGS=-J-Xmx2G -cxx-prearg -I/work0/t2gsgraph/chi/scalegraph-2.1/include -sourcepath /work0/t2gsgraph/chi/scalegraph-2.1/src
FLAGS=-OPTIMIZE=true -x10rt mpi #-NO_CHECKS 

DFLAGS=-debugpositions ../bin

all: $(EXEC)

#community : ComDetect.x10
commtest : comTest1.x10
	$(CC) $(CFLAGS) $(FLAGS) -bootclasspath ../bin -o $@ $^

community : ComDetect.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

community_pre : ComDetect_pre.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^ 

convert : Convert.x10
	$(CC) $(FLAGS) -o $@ $^ 

test : Test.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

copy : testCopy.x10
	$(CC) $(FLAGS) -o $@ $^

PsudoBP : PsudoBP.x10
	$(CC) -o $@ $^

psm : PSM.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

countedge : CountCrossEdge.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

#graph : Graph.x10
#	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

#sggraph : SGGraph.x10
#	$(CC) -OPTIMIZE=true $(CFLAGS) -o $@ $^

sgconvert : SGConvert.x10
	$(CC) -OPTIMIZE=true  $(CFLAGS) -o $@ $^
##########################################
# Generic rules
##########################################

clean:
	rm -f *.cc *~ *.h $(EXEC)
