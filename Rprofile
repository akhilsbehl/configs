# Set your lib path.
.libPaths("~/rstat/lib/")

# Load libraries for vim-r-plugin.
if(interactive()){
  library(colorout)
  library(setwidth)
  library(vimcom)
}

# Workaround for the Arch Cairo bug.
grDevices::X11.options(type="nbcairo")

options(prompt="R> ")
options("pdfviewer"="mupdf")
options(showWarnCalls=TRUE, showErrorCalls=TRUE)
options(max.print=1000)
options(repos=c("http://cran.cnr.berkeley.edu/", "http://stat.ethz.ch/CRAN/"))
options(pager="/usr/bin/less")

.ls.objects <- function (pos = 1, pattern, order.by,
                        decreasing=FALSE, head=FALSE, n=5) {
    napply <- function(names, fn) sapply(names, function(x)
                                         fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)
    obj.class <- napply(names, function(x) as.character(class(x))[1])
    obj.mode <- napply(names, mode)
    obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.size <- napply(names, object.size)
    obj.dim <- t(napply(names, function(x)
                        as.numeric(dim(x))[1:2]))
    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
    obj.dim[vec, 1] <- napply(names, length)[vec]
    out <- data.frame(obj.type, obj.size, obj.dim)
    names(out) <- c("Type", "Size", "Rows", "Columns")
    if (!missing(order.by))
        out <- out[order(out[[order.by]], decreasing=decreasing), ]
    if (head)
        out <- head(out, n)
    out
}

.lsos <- function(..., n=10) {
    tt <- .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
    tt[["Size"]] <- round(tt[["Size"]] / 1e6, digits=2)
    tt
}

clear <- function () system('clear')
