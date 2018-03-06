PREFIX ?= /usr

all:
		@echo Run \'make install\' to install osc-easy-install.

install:
		@echo 'Making directories...'
		@mkdir -p $(DESTDIR)$(PREFIX)/bin
		@mkdir -p $(DESTDIR)$(PREFIX)/share/applications

		@echo 'Installing osc-easy-install...'
		@chmod +x osc-easy-install.sh
		@cp -p osc-easy-install.sh $(DESTDIR)$(PREFIX)/bin/osc-easy-install
		@cp -p osc-easy-install.desktop $(DESTDIR)$(PREFIX)/share/applications/osc-easy-install.desktop
		@echo 'osc-easy-install installed!'

uninstall:
		@echo 'Removing files...'
		@rm -f $(DESTDIR)$(PREFIX)/bin/osc-easy-install
		@rm -f $(DESTDIR)$(PREFIX)/share/applications/osc-easy-install.desktop
		@echo 'osc-easy-install uninstalled!'
