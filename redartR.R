library(dartR)
library(ggplot2)

#' A ggplot builder for a bivariate plot of the results of a PCoA ordination
#'
#' See \code{\link[dartR]{gl.pcoa.plot}} for details on the plot.
#'
#' @param glPca Name of the glPca object containing the factor scores and eigenvalues [required]
#' @param data Name of the genlight object containing the SNP genotypes by specimen and population [required]
#' @param scale Flag indicating whether or not to scale the x and y axes in proportion to \% variation explained [default FALSE]
#' @param ellipse Flag to indicate whether or not to display ellipses to encapsulate points for each population [default FALSE]
#' @param p Value of the percentile for the ellipse to encapsulate points for each population [default 0.95]
#' @param labels -- Flag to specify the labels are to be added to the plot. ["none"|"ind"|"pop"|"interactive"|"legend", default = "pop"]
#' @param hadjust Horizontal adjustment of label position [default 1.5]
#' @param vadjust Vertical adjustment of label position [default 1]
#' @param xaxis Identify the x axis from those available in the ordination (xaxis <= nfactors)
#' @param yaxis Identify the y axis from those available in the ordination (yaxis <= nfactors)
#' @return An object of class "ggbuilder". Printing or plotting this ggbuilder object will return a ggplot object
#' @export
#'
#' @examples
#' gl <- testset.gl
#' levels(pop(gl)) <- c(rep("Coast", 5), rep("Cooper", 3),rep("Coast", 5)
#'                      rep("MDB", 8), rep("Coast", 7), "Em.subglobosa",
#'                      "Em.victoriae")
#' pcoa <- gl.pcoa(gl, nfactors = 5)
#' xb <- gl.pcoa.plot.builder(pcoa, gl, ellipse = TRUE, p = 0.99, labels = "pop", hadjust = 1.5, vadjust = 1)
#'

gl.pcoa.plot.builder <- function(glPca, data, scale = FALSE, ellipse = FALSE, p = 0.95, labels = "pop", hadjust = 1.5, vadjust = 1, xaxis = 1, yaxis = 2, values) {

    if (!inherits(glPca, c("glPca", "genlight")))
        stop("glPca and genlight objects required for glPca and data parameters respectively!")

    ## Create a dataframe to hold the required scores
    df <- data.frame(cbind(glPca$scores[, xaxis], glPca$scores[, yaxis]))

    ## Convert the eigenvalues to percentages
    s <- sum(glPca$eig)
    e <- round(glPca$eig*100/s, 1)

    ## Labels for the axes
    xlab <- paste0("PCoA Axis ", xaxis, " (", e[xaxis], "%)")
    ylab <- paste0("PCoA Axis ", yaxis, " (", e[yaxis], "%)")

    if (!labels %in% c("ind", "pop", "interactive", "plotly")) stop("labels \"", labels, "\" not implemented yet")
    group_by <- switch(labels,
                       "ind" = "ind",
                       "pop" = "pop",
                       NULL)

    if (labels %in% c("interactive", "ggplotly")) {
        ind <- as.character(indNames(data))
        pop <- as.character(pop(data))
        message("Preparing a plot for interactive labelling, follow with ggplotly()")
        message("Ignore any warning on the number of shape categories")
    } else {
        ind <- indNames(data)
        pop <- factor(pop(data))
    }

    if (missing(values)) values <- as.numeric(pop)
    df <- cbind(df, ind, pop)
    colnames(df) <- c("PCoAx", "PCoAy", "ind", "pop")

    ## build the object with the embedded plotting code and data
    out <- list(init = as_plotter(plotfun = "ggplot2::ggplot", plotargs = list(data = df, mapping = ggplot2::aes_string(x = "PCoAx", y = "PCoAy", group = group_by, colour = "pop"))))
    out$points <- as_plotter(plotfun = "ggplot2::geom_point", plotargs = list(size = 2))
    plot_sequence <- c("init", "points")
    if (labels %in% c("ind", "pop")) {
        dlargs <- list(mapping = ggplot2::aes_string(label = labels), method = if (labels == "ind") "first.points" else "smart.grid")
        out$labels <- as_plotter(plotfun = "directlabels::geom_dl", plotargs = dlargs)
        plot_sequence <- c(plot_sequence, "labels")
    }
    themeargs <- list(axis.title = ggplot2::element_text(face = "bold.italic", size = "20", color="black"),
                      axis.text.x  = ggplot2::element_text(face = "bold", angle = 0, vjust = 0.5, size = 10),
                      axis.text.y  = ggplot2::element_text(face = "bold", angle = 0, vjust = 0.5, size = 10),
                      legend.title = ggplot2::element_text(colour = "black", size = 18, face = "bold"),
                      legend.text = ggplot2::element_text(colour = "black", size = 16, face="bold"))
    if (labels %in% c("pop", "interactive", "plotly")) themeargs$legend.position <- "none"
    out$theme <- as_plotter(plotfun = "ggplot2::theme",
                            plotargs = themeargs)
    out$axis_labels <- as_plotter(plotfun = "ggplot2::labs", plotargs = list(x = xlab, y = ylab))
    out$hline <- as_plotter(plotfun = "ggplot2::geom_hline", plotargs = list(yintercept = 0))
    out$vline <- as_plotter(plotfun = "ggplot2::geom_vline", plotargs = list(xintercept = 0))
    out$scale_color <- as_plotter("ggplot2::scale_color_manual", plotargs = list(values = values))
    plot_sequence <- c(plot_sequence, "theme", "axis_labels", "hline", "vline", "scale_color")
    if (scale) {
        out$coord <- as_plotter(plotfun = "ggplot2::coord_fixed", plotargs = list(ratio = e[yaxis]/e[xaxis]))
        plot_sequence <- c(plot_sequence, "coord")
    }
    ## Add ellipses if requested
    if (ellipse) {
        ellpsargs <- list(type = "norm", level = p)
        if (labels == "pop") ellpsargs$colour <- "black"
        out$ellipse <- as_plotter(plotfun = "ggplot2::stat_ellipse", plotargs = ellpsargs)
        plot_sequence <- c(plot_sequence, "ellipse")
    }
    out$plot_sequence <- plot_sequence
    structure(out, class = "ggbuilder")
}


as_plotter <- function(plotfun, plotargs = NULL, name = NULL) {
    if (!is.character(plotfun)) {
        stopifnot(is.function(plotfun))
    } else {
        stopifnot(!is.na(plotfun), nzchar(plotfun))
    }
    if (!is.null(plotargs)) stopifnot(is.list(plotargs))
    out <- list(structure(list(plotfun = plotfun, plotargs = plotargs), class = "ggplotter"))
    if (!is.null(name)) {
        stopifnot(is.character(name), length(name) == 1)
        names(out) <- name
    }
    out
}

#' @method plot ggbuilder
#' @export
plot.ggbuilder <- function (x, y, ...) {
    ## interate through each plottable element in turn
    p <- NULL
    for (toplot in intersect(x$plot_sequence, names(x))) {
        allpf <- x[[toplot]] ## all the stuff to plot for this element
        if (!all(vapply(allpf, inherits, "ggplotter", FUN.VALUE = TRUE))) {
            warning("plotting behaviour for '", toplot, "' should be specified by a list of ggplotter objects, ignoring")
            next
        }
        ## evaluate each of these plotfuns
        for (thispf in allpf[seq_along(allpf)]) {
            thisfun <- thispf$plotfun
            this_plotargs <- thispf$plotargs
            thisp <- if (is.character(thisfun)) do.call(eval(parse(text = thisfun)), this_plotargs) else do.call(thisfun, this_plotargs)
            p <- if (is.null(p)) thisp else p + thisp
        }
    }
    p
}

#' @method print ggbuilder
#' @export
print.ggbuilder <- function(x, ...) {
    print(plot(x))
}
