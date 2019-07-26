
<!-- README.md is generated from README.Rmd. Please edit that file -->

# redartR

<!-- badges: start -->

<!-- badges: end -->

`redartR` is a builder for PCoA plots from the `dartR` package. The
original `dartR::gl.pcoa.plot` function builds the `ggplot` object
directly, which can then be difficult to modify to suit your needs.

Instead, this `gl.pcoa.plot.builder` function returns an object of class
`ggbuilder`, which contains the data and code required to produce the
`ggplot` object. You can modify that code and/or data inside the
`ggbuilder` object. Printing or plotting the `ggbuilder` object then
evaluates that code and produces a `ggplot` object; printing or plotting
*that* object will draw the plot to the current graphics device, as per
any other `ggplot` object.

## Example

``` r
## load the dartR packge
library(dartR)
## and the functions from this repo
source("redartR.R")

## example plot
gl <- testset.gl
levels(pop(gl)) <- c(rep("Coast", 5), rep("Cooper", 3),rep("Coast", 5),
                     rep("MDB", 8), rep("Coast", 7), "Em.subglobosa",
                     "Em.victoriae")
pcoa <- gl.pcoa(gl, nfactors = 5)
#> Performing a PCoA, individuals as entities, SNP loci as attributes
#> Ordination yielded 14 informative dimensions from 249 original dimensions
#>   PCoA Axis 1 explains 23.3 % of the total variance
#>   PCoA Axis 1 and 2 combined explain 42.8 % of the total variance
#>   PCoA Axis 1-3 combined explain 54.4 % of the total variance

## the existing `gl.pcoa.plot` function
gl.pcoa.plot(pcoa, gl, ellipse = TRUE, p = 0.99, labels = "pop", hadjust = 1.5, vadjust = 1)
#> Plotting populations
```

![](README_files/figure-gfm/example-1.png)<!-- -->

``` r


## construct the ggbuilder object
xb <- gl.pcoa.plot.builder(pcoa, gl, ellipse = TRUE, p = 0.99, labels = "pop", hadjust = 1.5, vadjust = 1)

class(xb)
#> [1] "ggbuilder"

## the contents of that object
str(xb, max.level = 2)
#> List of 10
#>  $ init         :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ points       :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ labels       :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ theme        :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ axis_labels  :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ hline        :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ vline        :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ scale_color  :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ ellipse      :List of 1
#>   ..$ :List of 2
#>   .. ..- attr(*, "class")= chr "ggplotter"
#>  $ plot_sequence: chr [1:9] "init" "points" "labels" "theme" ...
#>  - attr(*, "class")= chr "ggbuilder"

str(xb$points)
#> List of 1
#>  $ :List of 2
#>   ..$ plotfun : chr "ggplot2::geom_point"
#>   ..$ plotargs:List of 1
#>   .. ..$ size: num 2
#>   ..- attr(*, "class")= chr "ggplotter"

## plotting that object produces a ggplot object
xp <- plot(xb)
class(xp)
#> [1] "gg"     "ggplot"

## printing or plotting the xp object produces the actual plot
xp
```

![](README_files/figure-gfm/example-2.png)<!-- -->

``` r

## modify something in the ggbuilder object
## replace the code that plots the points
xb$points <- as_plotter(plotfun = "ggplot2::geom_point",
                        plotargs = list(mapping = aes_string(shape = "pop", size = 2)))

## and draw the modified plot
xb
```

![](README_files/figure-gfm/example-3.png)<!-- -->

Note: this is largely just a proof of concept. Only `labels` of type
`"pop"`, `"ind"`, `"interactive"`, or `"plotly"` are supported at the
moment.
