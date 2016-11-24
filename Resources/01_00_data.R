## does any relevant preprocessing.
## naming convention is
## DD_DD_preprocess.R
##    DD - overall order of groups
##    DD - order within that group
## For this file, it takes the relevant datasets in the nycflights13
## package and writes them to csv files in the data directory


## function to create_data
create_data <- function(repo_dir = NULL, verbose = FALSE) {
    ## if it's null, check for some directories...
    if (is.null(repo_dir)) {
        repo_dir <- get_repo_dir()
    }
    data_dir <- file.path(repo_dir, "data")
    dir.create(data_dir, showWarnings = verbose)
    ## adjust below to create the relevant data files
 

    if(verbose) cat("Done with data!\n")
    invisible(NULL)
}

