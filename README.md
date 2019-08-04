# Package transgt
Traditionally, genotying of individuals has been done using capillary sequencers. Speed of traveling of repeats (e.g. ATATAT) through the capillary is governed by its length and is specific for each machine. To compare samples between machines (or labs), one needs to analyze reference samples. These reference samples can serve to construct a translation table of alleles.

If you're lucky, the shift in lengths of alleles will be uniform throughout the allele length range, so substracting or adding to the length (`delta`) will yield common allele length. If this is not possible, because short or long allele reads are acting funky, you are best to provide 1:1 mapping alleles from your and from reference laboratory.

# Assumptions
Following assumptions are made by the package code.
* Allele lengths are characters that can be coerced to integers.
* Locus names are constructed as `<string>_1` `<string>_2` for diploid organisms where `<string>` represents an alphanumeric string where `_` is not allowed.
* You know translational `delta` or direct mapping of alleles from a laboratory relative to the reference laboratory allele. If not, assume NA as this is not directly translatable.
* Data from only one laboratory is being translated at a time.

# Overview
Inputs for this package are:

* input genotypes
* translation table

Inputs should be provided to the workhorse function `translateGenotypes` in a data.frame or as an Excel (.xlsx) file. Below is an example of input genotypes for samples `sample1` and `sample2` from lab `lab_srb`. First two column names are fixed, and that's `lab_from` which denotes the laboratory name that should match the name from the translation table, and `sample`. Locus names are `loc1` and `loc_2` and appended `_1` and `_2` denote a diploid genotype (order does not influence the translation).

```
# input
  lab_from  sample loc1_1 loc1_2 loc2_1 loc2_2
1  lab_srb sample1     10     14    100     98
2  lab_srb sample2     12      8    102    104
```

If you're providing the input via an Excel file, make sure the structure is reflected as in the above table. Please note that R is case sensitive.

Translation table would look as depicted below. Locus `loc_1` is behaving well and we can simply add or substract allele lengths relative to the reference laboratory. The change is denoted in column `delta`. Locus `loc_2` is mapped 1:1. It has 4 alleles. Allele `"98"` from laboratory `lab_srb` has a length of `"50"` in the reference laboratory.

```
# ref_tbl
  lab_from locus allele_from allele_ref delta
1  lab_srb  loc1        <NA>       <NA>     4
2  lab_srb  loc2          98         50  <NA>
3  lab_srb  loc2         100         52  <NA>
4  lab_srb  loc2         102         56  <NA>
5  lab_srb  loc2         104         60  <NA>
```

# Usage

```{r}
library(transgt)

> ref.tbl <- structure(list(lab_from = c("lab_srb", "lab_srb", "lab_srb", 
"lab_srb", "lab_srb"), locus = c("loc1", "loc2", "loc2", "loc2", 
"loc2"), allele_from = c(NA, "98", "100", "102", "104"), allele_ref = c(NA, 
"50", "52", "56", "60"), delta = c("4", NA, NA, NA, NA)), row.names = c(NA, 
5L), class = "data.frame")

> test.data <- structure(list(lab_from = c("lab_srb", "lab_srb"), sample = c("sample1", 
"sample2"), loc1_1 = c("10", "12"), loc1_2 = c("14", "8"), loc2_1 = c("100", 
"102"), loc2_2 = c("98", "104")), class = "data.frame", row.names = c(NA, 
-2L))

> translateGenotypes(input = test.data, ref_tbl = ref.tbl)
$translated
  lab_from  sample loc1_1 loc1_2 loc2_1 loc2_2
1  lab_srb sample1     14     18     52     50
2  lab_srb sample2     16     12     56     60

$original
  lab_from  sample loc1_1 loc1_2 loc2_1 loc2_2
1  lab_srb sample1     10     14    100     98
2  lab_srb sample2     12      8    102    104
```

Output comes as a list of length 2. Original input data is in `$original` and the translated table is in `$translated`.

If you would prefer to have output as a long table, use

```{r}
> translateGenotypes(input = test.tbl1, ref_tbl = ref.tbl, long = TRUE)

  lab_from  sample  locus allele lab_srb
1  lab_srb sample1 loc1_1     10      14
2  lab_srb sample2 loc1_1     12      16
3  lab_srb sample1 loc1_2     14      18
4  lab_srb sample2 loc1_2      8      12
5  lab_srb sample1 loc2_1    100      52
6  lab_srb sample2 loc2_1    102      56
7  lab_srb sample1 loc2_2     98      50
8  lab_srb sample2 loc2_2    104      60
```

You can write the translated `data.frame` into a text file using `write.table` (tab delimited) using the below command. You will be notified that the file has been written. Provide a relative or absolute path to the `output` argument.

```{r}
> translateGenotypes(input = test.tbl1, ref_tbl = ref.tbl, output = "test.txt")
Output written to file test.txt
```
