args <- commandArgs(trailingOnly = TRUE)

library(rpnf)
library(readr)
options(max.print=999999)

akcje <- read_csv(args[1],
    col_names = FALSE, col_types = cols(X1 = col_date(format = "%Y-%m-%d")))

#Data,	Nazwa,	ISIN,	Waluta,	"Kurs otwarcia",	"Kurs max",	"Kurs min",	"Kurs zamknięcia",	Zmiana,	Wolumen,	"Liczba Transakcji",	Obrót,	"Liczba otwartych pozycji",	"Wartość otwartych pozycji",	"Cena nominalna"
#1	2	3	4	5			6		7		8			9	10		11			12	13				14				15

pnfakcje <- pnfprocessor(
 high=akcje$X2,
 date=akcje$X1,
 boxsize=2,
 log=FALSE,
 style="bp")

# status "XO"
c <- pnfakcje[nrow(pnfakcje),"status.xo"]
cat(substring(c,1,1),"\n",sep="")

# status "buy/sell"
a <- pnfakcje[nrow(pnfakcje),"status.bs"]
cat(substring(a,1,1),"\n",sep="")


pnfplottxt(
 data = pnfakcje,
 boxsize = 2,
 log = F)

pnfakcje

