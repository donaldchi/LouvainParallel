#!/bin/bash

CC=x10c++
EXEC=community convert test copy comm commtest 

CFLAGS=-J-Xmx2G -cxx-prearg -Iscalegraph_home/include -sourcepath /work0/t2gsgraph/chi/scalegraph-2.1/src
FLAGS=-OPTIMIZE=true -x10rt mpi  

all: $(EXEC)

#community : ComDetect.x10
community : ComDetect.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^ 

convert : Convert.x10
	$(CC) $(FLAGS) -o $@ $^ 

test : Test.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

copy : testCopy.x10
	$(CC) $(FLAGS) -o $@ $^

comm : Communication.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^

commtest : comTest1.x10
	$(CC) $(CFLAGS) $(FLAGS) -o $@ $^
##########################################
# Generic rules
##########################################

clean:
	rm -f *.cc *~ *.h $(EXEC)
