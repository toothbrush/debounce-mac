.PHONY: all
all: debounce

debounce: debounce.m
	clang -fobjc-arc -framework Cocoa $^ -o $@

.PHONY: install
install: debounce
	cp $< /usr/local/bin
