#
#  Makefile
#
#  Execute 'make help' for a list of build targets.
#

target = diploma_thesis
paper_size ?= a4
#paper_size ?= letter
pdf_quality ?= printer

all: pdf

##  Rule to generate plot output from the gnuplot input.
plot/%.eps: plot/%.plot
	@echo "$< --> $@"
	gnuplot plot/term-eps-nofont.plot $< > $@

plot/%-color.eps: plot/%.plot
	@echo "$< --> $@"
	gnuplot plot/term-eps-nofont-color.plot $< > $@

plot/%.pdf: plot/%.eps
	@echo "$< --> $@"
	epstopdf $< > $@

##  Rules to generate other output
fig/%.eps: fig/%.fig
	@echo "$< --> $@"
	@fig2dev -L eps -p dummy $< $@

fig/%.eps: fig/%.gif
	@echo "$< --> $@"
	@giftopnm $< | pnmtops -noturn -rle > $@

fig/%.eps: fig/%.prn
	@echo "$< --> $@"
	@ps2eps -f $<

fig/%.eps: fig/%.ps
	@echo $(EPS)
	@echo "$< --> $@"
	@ps2eps -f $<

fig/%.pdf: fig/%.eps
	@echo "$< --> $@"
	epstopdf --embed $< > $@ || epstopdf --embed fig/$*.prn > $@

plotclean::
	rm -f plot/*.eps plot/*.pdf

texclean::
	rm -f *.aux

clean::
	rm -f $(eps_targets) $(pdf_targets) rev.tex


###########################################################################

pdf_target = $(addsuffix .pdf, $(target))
ps_target = $(addsuffix .ps, $(target))
dvi_target = $(addsuffix .dvi, $(target))

eps_targets = $(shell grep 'includegraphics' *.tex | grep -v "\%"  | grep 'fig\|plot' |\
                    sed  's/file=//' | sed  's/,scale=.*}/}/' | \
                    sed  's/.*{\([^{]*\)}.*/\1.eps/;' )

$(dvi_target):: *.tex *.bib $(eps_targets)

pdf_targets = $(shell grep 'includegraphics' *.tex | grep -v "\%"  | grep 'fig\|plot' |\
                    sed  's/file=//' | sed  's/,scale=.*}/}/' | \
                    sed  's/.*{\([^{]*\)}.*/\1.pdf/;' )

$(pdf_target):: *.tex *.bib $(pdf_targets)

pdf: $(pdf_target)
ps: $(ps_target)
dvi: $(dvi_target)

help:
	@echo
	@echo "Automatic build target:"
	@echo "    $(pdf_target)"
	@echo "Other build target:"
	@echo "    $(ps_target)"
	@echo

clean = $(target) $(optional)

##############################################################################

git.tex: Makefile
	@changeset=`git rev-parse HEAD` && echo '\\renewcommand{\Revision}' "{$${changeset}}" > $@
	-@tipdate=`git log -1 --format="%cd"` && echo '\\renewcommand{\RevisionDate}' "{$${tipdate}}" >> $@

rev.tex: git.tex
	mv $< $@


timezone.tex: Makefile
	-@timezone=`date +%z` && echo '\renewcommand{\TimeZone}' "{$${timezone}}" > $@

##############################################################################
RERUN = '(There were undefined references|Rerun to get (cross-references|the bars) right)'
RERUNBIB = 'No file.*\.bbl|Citation.*undefined'
UNDEFINED = '((Reference|Citation).*undefined)|(Label.*multiply defined)'
DVIPDFM_SPECIAL = 'pdf:.*docinfo'


latex = latex -interaction=batchmode $(1)
pdflatex = pdflatex -interaction=batchmode $(1)
bibtex = bibtex $(1)

gs_screen = -dPDFSETTINGS=/screen
gs_printer = -dPDFSETTINGS=/printer
gs_ebook = -dPDFSETTINGS=/ebook
gs_prepress = -dPDFSETTINGS=/prepress

gs2pdf_options = -dCompatibilityLevel=1.4 $(gs_$(pdf_quality))
gs2pdf = gs -q -dSAFER -dNOPAUSE -dBATCH -sOutputFile=$(1) $(gs2pdf_options) -sDEVICE=pdfwrite -c .setpdfwrite -f $(2)

dvipdfm = dvipdfm -p $(paper_size) -o $(1) $(2)
dvips   = dvips -Pdownload35 -Pcmz -Pcmz -Pamz -t $(paper_size)  -G0 -o $(1) $(2)


%.pdf:: %.tex
	@echo "====> LaTeX first pass"
	$(call pdflatex,$<) || cat $*.log 
	@if egrep -q $(RERUNBIB) $*.log ; then echo "====> BibTex" && $(call bibtex,$*) && echo "====> LaTeX BibTeX pass" && $(call pdflatex, $<) ; fi
	@if egrep -q $(RERUN) $*.log ; then echo "====> LaTeX rerun" && $(call pdflatex,$<); fi; 
	@if egrep -q $(RERUN) $*.log ; then echo "====> LaTeX rerun" && $(call pdflatex,$<); fi;
	@echo "====> Undefined references and citations:"
	@egrep -i $(UNDEFINED) $*.log || echo "None."
	@echo "====> Dimensions:"
	@grep "dimension:" $*.log || echo "None."



##  Automatically choose the method to convert a DVI into a PDF, favoring
##  dvips since dvipdfm is fragile.
#%.pdf: %.dvi
#	@if egrep -q $(DVIPDFM_SPECIAL) $< ; \
#	 then echo "====> Using dvipdfm" && $(call dvipdfm,$@,$<) ; \
#	 else echo "====> Using dvips" && $(call dvips,$(<:.dvi=.ps),$<) && $(call gs2pdf,$@,$(<:.dvi=.ps)) ; \
#	 fi

##  Build a PDF from PS.  To enable, put this rule before other PDF rules.
#%.pdf: %.ps
#	@echo "====> Converting Postscript to PDF"
#	$(call gs2pdf,$@,$<)

##  Build a Postscript file from the DVI.
%.ps: %.dvi
	@echo "====> Generating Postscript"
	$(call dvips,$@,$<)

%.dvi: %.tex
	@echo "====> LaTeX first pass"
	$(call latex,$<) || cat $*.log 
	@if egrep -q $(RERUNBIB) $*.log ; then echo "====> BibTex" && $(call bibtex,$*) && echo "====> LaTeX BibTeX pass" && $(call latex, $<) ; fi
	@if egrep -q $(RERUN) $*.log ; then echo "====> LaTeX rerun" && $(call latex,$<); fi; 
	@if egrep -q $(RERUN) $*.log ; then echo "====> LaTeX rerun" && $(call latex,$<); fi
	@echo "====> Undefined references and citations:"
	@egrep -i $(UNDEFINED) $*.log || echo "None."
	@echo "====> Dimensions:"
	@grep "dimension:" $*.log || echo "None."

clean::
	rm -rf $(addsuffix .pdf, $(clean)) $(addsuffix .ps, $(clean))
	rm -rf $(addsuffix .dvi, $(clean)) $(addsuffix .toc, $(clean))
	rm -rf $(addsuffix .log, $(clean)) $(addsuffix .aux, $(clean))
	rm -rf $(addsuffix .bbl, $(clean)) $(addsuffix .blg, $(clean))
	rm -rf $(addsuffix .out, $(clean))
	rm -rf rev.tex timezone.tex
	rm -rf $(tmp_subdirs)

##############################################################################
#  Additional dependencies
##############################################################################
rev_style =  timezone.tex rev.tex

$(addsuffix .dvi, $(target) $(optional)):: $(rev_style)
$(addsuffix .pdf, $(target) $(optional)):: $(rev_style)

##############################################################################
#
#  tex4ht - Renders html from a LaTeX file, using CSS style sheets.
#
#  To build the html output for a given LaTeX file, such as paper.tex,
#  substitute -html for .tex, such as paper-html
# 
##############################################################################

tex4ht ?= ~joshua/tex4ht.dir
tex4ht_bin = $(tex4ht)/bin/unix
tex4ht_styles = $(tex4ht)/texmf/tex/generic/tex4ht

%-html: %.tex FORCE
	mkdir -p $@
	cd $@ && env PATH=$(PATH):$(tex4ht_bin) TEXINPUTS=:..:$(tex4ht_styles) htlatex $<
