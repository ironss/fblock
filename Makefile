
testfiles=$(wildcard test/test_*)
tests=$(patsubst test/%.lua, %, $(testfiles))

all: $(tests)

$(tests): 
	test/$@.lua
	
test: $(testfiles) $(tests)

.PHONY: test $(tests)

