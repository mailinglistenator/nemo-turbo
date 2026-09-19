PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
SYSTEMD_USER_DIR ?= $(HOME)/.config/systemd/user

CLI = bin/nemo-turbo
SERVICE = systemd/nemo-turbo.service

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -fPIC
LDFLAGS ?= -shared -ldl

.PHONY: all install uninstall clean test-c-hook

all:
	@echo "nemo-turbo v1.1.0 (Native NEMO_PERSIST Engine)"
	@echo "Run 'make install' to install the service and CLI (no compiler required)."

install:
	@mkdir -p $(BINDIR) $(SYSTEMD_USER_DIR)
	install -m 755 $(CLI) $(BINDIR)/nemo-turbo
	install -m 644 $(SERVICE) $(SYSTEMD_USER_DIR)/nemo-turbo.service
	@rm -f $(LIBDIR)/libnemo-turbo.so 2>/dev/null || true
	systemctl --user daemon-reload
	systemctl --user enable --now nemo-turbo.service
	@echo "============================================="
	@echo "nemo-turbo installed and activated!"
	@echo "Run 'nemo-turbo status' or 'nemo-turbo bench'"
	@echo "============================================="

uninstall:
	-systemctl --user stop nemo-turbo.service 2>/dev/null || true
	-systemctl --user disable nemo-turbo.service 2>/dev/null || true
	rm -f $(BINDIR)/nemo-turbo
	rm -f $(LIBDIR)/libnemo-turbo.so
	rm -f $(SYSTEMD_USER_DIR)/nemo-turbo.service
	systemctl --user daemon-reload
	@echo "nemo-turbo uninstalled successfully."

# Optional: compile legacy C interposition module for reference/comparison
test-c-hook:
	@mkdir -p build
	$(CC) $(CFLAGS) src/nemo-turbo.c $(LDFLAGS) -o build/libnemo-turbo.so
	@echo "Built build/libnemo-turbo.so for benchmarking."

clean:
	rm -rf build
