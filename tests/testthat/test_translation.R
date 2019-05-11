context("Import and translate")

# Create test and reference table for testing. Breaking line length because
# these lines are not meant to be read by humans.
test.tbl1 <- as.data.frame(
  rbind(
    c(lab_from = "lab_srb", sample = "sample1", loc1_1 = "10", loc1_2 = "14", loc2_1 = "100", loc2_2 = "98"),
    c(lab_from = "lab_srb", sample = "sample2", loc1_1 = "12", loc1_2 = "8", loc2_1 = "102", loc2_2 = "104")
  ), stringsAsFactors = FALSE
)

test.tbl2 <- as.data.frame(
  rbind(
    c(lab_from = "lab_xyz", sample = "sample_x", loc1_1 = "12", loc1_2 = "6", loc2_1 = "100", loc2_2 = "100")
  )
)

test.tbl3 <- as.data.frame(rbind(
  c(lab_from = "lab_lab1", sample = "samplex", loc1_1 = "1", loc1_2 = "1", loc2_1 = NA, loc2_2 = NA)
))

test.tbl4 <- as.data.frame(rbind(
  c(lab_from = "lab_lab2", sample = "samplex", loc1_1 = "1", loc1_2 = "1")
))

test.tbl5 <- as.data.frame(rbind(
  c(lab_from = "lab_lab2", sample = "samplex", loc1_1 = "1", loc1_2 = "1", loc2_1 = NA, loc2_2 = NA)
))

ref.tbl <- as.data.frame(rbind(
  c(lab_from = "lab_srb", locus = "loc1", allele_from = NA, allele_ref = NA, delta = 4),
  c(lab_from = "lab_srb", locus = "loc2", allele_from = "98", allele_ref = "50", delta = NA),
  c(lab_from = "lab_srb", locus = "loc2", allele_from = "100", allele_ref = "52", delta = NA),
  c(lab_from = "lab_srb", locus = "loc2", allele_from = "102", allele_ref = "56", delta = NA),
  c(lab_from = "lab_srb", locus = "loc2", allele_from = "104", allele_ref = "60", delta = NA),
  c(lab_from = "lab_lab1", locus = "loc2", allele_from = "4", allele_ref = "6", delta = NA),
  c(lab_from = "lab_lab2", locus = "loc1", allele_from = "1", allele_ref = "2", delta = NA),
  c(lab_from = "lab_lab2", locus = "loc1", allele_from = "1", allele_ref = "4", delta = NA)
), stringsAsFactors = FALSE)


  # TODO: dodaj edge case:
  #  - narobe translation table, ko ima dve mapiranji
  #  - naj bo clash, da ima delta in še spec. mapiranje
test_that("Test normal behavior", {
  test1 <- translateGenotypes(input = test.tbl1, ref_tbl = ref.tbl)$translated
  t1s1 <- test1[test1$sample == "sample1", ]
  t1s2 <- test1[test1$sample == "sample2", ]

  expect_equal(t1s1$loc1_1, "14")  # If on OK, the other one is OK.
  expect_equal(t1s1$loc2_1, "52")
  expect_equal(t1s1$loc2_2, "50")
  expect_equal(t1s2$loc2_1, "56")
  expect_equal(t1s2$loc2_2, "60")
})

test_that("Test no data for lab in translation table.", {
  expect_error(translateGenotypes(input = test.tbl2, ref_tbl = ref.tbl))
})

test_that("Test no translation data for locus", {
  expect_error(translateGenotypes(input = test.tbl3, ref_tbl = ref.tbl))
})

test_that("Test incorrect translation table (one to two translation)", {
  expect_error(translateGenotypes(input = test.tbl4, ref_tbl = ref.tbl))
})

test_that("Test if output as long format is working", {
  test2 <- translateGenotypes(input = test.tbl1, ref_tbl = ref.tbl, long = TRUE)
  expect_equal(ncol(test2), 5)
  expect_equal(nrow(test2), 8)
  expect_identical(colnames(test2), c("lab_from", "sample", "locus", "allele", "lab_srb"))
})

test_that("Test writing of output file", {
  test3 <- translateGenotypes(input = test.tbl1, ref_tbl = ref.tbl,
                                        output = "test.txt")
  expect_true(file.exists("test.txt"))
  unlink("test.txt")

})