
%.js : %.in
		python /usr/share/pyshared/slimmer/slimmer.py $< js --output=$@

default: jquery.autocomplete.js
	@echo "OK"

clean:
	rm *.css || true
