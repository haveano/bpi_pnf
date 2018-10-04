args <- commandArgs(trailingOnly = TRUE)

library(rpnf)
library(readr)
options(max.print=999999)

akcje <- read_csv(args[1],
#    col_names = FALSE, col_types = cols(X1 = col_date(format = "%Y-%m-%d")))

    col_names = FALSE, col_types = cols(X1 = col_date(format = "%Y-%m-%d"),
        X10 = col_skip(), X11 = col_skip(),
        X12 = col_skip(), X13 = col_skip(),
        X14 = col_skip(), X15 = col_skip(),
        X2 = col_skip(), X3 = col_skip(),
        X4 = col_skip(), X5 = col_skip(),
        X6 = col_skip(), X7 = col_skip(),
        X8 = col_double(),
        X9 = col_skip()))


#Data,  Nazwa,  ISIN,   Waluta, "Kurs otwarcia",        "Kurs max",     "Kurs min",     "Kurs zamknięcia",      Zmiana, Wolumen,        "Liczba Transakcji",    Obrót,  "Liczba otwartych pozycji",     "Wartość otwartych pozycji",    "Cena nominalna"
#1      2       3       4       5                       6               7               8                       9       10              11                      12      13                              14                              15

pnfakcje <- pnfprocessor(
high=akcje$X8,
low=akcje$X8,
date=akcje$X1,
boxsize=1L,
log=FALSE)

a <- pnfakcje[nrow(pnfakcje),"status.bs"]
cat(substring(a,1,1),"\n",sep="")

#pnfakcje

pnfplottxt(
  data = pnfakcje,
  reversal = 3,
  boxsize = 1L,
  log = F)

pnfakcje

