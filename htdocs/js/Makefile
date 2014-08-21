
%.js : %.in
		python /usr/share/pyshared/slimmer/slimmer.py $< js --output=$@

default: jquery.autogrow.js jquery.sidebarToggler.102.js jquery.autocomplete.js
	@echo "OK"

clean:
	rm *.css || true
