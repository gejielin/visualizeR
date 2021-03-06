#     temporalPlot.R Lattice plot methods for climatological grids
#
#     Copyright (C) 2017 Santander Meteorology Group (http://www.meteo.unican.es)
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.



#' @title Lattice plot methods for climatological series 
#' @description A wrapper for the lattice (trellis) plot methods for grid and station data.
#' @param ... Input grids (or station data)
#' @param aggr.spatial list containing the function and the related arguments to perform spatial 
#' aggregation. Default is \code{list(FUN = mean, na.rm = TRUE)}.
#' @param cols Character with colors.
#' @param lwd Numeric for line width.
#' @param lty Numeric for line type.
#' @param missing.dates Logical. Not implemented (see Details).
#' @param show.na Logical. Implemented but under development (see Details). 
#' @param xyplot.custom List of arguments as passed to xyplot. Argument \code{panel} cannot be modified, thus,
#' if specified, it will be ignored. 
#' @details The function applies the \code{\link[lattice]{xyplot}} method after computing spatial aggregation 
#' (parameter \code{aggr.spatial}) and member aggregation (mean and range) to the imput grids (or station data).
#'  
#' In case of multimember grids, the function will internally compute the ensemble mean 
#' and the range for plotting. The range is used to plot the shadow of the multimember spread.
#'  
#'  \strong{Controlling graphical parameters}
#'  
#'  Many different aspects of the plot can be controlled passing the relevant arguments to 
#'  \code{xyplot}. Fine control of graphical parameters for the trellis display can
#'  be also controlled using \code{\link[lattice]{trellis.par.set}}.
#'  
#'  \strong{Future Work}
#'  
#'  Implement parameters missing.dates (default will be TRUE) to suppress 
#'  dates without values from xaxis when FALSE.
#'  Implement parameter show.na (default will be FALSE) to fill with gray
#'  NA values when TRUE.
#'  Implement auxiliary functions to reduce dependencies and remove from 
#'  imports packages \code{data.table}, \code{padr} and \code{grDevices}.
#'   
#'   
#
#' @return A lattice plot of class \dQuote{trellis}. 
#' 
#'    
#'@author M. Iturbide
#'@export
#'@importFrom lattice xyplot panel.grid panel.polygon panel.xyplot
#'@importFrom grDevices col2rgb rgb colors
#'@importFrom padr pad
#'@importFrom data.table rleid
#'@import latticeExtra
#' @examples
#' data("CFS_Iberia_pr")
#' data("EOBS_Iberia_pr")
#' data("VALUE_Iberia_pr")
#' # Combine grids with members (CFS) and without members (EOBS)
#' a <- subsetGrid(CFS_Iberia_tas, years = 1985:1992)
#' b <- subsetGrid(EOBS_Iberia_tas, years = 1985:1992)
#' temporalPlot("EOBS" = b, "CFS" = a,
#'              xyplot.custom = list(main = "winter temperature", ylab = "Celsius"))
#' # Station and grid data can be combined, also different temporal ranges
#' v <- subsetGrid(VALUE_Iberia_tas, years = 1988:1990)
#' temporalPlot("VALUE" = v, "EOBS" = b, "CFS" = a, lwd = 0.9,
#'              aggr.spatial = list(FUN = min, na.rm = TRUE),
#'              xyplot.custom = list(main = "winter temperature",
#'                                   ylab = "Celsius", ylim = c(-20, 10)))
#' # Use subsetGrid to obtain and plot a single location (no spatial aggregation)
#' a1 <- subsetGrid(a, lonLim = 2, latLim = 42)
#' b1 <- subsetGrid(b, lonLim = 2, latLim = 42)
#' 
#' temporalPlot("EOBS" = b1, "CFS" = a1, 
#'              cols = c("green", "deeppink"), show.na = TRUE,
#'              xyplot.custom = list(main = "winter temperature", ylab = "Celsius"))


temporalPlot <- function(..., 
                         aggr.spatial = list(FUN = mean, na.rm = TRUE), 
                         cols = NULL,
                         lwd = 1,
                         lty = 1,
                         missing.dates = TRUE,
                         show.na = FALSE,
                         xyplot.custom = list()) {
  obj.list <- list(...)
  if (is.null(names(obj.list))) {
    nmes <- as.list(substitute(list(...)))[-1L]
    names(obj.list) <- as.character(nmes)
  }
  obj.list <- lapply(obj.list, FUN = redim)
  # spatial aggregation
  aggr.spatial[["MARGIN"]] <- c(1,2)
  data <- lapply(1:length(obj.list), function(x){
    aggr.spatial[["X"]] <- obj.list[[x]]$Data
    do.call("apply", aggr.spatial)
  })
  # extract dates
  dates <- lapply(1:length(obj.list), function(x){
    as.Date(obj.list[[x]]$Dates$start)
  })
  # member aggregation
  mm <- lapply(data, FUN = apply, MARGIN = 2,  mean)
  mx <- lapply(data, FUN = apply, MARGIN = 2,  max)
  mn <- lapply(data, FUN = apply, MARGIN = 2,  min)
  # bind to data frames
  df <- lapply(1:length(obj.list), function(x){
      df0 <- cbind(as.data.frame(mm[[x]]), as.data.frame(dates[[x]]), 
                   as.data.frame(mn[[x]]), as.data.frame(mx[[x]]))
      colnames(df0) <- c("Value", "Dates", "mini", "maxi")
      return(df0)
    })
  # complete temporal series
  df <- lapply(df, FUN = pad) # uses package padr to fill dates in the data.frame. Should we implement alternative code?
  # prepare inter-NA chunks for panel.polygon
  df.polys <- lapply(1:length(df), function(i){
    chunkid <- rle(!is.na(df[[i]]$Value))$values
    split(df[[i]], rleid(is.na(df[[i]]$Value)))[chunkid]
  })
  df.polys.na <- lapply(1:length(df), function(i){
    chunkid <- rle(is.na(df[[i]]$Value))$values
    split(df[[i]], rleid(is.na(df[[i]]$Value)))[chunkid]
  })
  # define graphical parameters
  ylim <- round(range(c(unlist(mm), unlist(mx)), na.rm = TRUE), digits = 2)
  xlim <- range(do.call("c", dates))
  # xdates0 <- unique(do.call("c", dates))[order(unique(do.call("c", dates)))]
  # seqval <- round(length(xdates0)/10)
  # xdates <- xdates0[seq(1, length(xdates0), seqval)]
  colors2 <- colors()[-c(552, 254, 26, 24)]
  colors2 <- colors2[sample(1:length(colors2), size = length(colors2))]
  if (is.null(cols)) cols <- c("black","red", "blue", "green", colors2)
  if (length(cols) < length(obj.list)) stop("Please, add ", length(obj.list) - length(cols), " more color/s to 'cols', or keep the default option.")
  if (is.null(xyplot.custom[["x"]])) xyplot.custom[["x"]] <- Value ~ Dates
  if (is.null(xyplot.custom[["type"]])) xyplot.custom[["type"]] = "l"
  if (is.null(xyplot.custom[["ylim"]])) xyplot.custom[["ylim"]] <- ylim
  if (is.null(xyplot.custom[["xlim"]])) xyplot.custom[["xlim"]] <- xlim
  if (is.null(xyplot.custom[["lwd"]])) xyplot.custom[["lwd"]] <- 2
  ylim <- xyplot.custom[["ylim"]]
  xlim <- xyplot.custom[["xlim"]]
  if (is.null(xyplot.custom[["scales"]])) xyplot.custom[["scales"]] <- list(x = list(at = seq(xlim[1], xlim[2],(xlim[2] - xlim[1])/10),
                                         labels = seq(xlim[1], xlim[2],(xlim[2] - xlim[1])/10), rot = 45),
                       y = list(at = seq(ylim[1], ylim[2],round((ylim[2] - ylim[1])/10)),
                                labels = seq(ylim[1], ylim[2],round((ylim[2] - ylim[1])/10))),
              cex = .6, col = "black")
  if (is.null(xyplot.custom[["key"]])) xyplot.custom[["key"]] <- list(space = "right", points = list(pch = 15, 
                                          col = cols[1:length(obj.list)],
                                          cex = .5),
                                 text = list(names(obj.list), cex = .8))
  # crate trellis objects
  xy <- lapply(1:length(df), function(i){
    col <- cols[i]
    colsrgb <- do.call("rgb", as.list(c(col2rgb(col)/255, 0.15)))
    xyplot.custom[["data"]] <- df[[i]]
    xyplot.custom[["col"]] <- col
    xyplot.custom[["panel"]] <- function(x, y, z, ...) {
      for (l in 1:length(df.polys[[i]])) {
        panel.polygon(na.omit(c(df.polys[[i]][[l]]$Dates,  rev(df.polys[[i]][[l]]$Dates))), na.omit(c(df.polys[[i]][[l]]$mini, rev(df.polys[[i]][[l]]$maxi))),
                    border = NA, col = colsrgb)
      }
      if (show.na) {
        for (l in 1:length(df.polys.na[[i]])) {
          panel.polygon(na.omit(c(df.polys.na[[i]][[l]]$Dates,  rev(df.polys.na[[i]][[l]]$Dates))), 
                      na.omit(c(ylim[1], ylim[2])),
                      border = NA, col = "gray90")
        }
      }
      panel.xyplot(df[[i]]$Dates, df[[i]]$Value, type = "l", lwd = lwd, lty = lty, col = col)
      panel.abline(h = seq(ylim[1], ylim[2],round((ylim[2] - ylim[1])/10)), 
                   v = seq(xlim[1], xlim[2],(xlim[2] - xlim[1])/10), 
                   col = "gray65", lwd = 0.5, lty = 2)
    }
    
    do.call("xyplot", xyplot.custom)
  })
  # evaluate trellis objects
  p0 <- lapply(1:length(obj.list), function(x){
    if (x == length(obj.list)) {
      paste0("xy[[", x, "]]")
    } else {
      paste0("xy[[", x, "]] +")
    }
  })
  output <- eval(parse(text = do.call("paste", p0)))
  return(output)
}

#end
