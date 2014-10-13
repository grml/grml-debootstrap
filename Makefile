BASH_SCRIPTS = grml-debootstrap
SHELL_SCRIPTS = chroot-script
MKSH_SCRIPTS = bootgrub.mksh

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
	xsltproc --stringparam man.base.url.for.relative.links http://grml.org/grml-debootstrap/ \
		/usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl grml-debootstrap.8.xml
	touch man-stamp

shellcheck:
	@echo -n "Checking for shell syntax errors"; \
	for SCRIPT in $(SHELL_SCRIPTS); do \
		test -r $${SCRIPT} || continue ; \
		sh -n $${SCRIPT} || exit ; \
		echo -n "."; \
	done; \
	for SCRIPT in $(BASH_SCRIPTS) ; do \
		test -r $${SCRIPT} || continue ; \
		bash -n $${SCRIPT} || exit ; \
		echo -n "."; \
	done; \
	for SCRIPT in $(MKSH_SCRIPTS) ; do \
		test -r $${SCRIPT} || continue ; \
		mksh -n $${SCRIPT} || exit ; \
		echo -n "."; \
	done; \
	echo " done."

clean:
	rm -rf grml-debootstrap.8.html grml-debootstrap.8.xml grml-debootstrap.8 html-stamp man-stamp

testrun:
	cd ./packer && $(MAKE) compile && $(MAKE) packer

vagrant:
	vagrant up
