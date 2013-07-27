
testfiles=$(wildcard test/test_*)
tests=$(patsubst test/%, %, $(testfiles))

all: $(tests)

$(tests): 
	test/$@
	
test: $(testfiles)
	echo $(testfiles)
	$(foreach f, $^, $f;)

.PHONY: test $(tests)

