<h1 align="center"> N-Way set associative changes </h1>

This project is an implementation of set associative cache with variable number of ways, sets and memory and block sizes. The "cache.v" file inside the memory project directory gave the following results when run on the traces given below. 
<a href="[url](http://www.cs.toronto.edu/~reid/csc150/02f/a2/traces.html)">http://www.cs.toronto.edu/~reid/csc150/02f/a2/traces.html</a>

(The traces can also be found in the memory project directory where the files are named lu,mm16,mm32 and qsort.)

![image](https://user-images.githubusercontent.com/102411194/201526894-59c20c13-129e-4327-a77a-7cd76c48ed3f.png)

# Description about configurations:- #


Configuration 1


Cache size - 32KB, set size - 64B, Associativity - 8 ways


Configuration 2


Cache size - 32KB, set size - 64B, Direct mapped 


Configuration 3


Cache size - 16KB, set size - 64B, Associativity - 16 ways



## Description of Directory Structure: ##

RandomInsGenerator.cpp:
This file generates random instructions for the specified bits.

cache.v:
This file contains code for calcuulating hit n=and miss rate. Write back is not fully implemented.

cache_full_implementation.v:
This file contains fully implemented code along with write back.

lu.txt
instructions for lu.

mm16.txt
instructions for mm16.

mm32.txt
instructions for mm32.

qsort.txt:
instructions for qsort.


