##' Normalize process likelihood using the Laplace approximation.
##'
##' If the random effect likelihood contribution of a model has been
##' implemented without proper normalization (i.e. lacks the normalizing
##' constant), then this function can perform the adjustment
##' automatically. In order for this to work, the model must include a
##' flag that disables the data term so that the un-normalized random effect
##' (negative log) density is returned from the model template.
##' Automatic process normalization may be useful if either the
##' normalizing constant is difficult to implement, or if its calulation
##' involves so many operations that it becomes infeasible to include in
##' the AD machinery.
##'
##' @param obj Model object from \code{MakeADFun} without proper normalization of the random effect likelihood.
##' @param flag Flag to disable the data term from the model.
##' @param value Value of 'flag' that signifies to not include the data term.
##' @return Modified model object that can be passed to an optimizer.
normalize <- function(obj, flag, value=0) {
    obj1 <- obj ## Data included
    tracemgc <- obj1$env$tracemgc
    obj1$env$tracemgc <- FALSE
    ## Deep copy
    obj0 <- unserialize(serialize(obj, NULL))
    obj0$env$L.created.by.newton <- NULL ## Can't use same Cholesky object
    if (missing(flag)        ||
        ! is.character(flag) ||
        length(flag) != 1    ||
        length(obj0$env$data[[flag]]) == 0 ) {
        stop("'flag' must be a character of length one naming a data item.")
    }
    obj0$env$data[[flag]][] <- value
    obj0$retape()    
    newobj <- list()
    newobj$par <- obj1$par
    newobj$env <- obj1$env
    ## Workaround: Insert NAs in invalid hessian block H[fixed, fixed]
    ## if accessed by e.g. 'sdreport':
    random <- NULL ## CRAN check: no visible binding
    local({
        f_old <- f
        f <- function(...) {
            args <- list(...)
            ans <- f_old(...)
            if ((args$order == 1) &&
                (args$type == "ADGrad") &&
                is.vector(args$rangeweight) ) {
                if ( ! all( args$rangeweight[-random] == 0 ) ) {
                    ans[-random] <- NA
                }
            }
            ans
        }
    }, newobj$env)
    newobj$fn <- function(x = newobj$par) {
        env <- newobj$env
        value.best    <- env$value.best
        last.par.best <- env$last.par.best
        ans <- obj1$fn(x) - obj0$fn(x)
        last.par      <- env$last.par
        if (is.finite(ans)) {
            if (ans < value.best) {
                env$last.par.best <- last.par
                env$value.best    <- ans
            }
        }
        ans
    }
    newobj$gr <- function(x = newobj$par) {
        ans <- obj1$gr(x) - obj0$gr(x)
        if (tracemgc) 
            cat("outer mgc: ", max(abs(ans)), "\n")
        ans
    }
    newobj
}
