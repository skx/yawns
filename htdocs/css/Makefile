
%.css : %.in
		python /usr/share/pyshared/slimmer/slimmer.py $< css --output=$@

default: jquery.autocomplete.in layout.in print.in
	@echo "OK"

clean:
	rm *.css || true
