INSTALL_DIR=/usr/local/bin

install:
	cp io $(INSTALL_DIR)
	chmod +x $(INSTALL_DIR)/io

test:
