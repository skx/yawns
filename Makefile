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
	@echo " test         - Simple code tests."
	@echo " test-verbose - Simple code tests."
	@echo " "


.PHONY:
	@true


clean:
	@find . -name '.*~' -exec rm \{\} \;
	@find . -name '.#*' -exec rm \{\} \;
	@find . -name '*~' -exec rm \{\} \;
	@find . -name '*.bak' -exec rm \{\} \;
	@[ -e fabfile.pyc ] && rm fabfile.pyc || true



feeds:
	@./bin/gen-feeds
	@chmod 777 ~/current/htdocs/*.xml
	@chmod 777 ~/current/htdocs/*.rdf

test:
	prove --shuffle tests/

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

