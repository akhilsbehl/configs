.libPaths("~/rstat/lib/")

if(interactive()){

  library(colorout)
  library(setwidth)
  library(vimcom)

  require(utils)
  packagelist <- installed.packages()[ , "Package"]
  save(packagelist, file="~/rstat/packagelist.RData")
  rm(packagelist)

  #if(nchar(Sys.getenv("DISPLAY")) > 1){
    #options(editor = 'gvim -f -c "set ft=r"')
    #options(pager = "gvim -c 'set ft=rdoc' -")
  #} else {
    #options(editor = 'vim -c "set ft=r"')
    #options(pager = "vim -c 'set ft=rdoc' -")
  #}

}

._get_all_pkgs_ <- function () {
  installed <- packagelist %in% installed.packages()[ , "Package"]
  if (length(packagelist[!installed]) >= 1){
    install.packages(packagelist[!installed])
  }
}
