CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -fPIC
LDFLAGS ?= -shared -ldl

PREFIX ?= $(HOME)/.local
LIBDIR ?= $(PREFIX)/lib
BINDIR ?= $(PREFIX)/bin
SYSTEMD_USER_DIR ?= $(HOME)/.config/systemd/user

TARGET = build/libnemo-turbo.so
SRC = src/nemo-turbo.c
CLI = bin/nemo-turbo
SERVICE = systemd/nemo-turbo.service

.PHONY: all clean install uninstall

all: $(TARGET)

$(TARGET): $(SRC)
	@mkdir -p build
	$(CC) $(CFLAGS) $(SRC) $(LDFLAGS) -o $(TARGET)
	@echo "Built $(TARGET) successfully."

install: all
	@mkdir -p $(LIBDIR) $(BINDIR) $(SYSTEMD_USER_DIR)
	install -m 755 $(TARGET) $(LIBDIR)/libnemo-turbo.so
	install -m 755 $(CLI) $(BINDIR)/nemo-turbo
	install -m 644 $(SERVICE) $(SYSTEMD_USER_DIR)/nemo-turbo.service
	systemctl --user daemon-reload
	systemctl --user enable --now nemo-turbo.service
	@echo "============================================="
	@echo "nemo-turbo installed and activated!"
	@echo "Run 'nemo-turbo status' or 'nemo-turbo bench'"
	@echo "============================================="

uninstall:
	-systemctl --user stop nemo-turbo.service 2>/dev/null || true
	-systemctl --user disable nemo-turbo.service 2>/dev/null || true
	rm -f $(LIBDIR)/libnemo-turbo.so
	rm -f $(BINDIR)/nemo-turbo
	rm -f $(SYSTEMD_USER_DIR)/nemo-turbo.service
	systemctl --user daemon-reload
	@echo "nemo-turbo uninstalled successfully."

clean:
	rm -rf build
