all: doc

doc: doc_man doc_html

doc_html: html-stamp

html-stamp: grml-debootstrap.txt
	sed -i 's/^include::releasetable-man.txt\[\]/include::releasetable.txt\[\]/' grml-debootstrap.txt
	asciidoc -b xhtml11 grml-debootstrap.txt
	touch html-stamp

doc_man: man-stamp

man-stamp: grml-debootstrap.txt
	sed -i 's/^include::releasetable.txt\[\]/include::releasetable-man.txt\[\]/' grml-debootstrap.txt
	asciidoc -d manpage -b docbook grml-debootstrap.txt
	sed -i 's/<emphasis role="strong">/<emphasis role="bold">/' grml-debootstrap.xml
	xsltproc /usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl grml-debootstrap.xml
	# ugly hack to avoid duplicate empty lines in manpage
	# notice: docbook-xsl 1.71.0.dfsg.1-1 is broken! make sure you use 1.68.1.dfsg.1-0.2!
	cp grml-debootstrap.8 grml-debootstrap.8.tmp
	uniq grml-debootstrap.8.tmp > grml-debootstrap.8
	rm grml-debootstrap.8.tmp
	touch man-stamp

online: all
	scp grml-debootstrap.html grml:/var/www/grml/grml-debootstrap/index.html

clean:
	rm -rf grml-debootstrap.html grml-debootstrap.xml grml-debootstrap.8 html-stamp man-stamp
