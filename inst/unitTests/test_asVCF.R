library(VariantAnnotation)

.test_fixed <- function(fv, fg) {
  checkIdentical(as.character(fv$REF), as.character(fg$REF))
  checkIdentical(fv$ALT, fg$ALT)
  checkIdentical(fv$QUAL, fg$QUAL)
  ## VCF sets filter==NA to "."
  fg$FILTER[is.na(fg$FILTER)] <- "."
  checkIdentical(fv$FILTER, fg$FILTER)
}

.test_rowRanges <- function(rdv, rdg) {
  checkIdentical(seqnames(rdv), seqnames(rdg))
  checkIdentical(start(rdv), start(rdg))
  checkIdentical(width(rdv), width(rdg))
  checkIdentical(strand(rdv), strand(rdg))
  ## rowRanges for VCF not working with fixed=TRUE for some reason
  ## fcols <- c("REF", "ALT", "QUAL", "FILTER")
  ## .test_fixed(mcols(rdv)[,fcols], mcols(rdg)[,fcols])
}

.test_colData <- function(cdv, cdg) {
  cdg <- cdg[,1,drop=FALSE]
  checkIdentical(cdv, cdg)
}

.test_header <- function(hdv, hdg) {
  checkIdentical(samples(hdv), samples(hdg))
  ## The meta(VCFHeader) getter now returns a DataFrameList, not DataFrame.
  ## tags with non-alphanumeric characters get ignored by scanBcfHeader
  meta.hdg <- meta(hdg)[grep("^[[:alnum:]]+$", row.names(meta(hdg))),,drop=FALSE]
  checkIdentical(meta(hdv)[rownames(meta.hdg),,drop=FALSE], meta.hdg)
  ## VariantAnnotation now makes up a value for FILTER in the header even
  ## if it was not present in original VCF header
  for (i in intersect(names(fixed(hdv)), names(fixed(hdg)))) {
      checkIdentical(fixed(hdv)[[i]], fixed(hdg)[[i]])
  }
  checkIdentical(info(hdv), info(hdg))
  checkIdentical(geno(hdv), geno(hdg))
}

.test_info <- function(iv, ig) {
  checkIdentical(sort(names(iv)), sort(names(ig)))
  for (n in names(iv)) {
    if (is(iv[[n]], "IntegerList")) {
      iv[[n]] <- IntegerList(lapply(iv[[n]], function(x) {if (length(x) > 0) x else NA}))
    } else if (is(iv[[n]], "CharacterList")) {
      iv[[n]] <- CharacterList(lapply(iv[[n]], function(x) {if (length(x) > 0) x else NA}))
    }
    checkEquals(iv[[n]], ig[[n]], paste(" ", n, "not identical"),
                tolerance=2*(.Machine$double.eps^0.5), checkNames=FALSE)
  }
}

.test_geno <- function(gv, gg) {
  for (n in names(gv)) {
    ## variant names are different
    checkEquals(nrow(gv[[n]]), nrow(gg[[n]]),
                paste(" ", n, "have different numbers of rows"))
    dimnames(gv[[n]])[1] <- dimnames(gg[[n]])[1]
    checkEquals(gv[[n]], gg[[n]], paste(" ", n, "not identical"),
                tolerance=10*(.Machine$double.eps^0.5), checkNames=FALSE)
  }
}

.test_asVCF <- function(vcffile, gdsfile) {
  vcf <- readVcf(vcffile, genome="hg19")
  showfile.gds(closeall=TRUE, verbose=FALSE)
  gdsobj <- seqOpen(gdsfile)

  ## .test_rowRanges(rowRanges(vcf), rowRanges(gdsobj))
  ## .test_colData(colData(vcf), colData(gdsobj))
  ## .test_header(header(vcf), header(gdsobj))
  ## .test_info(info(vcf), info(gdsobj))
  ## .test_geno(geno(vcf), geno(gdsobj))

  vcfg <- seqAsVCF(gdsobj)
  .test_rowRanges(rowRanges(vcf), rowRanges(vcfg))
  .test_colData(colData(vcf), colData(vcfg))
  #.test_header(header(vcf), header(vcfg))
  .test_fixed(fixed(vcf), fixed(vcfg))
  .test_info(info(vcf), info(vcfg))
  .test_geno(geno(vcf), geno(vcfg))

  seqClose(gdsobj)
}

## takes too long - use for development only
## test_asVCF <- function() {
##   vcffile <- seqExampleFileName("vcf")
##   gdsfile <- seqExampleFileName("gds")
##   .test_asVCF(vcffile, gdsfile)
## }

test_asVCF_filterInHead <- function() {
  vcffile <- system.file("extdata", "ex2.vcf", package="VariantAnnotation")
  gdsfile <- tempfile()
  seqVCF2GDS(vcffile, gdsfile, storage.option="ZIP_RA", verbose=FALSE)
  .test_asVCF(vcffile, gdsfile)
  unlink(gdsfile)
}

test_asVCF_altInHead <- function() {
  vcffile <- system.file("extdata", "gl_chr1.vcf", package="VariantAnnotation")
  gdsfile <- tempfile()
  seqVCF2GDS(vcffile, gdsfile, storage.option="ZIP_RA", verbose=FALSE)
  .test_asVCF(vcffile, gdsfile)
  unlink(gdsfile)
}

## takes too long - use for development only
## test_asVCF_c22 <- function() {
##   vcffile <- system.file("extdata", "chr22.vcf.gz", package="VariantAnnotation")
##   gdsfile <- tempfile()
##   seqVCF2GDS(vcffile, gdsfile, storage.option="ZIP_RA", verbose=FALSE)
##   .test_asVCF(vcffile, gdsfile)
##   unlink(gdsfile)
## }

test_info_geno <- function() {
  showfile.gds(closeall=TRUE, verbose=FALSE)
  vcffile <- system.file("extdata", "gl_chr1.vcf", package="VariantAnnotation")
  gdsfile <- tempfile()
  seqVCF2GDS(vcffile, gdsfile, storage.option="ZIP_RA", verbose=FALSE)

  info <- c("AN", "VT")
  geno <- "DS"

  vcf <- readVcf(vcffile, genome="hg19",
                 param=ScanVcfParam(info=info, geno=geno))
  gdsobj <- seqOpen(gdsfile)

  vcfg <- seqAsVCF(gdsobj, info=info, geno=geno)
  .test_header(header(vcf), header(vcfg))
  .test_info(info(vcf), info(vcfg))
  .test_geno(geno(vcf), geno(vcfg))

  seqClose(gdsobj)
  unlink(gdsfile)
}

test_info_geno_na <- function() {
  showfile.gds(closeall=TRUE, verbose=FALSE)
  vcffile <- seqExampleFileName("vcf")
  gdsfile <- seqExampleFileName("gds")
  info <- NA
  geno <- NA
  vcf <- readVcf(vcffile, genome="hg19",
                 param=ScanVcfParam(info=info, geno=geno))
  gdsobj <- seqOpen(gdsfile)

  vcfg <- seqAsVCF(gdsobj, info=info, geno=geno)
  checkEquals(0, length(info(vcfg)))
  checkEquals(0, length(geno(vcfg)))
  .test_header(header(vcf), header(vcfg))
  .test_info(info(vcf), info(vcfg))
  .test_geno(geno(vcf), geno(vcfg))

  seqClose(gdsobj)
}

test_filters <- function() {
  showfile.gds(closeall=TRUE, verbose=FALSE)
  vcffile <- system.file("extdata", "chr22.vcf.gz", package="VariantAnnotation")
  gdsfile <- tempfile()
  seqVCF2GDS(vcffile, gdsfile, storage.option="ZIP_RA", verbose=FALSE)

  gdsobj <- seqOpen(gdsfile)
  samples <- seqGetData(gdsobj, "sample.id")[1:5]
  variants <- seqGetData(gdsobj, "variant.id")[1:10]
  seqSetFilter(gdsobj, sample.id=samples, variant.id=variants, verbose=FALSE)

  info <- c("AA", "AN")
  geno <- "GT"
  vcf <- readVcf(vcffile, genome="hg19",
                 param=ScanVcfParam(info=info, geno=geno,
                   samples=samples, which=granges(gdsobj)))
  vcfg <- seqAsVCF(gdsobj, info=info, geno=geno)

  .test_rowRanges(rowRanges(vcf), rowRanges(vcfg))
  .test_colData(colData(vcf), colData(vcfg))
  .test_header(header(vcf), header(vcfg))
  .test_fixed(fixed(vcf), fixed(vcfg))
  .test_info(info(vcf), info(vcfg))
  .test_geno(geno(vcf), geno(vcfg))

  seqClose(gdsobj)
  unlink(gdsfile)
}

