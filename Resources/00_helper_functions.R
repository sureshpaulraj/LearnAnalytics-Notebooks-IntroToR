#' helper functions
# TODO: document with Roxygen

get_repo_dir <- function() {
    #' 
    ## script should either be run with the ipynb dir OR in the resources dir as wd.
        ## check for a .ipynb
    cur_nbs <- list.files(pattern = ".ipynb$")
    if (length(cur_nbs) > 0) {
        ## this is the dir!
        return(getwd())
    } else {
        ## if no notebooks found, then check to see if it is in the "Resources" dir,
        if (basename(getwd()) == "Resources") {
            repo_dir <- dirname(getwd())
            cur_nbs <- list.files(pattern = ".ipynb$", path = repo_dir)
            if (length(cur_nbs) > 0) {
                ## this is it!
                return(repo_dir)
            }
        }
    }
    ## if it gets to here - it fails!
    msg <-
            cat("Sourced from",
                getwd(),
                ".\n No notebooks found, and I cannot figure out the locaiton of the notebooks!")
    stop(msg)

}

nbconvert_for_scan <- function(nb, repo_dir = dirname(nb), out_dir = file.path(repo_dir, "Resources", "nbc_Rscripts"), check_timestamp = TRUE,verbose = FALSE) {
    if (!file.exists(out_dir)) dir.create(out_dir)
    out_file <- file.path(out_dir, sub(".ipynb$", ".r", basename(nb)))
    if (!file.exists(out_file) || !check_timestamp || (check_timestamp && file.exists(out_file) && file.mtime(out_file) <= file.mtime(nb))) {
        ## needs to know where jupyter is!!!
        nbc_cmd <- paste("jupyter nbconvert --to script", nb)
        ## run it!
        system(nbc_cmd, show.output.on.console = verbose)
        ## clean up and move to appropriate directory:
        file.rename(
            from = sub(".ipynb$", ".r", nb),
            to = out_file
        )
    }
    return(out_file)
}

# This actually creates symlinks in the first entry in .libPaths() if it's not already there...
# Create a set of symlinks in a specific directory, so we can add it to .libPaths()
sandbox_packages <- function(pkg_info, to_stem, versions = NULL, copy_missing = FALSE, verbose = FALSE, ...) {
    #' @ pkg_info - the subset of rows from installed.packages() that contains that packages you want to link to
    #' @ to_stem - target directory that would be added with .libPaths(), the parent dir of where all packages will be installed
    # print(pkg_info)
    if (is.matrix(pkg_info)) {
        original_file_paths <- file.path(pkg_info[, 'LibPath'], pkg_info[, 'Package'])
    } else {
        original_file_paths <- file.path(pkg_info['LibPath'], pkg_info['Package'])
    }
    if (!file.exists(to_stem)) dir.create(to_stem, recursive = TRUE)
    all_target_files <- mapply(function(from, to, ...) {
        target_file <- file.path(to, basename(from))
        if (!file.exists(target_file)) {
            if(verbose) cat("copying", from, 'to', target_file, "...\n")
            file.copy(from, to, ...)
        } else {
            if(verbose) cat(target_file, 'already exists. Skipping.\n')
        }
        return(target_file)
    }, original_file_paths, to_stem, ...
    )
    return(all_target_files)
}




# Useful when in checkpoint
add_revo_packages_to_libPaths <- function(orig_pkg_info) {
    default_package_paths <- file.path(orig_pkg_info, Package)
}