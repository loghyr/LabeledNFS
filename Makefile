# Copyright (C) The IETF Trust (2011)
#

YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
PREVVERS=00
VERS=01

autogen/%.xml : %.x
	@mkdir -p autogen
	@rm -f $@.tmp $@
	@cat $@.tmp | sed 's/^\%//' | sed 's/</\&lt;/g'| \
	awk ' \
		BEGIN	{ print "<figure>"; print" <artwork>"; } \
			{ print $0 ; } \
		END	{ print " </artwork>"; print"</figure>" ; } ' \
	| expand > $@
	@rm -f $@.tmp

all: html txt

#
# Build the stuff needed to ensure integrity of document.
common: testx html

txt: draft-quiqley-nfsv4-labeled-$(VERS).txt

html: draft-quiqley-nfsv4-labeled-$(VERS).html

nr: draft-quiqley-nfsv4-labeled-$(VERS).nr

xml: draft-quiqley-nfsv4-labeled-$(VERS).xml

clobber:
	$(RM) draft-quiqley-nfsv4-labeled-$(VERS).txt \
		draft-quiqley-nfsv4-labeled-$(VERS).html \
		draft-quiqley-nfsv4-labeled-$(VERS).nr
	export SPECVERS := $(VERS)
	export VERS := $(VERS)

clean:
	rm -f $(AUTOGEN)
	rm -rf autogen
	rm -f draft-quiqley-nfsv4-labeled-$(VERS).xml
	rm -rf draft-$(VERS)
	rm -f draft-$(VERS).tar.gz
	rm -rf testx.d
	rm -rf draft-tmp.xml

# Parallel All
pall: 
	$(MAKE) xml
	( $(MAKE) txt ; echo .txt done ) & \
	( $(MAKE) html ; echo .html done ) & \
	wait

draft-quiqley-nfsv4-labeled-$(VERS).txt: draft-quiqley-nfsv4-labeled-$(VERS).xml
	rm -f $@ draft-tmp.txt
	sh xml2rfc_wrapper.sh draft-quiqley-nfsv4-labeled-$(VERS).xml draft-tmp.txt
	mv draft-tmp.txt $@

draft-quiqley-nfsv4-labeled-$(VERS).html: draft-quiqley-nfsv4-labeled-$(VERS).xml
	rm -f $@ draft-tmp.html
	sh xml2rfc_wrapper.sh draft-quiqley-nfsv4-labeled-$(VERS).xml draft-tmp.html
	mv draft-tmp.html $@

draft-quiqley-nfsv4-labeled-$(VERS).nr: draft-quiqley-nfsv4-labeled-$(VERS).xml
	rm -f $@ draft-tmp.nr
	sh xml2rfc_wrapper.sh draft-quiqley-nfsv4-labeled-$(VERS).xml $@.tmp
	mv draft-tmp.nr $@

labelednfs_front_autogen.xml: labelednfs_front.xml Makefile
	sed -e s/DAYVAR/${DAY}/g -e s/MONTHVAR/${MONTH}/g -e s/YEARVAR/${YEAR}/g < labelednfs_front.xml > labelednfs_front_autogen.xml

labelednfs_rfc_start_autogen.xml: labelednfs_rfc_start.xml Makefile
	sed -e s/VERSIONVAR/${VERS}/g < labelednfs_rfc_start.xml > labelednfs_rfc_start_autogen.xml

AUTOGEN =	\
		labelednfs_front_autogen.xml \
		labelednfs_rfc_start_autogen.xml

START_PREGEN = labelednfs_rfc_start.xml
START=	labelednfs_rfc_start_autogen.xml
END=	labelednfs_rfc_end.xml

FRONT_PREGEN = labelednfs_front.xml

IDXMLSRC_BASE = \
	labelednfs_middle_start.xml \
	labelednfs_middle_introduction.xml \
	labelednfs_middle_iana.xml \
	labelednfs_middle_end.xml \
	labelednfs_back_front.xml \
	labelednfs_back_references.xml \
	labelednfs_back_acks.xml \
	labelednfs_back_back.xml

IDCONTENTS = labelednfs_front_autogen.xml $(IDXMLSRC_BASE)

IDXMLSRC = labelednfs_front.xml $(IDXMLSRC_BASE)

draft-tmp.xml: $(START) Makefile $(END)
		rm -f $@ $@.tmp
		cp $(START) $@.tmp
		chmod +w $@.tmp
		for i in $(IDCONTENTS) ; do echo '<?rfc include="'$$i'"?>' >> $@.tmp ; done
		cat $(END) >> $@.tmp
		mv $@.tmp $@

draft-quiqley-nfsv4-labeled-$(VERS).xml: draft-tmp.xml $(IDCONTENTS) $(AUTOGEN)
		rm -f $@
		cp draft-tmp.xml $@

genhtml: Makefile gendraft html txt draft-$(VERS).tar
	./gendraft draft-$(PREVVERS) \
		draft-quiqley-nfsv4-labeled-$(PREVVERS).txt \
		draft-$(VERS) \
		draft-quiqley-nfsv4-labeled-$(VERS).txt \
		draft-quiqley-nfsv4-labeled-$(VERS).html \
		draft-quiqley-nfsv4-labeled-dot-x-04.txt \
		draft-quiqley-nfsv4-labeled-dot-x-05.txt \
		draft-$(VERS).tar.gz

testx: 
	rm -rf testx.d
	mkdir testx.d
	( cd testx.d ; \
		rpcgen -a labelednfs.x ; \
		$(MAKE) -f make* )

spellcheck: $(IDXMLSRC)
	for f in $(IDXMLSRC); do echo "Spell Check of $$f"; spell +dictionary.txt $$f; done

AUXFILES = \
	dictionary.txt \
	gendraft \
	Makefile \
	errortbl \
	rfcdiff \
	xml2rfc_wrapper.sh \
	xml2rfc

DRAFTFILES = \
	draft-quiqley-nfsv4-labeled-$(VERS).txt \
	draft-quiqley-nfsv4-labeled-$(VERS).html \
	draft-quiqley-nfsv4-labeled-$(VERS).xml

draft-$(VERS).tar: $(IDCONTENTS) $(START_PREGEN) $(FRONT_PREGEN) $(AUXFILES) $(DRAFTFILES)
	rm -f draft-$(VERS).tar.gz
	tar -cvf draft-$(VERS).tar \
		$(START_PREGEN) \
		$(END) \
		$(FRONT_PREGEN) \
		$(IDCONTENTS) \
		$(AUXFILES) \
		$(DRAFTFILES) \
		gzip draft-$(VERS).tar
