outdir  = build
options = -file-line-error -halt-on-error -output-directory $(outdir)

sources = report.tex
pdfs    = $(patsubst %.tex,$(outdir)/%.pdf, $(sources))

all: $(pdfs)

$(outdir)/%.pdf: %.tex
	pdflatex $(options) $<

clean:
	$(RM) $(outdir)/*

.PHONY: clean all
