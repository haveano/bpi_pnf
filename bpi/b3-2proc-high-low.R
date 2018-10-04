args <- commandArgs(trailingOnly = TRUE)

library(rpnf)
library(readr)
options(max.print=999999)
akcje <- read_csv(args[1],
    col_names = FALSE, col_types = cols(X1 = col_date(format = "%Y-%m-%d"),
        X10 = col_skip(), X11 = col_skip(),
        X12 = col_skip(), X13 = col_skip(),
        X14 = col_skip(), X15 = col_skip(),
        X4 = col_skip(), X5 = col_skip(),
        X6 = col_double(), 
	X7 = col_double(),
        X8 = col_skip(), 
	X9 = col_skip()))

pnfakcje <- pnfprocessor(
high=akcje$X6,
low=akcje$X7,
date=akcje$X1,
boxsize=getLogBoxsize(2),
log=TRUE)

a <- pnfakcje[nrow(pnfakcje),"status.bs"]
cat(substring(a,1,1),"\n",sep="")

#cat(pnfakcje[nrow(pnfakcje),"status.bs"],"\n")

pnfplottxt(
 data=pnfakcje,
 reversal=3,
 boxsize=getLogBoxsize(2),
 log=TRUE)

pnfakcje

