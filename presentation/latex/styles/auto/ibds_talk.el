(TeX-add-style-hook "ibds_talk"
 (lambda ()
    (TeX-add-symbols
     "thepage")
    (TeX-run-style-hooks
     "pifont"
     "ibds_beamer_bib"
     "babel"
     "ngerman"
     "beamerbaseoverride"
     "beamer10"
     "beamer")))

