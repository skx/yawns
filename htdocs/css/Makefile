
%.css : %.in
		python /usr/share/pyshared/slimmer/slimmer.py $< css --output=$@

default: jquery.autocomplete.css view.css 
	@echo "OK"

clean:
	rm *.css || true
