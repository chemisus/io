INSTALL_DIR=/usr/local/bin

install:
	cp io $(INSTALL_DIR)
	chmod +x $(INSTALL_DIR)/io

test:
	./io json csv test1.json | ./io csv json - \
	| ./io json tsv - | ./io tsv json - \
	| ./io json ssv - | ./io ssv json - \
	| comm expect1.json - --nocheck-order -3
