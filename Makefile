all: doc

doc: doc_man doc_html

doc_html: html-stamp

html-stamp: grml-debootstrap.8.txt
	sed -i 's/^include::releasetable-man.txt\[\]/include::releasetable.txt\[\]/' grml-debootstrap.8.txt
	asciidoc -b xhtml11 -a icons grml-debootstrap.8.txt
	touch html-stamp

doc_man: man-stamp

man-stamp: grml-debootstrap.8.txt
	sed -i 's/^include::releasetable.txt\[\]/include::releasetable-man.txt\[\]/' grml-debootstrap.8.txt
	asciidoc -d manpage -b docbook grml-debootstrap.8.txt
	xsltproc /usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl grml-debootstrap.8.xml
	touch man-stamp

online: all
	scp grml-debootstrap.8.html grml:/var/www/grml/grml-debootstrap/index.html
	scp images/icons/*          grml:/var/www/grml/grml-debootstrap/images/icons/
	scp images/screenshot.png   grml:/var/www/grml/grml-debootstrap/images/

clean:
	rm -rf grml-debootstrap.8.html grml-debootstrap.8.xml grml-debootstrap.8 html-stamp man-stamp

testrun:
	cd ./packer && $(MAKE) compile && $(MAKE) packer

vagrant:
	vagrant up
