BASH_SCRIPTS = grml-debootstrap
SHELL_SCRIPTS = chroot-script
DOCBOOK_XML=/usr/share/xml/docbook/stylesheet/nwalsh/manpages/docbook.xsl

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
	xsltproc --nonet --stringparam man.base.url.for.relative.links http://grml.org/grml-debootstrap/ \
		$(DOCBOOK_XML) grml-debootstrap.8.xml
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
	echo " done."

install:
	mkdir -p $(DESTDIR)/etc/debootstrap/
	mkdir -p $(DESTDIR)/etc/debootstrap/extrapackages
	mkdir -p $(DESTDIR)/usr/sbin/
	mkdir -p $(DESTDIR)/etc/zsh/completion.d/
	mkdir -p $(DESTDIR)/usr/share/grml-debootstrap/functions/
	install -m 644 config           $(DESTDIR)/etc/debootstrap/
	install -m 644 devices.tar.gz   $(DESTDIR)/etc/debootstrap/
	install -m 644 locale.gen       $(DESTDIR)/etc/debootstrap/
	install -m 644 packages         $(DESTDIR)/etc/debootstrap/
	install -m 755 chroot-script    $(DESTDIR)/etc/debootstrap/
	install -m 755 grml-debootstrap $(DESTDIR)/usr/sbin/
	install -m 644 zsh-completion   $(DESTDIR)/etc/zsh/completion.d/_grml-debootstrap
	install -m 644 cmdlineopts.clp  $(DESTDIR)/usr/share/grml-debootstrap/functions/cmdlineopts.clp

clean:
	rm -rf grml-debootstrap.8.html grml-debootstrap.8.xml grml-debootstrap.8 html-stamp man-stamp packer/local_dir/

testrun:
	cd ./packer && $(MAKE) compile && $(MAKE) jessie

vagrant:
	vagrant up
