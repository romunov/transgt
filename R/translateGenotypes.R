#' Translate genotypes
#'
#' @param input A data.frame or a (relative) path to a file of alleles to be
#' translated. Fixed columns are
#' name of the laboratory, which should match that from \code{ref_tbl}
#' and sample name (this is for your viewing pleasure only). The varying
#' columns represent genotype. Make sure columns match names from the
#' \code{ref_tbl}.
#' @param ref_tbl A data.frame which holds the translation table.
#' Structure is fixed and the columns are \code{lab_from}, \code{locus},
#' \code{allele_from}, \code{allele_ref} and \code{delta}. First two columns
#' are self explanatory. Columns that start with \code{allele_} have actual
#' allele values in laboratory of question and the reference (right now the
#' reference is laboratory from Slovenia). The last column is the amount
#' an allele should be shifted relative to the reference.
#' @param long Logical. If \code{TRUE}, the result will be returned as a long
#' table instead of wide. If \code{FALSE} (default), wide table will be
#' provided.
#' @param output Character. Relative or absolute path to the file the data
#' should be written to. The result will have tab separated columns and no row
#' names. Default is \code{NA}.
#' @param ... Parameters passed to \link[readxl]{read_excel}.
#'
#' @details The shift (\code{delta}) can be possibly calculated for some loci.
#' If alleles for a certain locus are missing and there's only a delta
#' parameter, this means that all so far examined alleles behave properly and
#' can be offset safely. For those that also have mapping table in
#' \code{allele_from} and \code{allele_ref}, the mapping is done 1:1.
#'
#' @importFrom readxl read_excel
#' @importFrom tidyr gather spread
#' @importFrom utils write.table

translateGenotypes <- function(input, ref_tbl, long = FALSE, output = NA, ...) {
  # If input is not an already formatted table, import it assuming it's an
  # xlsx file. User needs to pass in the sheet name using the ... argument.
  if (any(class(input) %in% "character")) {
    stopifnot(file.exists(input))
    xy <- read_excel(path = input, ...)
  }

  # If input is data.frame, make sure it has all the appropriate columns.
  if (any(class(input) %in% "data.frame")) {
    stopifnot(all(c("lab_from", "sample") %in% names(input)))
  }

  # Output should have all loci from the reference table. Find loci that are
  # in reference, but not xy (uncommon.loci), and append those as NA to xy
  # before translation starts.
  ref <- ref_tbl[ref_tbl$lab_from == unique(input$lab_from), ]
  input.loci <- colnames(input)
  input.loci <- colnames(input)[!(input.loci %in% c("lab_from", "sample"))]
  input.loci <- unique(gsub("_[1|2]", "", input.loci))

  ref.loci <- unique(ref$locus)
  uncommon.loci <- ref.loci[!(ref.loci %in% input.loci)]
  uncommon.loci <- paste(rep(uncommon.loci, each = 2),
                      c("1", "2"),
                      sep = "_")

  for (i in uncommon.loci) {
    input[, i] <- NA
  }

  # Make sure column order matches the order of loci in reference (ref).
  ref.order <- paste(rep(unique(ref$locus), each = 2),
                     c("1", "2"),
                     sep = "_")
  ref.order <- c("lab_from", "sample", ref.order)

  if (!all(ref.order %in% colnames(input))) {
    stop("Reference and input columns do not match. Investigate.")
  }

  input <- input[, ref.order]

  # The algorithm works on a long format, so we reflow accordingly.
  xy <- suppressWarnings(
    gather(input, key = locus, value = allele, -lab_from, -sample)
  )

  lab <- as.character(unique(xy$lab_from))
  xy[, lab] <- NA

  # Algorithm for translating values:
  for (i in 1:nrow(xy)) {
    # For each line (lab, locus, allele) of data, find corresponding allele
    # in translation table.
    roll.i <- xy[i, ]

    # Extract pretty locus name (loc2_1 is now loc2).
    roll.locus <- strsplit(roll.i$locus, "_")[[1]][[1]]
    roll.lab <- roll.i$lab_from
    ref <- ref_tbl[ref_tbl$locus == roll.locus & ref_tbl$lab_from == roll.lab, ]

    if (nrow(ref) == 0) {
      stop(sprintf("No entries in translation table for this combination of locus-lab (%s-%s)",
                   roll.locus, roll.lab))
    }

    # If locus is well behaved, it has one delta (offset) value used for
    # translating. If that's the case, ref will only have one row.
    if (!is.na(ref$delta) && nrow(ref) == 1) {
      # If offset (delta) is provided, calculate new allele based on offset.
      xy[i, lab] <- as.character(as.numeric(roll.i$allele) + as.numeric(ref$delta))
    } else {
      # If direct translation value available, use that instead. But first,
      # tease it out using the correct allele name.
      ref <- ref[ref$allele_from == roll.i$allele, ]

      # The reference table may have a locus entry, but no data for it. In this case,
      # we just leave entry as NA.
      if (all(is.na(ref[, c("allele_from", "allele_ref", "delta")]))) {
        xy[i, lab] <- NA
        next
      }

      if (nrow(ref) >= 2) {
        stop(sprintf("Reference from lab %s (locus %s) have more than one translation.
    Check translation table.", roll.lab, roll.locus))
      }

      if (nrow(ref) == 0) {
        warning(sprintf("%s has no translation value (locus: %s, lab: %s).",
                        roll.i$allele, roll.locus, roll.lab))
        next
      }

      if (nrow(ref) == 1) {
        xy[i, lab] <- ref$allele_ref
      }
    }
  }

  # Keep in long format if so requested.
  if (long == TRUE) {
    return(xy)
  }

  # Remove the original allele value in order to properly reflow data into
  # wide format and then reflow into wide format.
  xy$allele <- NULL
  xy <- spread(xy, key = locus, value = lab)

  # Export if file (path)name provided.
  if (!is.na(output)) {
    write.table(xy, file = output, quote = FALSE, row.names = FALSE,
                col.names = TRUE, sep = "\t")

    message(sprintf("Output written to file %s", output))
  }

  return(list(translated = xy,
              original = input)
  )
}