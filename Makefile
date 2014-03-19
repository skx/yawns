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

test-html:
	mkdir -p htdocs/tests || true
	prove -m -Q -P HTML=outfile:htdocs/tests/index.html,force_inline_css:1,force_inline_js:1 tests/*.t
	perl -pi -e 's!file:/usr/share/perl5/TAP/Formatter/HTML/!!g' htdocs/tests/index.html
	perl -pi -e 's!</title>!</title><script src="http://code.jquery.com/jquery-1.11.0.min.js"></script>!g' htdocs/tests/index.html
	cp /usr/share/perl5/TAP/Formatter/HTML/* htdocs/tests/

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

