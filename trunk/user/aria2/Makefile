SRC_NAME=aria2-1.35.0

THISDIR = $(shell pwd)

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		touch config_done; \
	fi )


clean:
	rm -f config_done

romfs:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_ARIA_WEB_CONTROL),y)
	cp -rf $(THISDIR)/ariaweb $(INSTALLDIR)/www
endif
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/aria2c /usr/bin/aria2c
	$(ROMFSINST) -p +x /usr/bin/aria.sh
