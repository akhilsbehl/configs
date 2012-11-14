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
#options(repos=c("http://ftp.iitm.ac.in/cran/", "http://cran.csdb.cn"))
