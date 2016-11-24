splitData <- function(data = dF, pctTrain = 0.7) {
    # fcn to create indices to divide data into random 
    # training, validation and testing data sets
    N <- nrow(data)
    trainInd <- sample(N, pctTrain * N)
    testInd <- setdiff(seq_len(N), trainInd)
    indexList <- list(train = trainInd, test = testInd)
    return(indexList)
}
