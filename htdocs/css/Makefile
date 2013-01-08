
%.css : %.in
		python /usr/share/pyshared/slimmer/slimmer.py $< css --output=$@

default: jquery.autocomplete.css layout.css print.css
	@echo "OK"

clean:
	rm *.css || true
