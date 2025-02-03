CXX = g++
# Regular flags for testing
CXXFLAGS = -O2 -Wall -Wextra -std=c++11
# Processor-specific optimization for PROC PROTO target
PROCFLAGS = -O3 -Wall -Wextra -std=c++11 -march=native

# Targets:
# Default target builds the optimized shared library for PROC PROTO
all: proc

# Build shared library (for PROC PROTO)
proc: hashmap.cpp
	$(CXX) $(PROCFLAGS) -shared -fPIC -o libhashmap.so hashmap.cpp

# Build and run test executable
test: hashmap.cpp hashmap_test.cpp
	$(CXX) $(CXXFLAGS) -o test_exe hashmap.cpp hashmap_test.cpp
	./test_exe

clean:
	rm -f test_exe libhashmap.so
