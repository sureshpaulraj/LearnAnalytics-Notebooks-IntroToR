## This script configures and attempts to install or download the relevant dependencies for the jupyter notebooks contained within the repository. 
## ASSUMES that this is run from the repository root directory (which can be arbitrarily named)
## The main sections are:
## options
## packages
## datasets that need to be retrieved
## any preprocessing steps that need to be taken

## load some helper functions
## Assumes that it's being run from the repo directory!
cat('*** Configuring your environment - this may take a moment (especially the first time this is run), so please be patient...\n')
## Set Options!
if (!exists('myconfig')) {
    myconfig <- new.env()
}
sys.source("Resources/00_helper_functions.R", envir = myconfig)
while ('myconfig' %in% search())
    detach('myconfig') ## make sure any pre-existing ones are not on!

attach(myconfig) ## attach for helper functions
myconfig$verbose = TRUE
myconfig$date_to_checkpoint_to <- "2015-11-30" ## approximately the last date associated with the current version of R Open used in MRS/MRC
myconfig$checkpoint_dir <- file.path(get_repo_dir(), '.Rcheckpoint')

## check this specifically!
if (!exists('myconfig$orig_libPaths')) {
    myconfig$orig_libPaths <- .libPaths()
} else {
    ## reset this so it can find the original Revo Path
    .libPaths(myconfig$orig_libPaths)
}


options(
    stringsAsFactors = FALSE,
    repos = paste0("https://mran.revolutionanalytics.com/snapshot/", myconfig$date_to_checkpoint_to) ## only set here in case checkpoint is not installed!
)

##############################
## PACKAGES
##############################
cat('*** Checking for packages...\n')

# make sure checkpoint is installed! Can't use checkpoint *for* checkpoint
if (!require(checkpoint, quietly = !myconfig$verbose)) {
    # make sure that we're using a relatively recent version of CRAN:
    tryCatch(
        install.packages("checkpoint", lib = checkpoint_dir),
        error = function(e) stop("installation of checkpoint failed!")
    )
    library(checkpoint, lib.loc = myconfig$checkpoint_dir)
}

## convert .ipynb files to r scripts so checkpoint can do the necessary work...
## Reason this is necessary is that checkpoint:::scanForPackages() won't check ipynb files.
if (myconfig$verbose) { cat('\t*** Converting notebooks...\n') }
myconfig$repo_dir <- get_repo_dir()
myconfig$nb_files <- list.files(pattern = ".ipynb$", path = myconfig$repo_dir)
lapply(myconfig$nb_files, myconfig$nbconvert_for_scan, verbose = myconfig$verbose)

## get revo packages for use later!
myconfig$revo_pkg_info <- installed.packages()[grep('^[Rr]evo', rownames(installed.packages())),]

# this is used to save when creating the document
# saveRDS(revo_pkg_info[, 'Version'], file = 'Resources/microsoft_r_client_package_versions.rds')
## copy relevant packages over to a special directory for loading later.
## load the revo pkg info that we're confirmed on.
## checkpointed_revo_pkg_versions <- readRDS('Resources/microsoft_r_client_package_versions.rds')
## only get the packages that are in the checkpointed versions:
#installed_packages_in_chkpt_logical <- rownames(installed.packages()) %in% names(checkpointed_revo_pkg_versions)
#if (sum(installed_packages_in_chkpt_logical) < length(checkpointed_revo_pkg_versions)) {
#    missing_pkgs <- names(checkpointed_revo_pkg_versions)[names(checkpointed_revo_pkg_versions) %in% rownames(installed.packages())]
#    msg <- cat('We are missing some packages:\n', paste(missing_pkgs, collapse = '\n'))
#    stop(msg)
#}
#names_of_installed_and_checkpointed <- rownames(installed.packages())[installed_packages_in_chkpt_logical]
## now check versions:
#same_version <- installed.packages()[names_of_installed_and_checkpointed,'Version'] == checkpointed_revo_pkg_versions[names_of_installed_and_checkpointed]
# if (!all(same_version)) {
#    stop('Packages installed, but different versions...')
#}
#key_pkg_info <- installed.packages()[names_of_installed_and_checkpointed[same_version],]
## let `checkpoint()` take care of most things!
# force the creation of the .checkpoint dir so it doesn't have to be interactive:
myconfig$actual_checkpoint_dir <- file.path(myconfig$checkpoint_dir, '.checkpoint')
if (!dir.exists(myconfig$actual_checkpoint_dir)) dir.create(myconfig$actual_checkpoint_dir, recursive = TRUE)
checkpoint(myconfig$date_to_checkpoint_to, checkpointLocation = myconfig$checkpoint_dir, verbose = myconfig$verbose)
# add revo sandbox to the end *after* checkpoint has completed!
## do it this way instead of .libPaths() because .libPaths() adds .Library.site too (similar approach used in checkpoint:::setLibPaths()
if (length(myconfig$revo_pkg_info) > 0) {
    if (myconfig$verbose) { cat('\t*** Sandboxing Revo packages...\n') }
    myconfig$revo_sandbox_dir <- file.path(myconfig$checkpoint_dir, "revo_sandbox")
    myconfig$sandbox_pkg_info <- sandbox_packages(myconfig$revo_pkg_info, myconfig$revo_sandbox_dir, overwrite = FALSE, recursive = TRUE, verbose = myconfig$verbose)
    assign(".lib.loc", c(.libPaths(), myconfig$revo_sandbox_dir), envir = environment(.libPaths))
}

## add back the revo_packages as long as they are the right version
## tag the following to make sure that checkpoint captures them
myconfig$lme4present <- require(lme4) # not listed as car requirement but it is!
myconfig$Matrixpresent <- require(Matrix) # not listed as caret requirement, but it is!
myconfig$e1071present <- require(e1071) # not listed as caret requirement, but it is!

## TODO: add code for packages NOT on MRAN when it becomes necessary! 
## leverage results returned from checkpoint()


## add a Revo piece
## add revo dirs
##############################
## DATA
##############################
cat('*** Checking for datasets...\n')

## this section is specifically for setting up relevant datasets!
myconfig$resources_dir <- file.path(myconfig$get_repo_dir(), "Resources")
sys.source(file.path(myconfig$resources_dir, "01_00_data.R"), envir = myconfig)
myconfig$create_data(get_repo_dir())

##############################
## preprocessing!
##############################
sys.source(file.path(myconfig$resources_dir, "02_00_preprocess_function.R"), envir = myconfig)
# preprocess()

##############################
## clean up objects!
##############################

cat("\n*** Done with configuration! ***\n")
detach('myconfig') ## detach, but don't remove...
