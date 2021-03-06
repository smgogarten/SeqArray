\name{seqStorageOption}
\alias{seqStorageOption}
\title{Storage and Compression Options}
\description{
    Storage and compression options for GDS import and merging.
}
\usage{
seqStorageOption(compression=c("ZIP_RA", "ZIP_RA.fast", "ZIP_RA.max",
    "LZ4_RA", "LZ4_RA.fast", "LZ4_RA.max", "LZMA_RA", "LZMA_RA.fast",
    "LZMA_RA.max", "Ultra", "UltraMax", "none"), mode=NULL, float.mode="float32",
    geno.compress=NULL, info.compress=NULL, format.compress=NULL,
    index.compress=NULL, ...)
}
\arguments{
    \item{compression}{the default compression level ("ZIP_RA"), see
        \link{add.gdsn} for the description of compression methods}
    \item{mode}{a character vector, specifying storage type for corresponding
        variable, e.g., c(`annotation/info/HM`="int16",
        `annotation/format/PL`="int")}
    \item{float.mode}{specify the storage mode for read numbers, e.g.,
        "float32", "float64", "packedreal16"; the additional parameters can
        follow by colon, like "packedreal16:scale=0.0001"}
    \item{geno.compress}{NULL for the default value, or the compression method
        for genotypic data}
    \item{info.compress}{NULL for the default value, or the compression method
        for data sets stored in the INFO field (i.e., "annotation/info")}
    \item{format.compress}{NULL for the default value, or the compression method
        for data sets stored in the FORMAT field (i.e., "annotation/format")}
    \item{index.compress}{NULL for the default value, or the compression method
        for data index variables (e.g., "annotation/info/@HM")}
    \item{...}{other specified storage compression for corresponding variable,
        e.g., `annotation/info/HM`="ZIP_MAX"}
}
\details{
    The compression modes \code{"Ultra"} and \code{"UltraMax"} attempt to
maximize the compression ratio using gigabyte-sized or even terabyte-sized
virtual memory, according to \code{"LZMA_RA.ultra"} and
\code{"LZMA_RA.ultra_max"} in \code{\link{compression.gdsn}}. These features
require gdsfmt (>=v1.16.0). \code{"Ultra"} and \code{"UltraMax"} may not
increase the compression ratio much compared with \code{"LZMA_RA.max"}, and
these options are designed for the users who want to exhaust the computational
resources.
}
\value{
    Return a list with a class name "SeqGDSStorageClass", contains the
compression algorithm for each data type.
}

\author{Xiuwen Zheng}
\seealso{
    \code{\link{seqVCF2GDS}}, \code{\link{seqMerge}}
}

\examples{
# the file of VCF
(vcf.fn <- seqExampleFileName("vcf"))

# convert
seqVCF2GDS(vcf.fn, "tmp1.gds", storage.option=seqStorageOption())
(f1 <- seqOpen("tmp1.gds"))

# convert (maximize the compression ratio)
seqVCF2GDS(vcf.fn, "tmp2.gds", storage.option=seqStorageOption("ZIP_RA.max"))
(f2 <- seqOpen("tmp2.gds"))

# does not compress the genotypic data
seqVCF2GDS(vcf.fn, "tmp3.gds", storage.option=
    seqStorageOption("ZIP_RA", geno.compress=""))
(f3 <- seqOpen("tmp3.gds"))

# compress with LZ4
seqVCF2GDS(vcf.fn, "tmp4.gds", storage.option=seqStorageOption("LZ4_RA"))
(f4 <- seqOpen("tmp4.gds"))


# close and remove the files
seqClose(f1)
seqClose(f2)
seqClose(f3)
seqClose(f4)

unlink(c("tmp1.gds", "tmp2.gds", "tmp3.gds", "tmp4.gds"))
}

\keyword{gds}
\keyword{sequencing}
\keyword{genetics}
