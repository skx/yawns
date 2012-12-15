#
#  Utility makefile for people working with Yawns.
#



nop:
	@echo "Valid targets are (alphabetically) :"
	@echo " "
	@echo " clean     - Remove bogus files."
	@echo " feeds     - Update our output feeds".
	@echo " "
	@echo " Debian-Administration.org specific:"
	@echo " "
	@echo " cache     - Show cache hits & misses"
	@echo " daily     - Run daily cleanup tasks"
	@echo " restart   - Restart Apache2 + Memcached."
	@echo " test      - Simple code tests."
	@echo " "


.PHONY:
	@true

cache:
	@echo -e 'stats\r\nquit\r\n' | nc localhost 11211 | grep 'hit' | awk '{ printf("hits  : %8s\n", $$3)}'
	@echo -e 'stats\r\nquit\r\n' | nc localhost 11211 | grep 'miss' | awk '{ printf("misses: %8s\n", $$3)}'


clean:
	@find . -name '.*~' -exec rm \{\} \;
	@find . -name '.#*' -exec rm \{\} \;
	@find . -name '*~' -exec rm \{\} \;
	@find . -name '*.bak' -exec rm \{\} \;
	@[ -e fabfile.pyc ] && rm fabfile.pyc || true


daily:  clean oldmessages uncache


feeds:
	@./bin/gen-feeds
	@chmod 777 /srv/yawns/current/htdocs/*.xml
	@chmod 777 /srv/yawns/current/htdocs/*.rdf

oldmessages:
	@./bin/expire-messages

uncache:
	@./bin/uncache-all

test:
	prove --shuffle tests/

test-output:
	@./bin/test-output

test-verbose:
	prove --shuffle --verbose tests/


#
#  Run our main script(s) through perltidy
#
tidy:
	if [ -x /usr/bin/perltidy ]; then \
	for i in `find . -name '*.pm' -o -name '*.cgi' `; do \
		echo "tidying $$i"; \
		perltidy  $$i \
	; done \
	; fi

