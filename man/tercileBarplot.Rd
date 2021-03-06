% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tercileBarplot.R
\name{tercileBarplot}
\alias{tercileBarplot}
\title{Tercile bar plot for visualization of forecast skill of seasonal climate predictions.}
\usage{
tercileBarplot(hindcast, obs, forecast = NULL, year.target = NULL,
  detrend = FALSE, conf.level = 0.95, score.threshold = NULL,
  subtitle = NULL)
}
\arguments{
\item{hindcast}{A multi-member list with the hindcast for verification. See details.}

\item{obs}{List with the benchmarking observations for forecast verification.}

\item{forecast}{A multi-member list with the forecasts. Default is NULL.}

\item{year.target}{Year within the hindcast period considered as forecast. Default is NULL.}

\item{detrend}{Logical indicating if the data should be linear detrended. Default is FALSE.}

\item{conf.level}{Confidence level to compute the score significance, by default conf.level=0.95}

\item{score.threshold}{Threshold to remark high positive score values in the figure.}

\item{subtitle}{String to include a subtitle bellow the title. Default is NULL.}
}
\description{
Tercile bar plot for visualization of the skill of seasonal climate predictions for a particular year.
 This function is prepared to plot the data sets loaded from the ECOMS User Data Gateway (ECOMS-UDG). See 
 the loadeR.ECOMS R package for more details (http://meteo.unican.es/trac/wiki/udg/ecoms/RPackage).
}
\details{
First daily data are averaged to obtain a single seasonal value. For rectangular spatial domains (i.e., for fields), 
the spatial average is first computed (with a warning) to obtain a
unique series for the whole domain. The corresponding terciles for each ensemble member are then computed
for the hindcast period. Thus, each particular member and season, are categorized into three categories (above, 
between or below), according to their respective climatological terciles. Then, a probabilistic forecast is computed 
year by year by considering the number of members falling within each category. The probability for the the forecast 
or selected year is represented by the bars. The 1/3 probability is plotted by a grey line. For instance, probabilities below this 
line are very low, indicating that a minority of the members falls in the tercile. Conversely, probabilities above 2/3 
indicate a high level of member agreement (more than 66\% of members falling in the same tercile).  
 
Finally, the ROC Skill Score (ROCSS) is indicated at the bottom part of the bar plot for each tercile. It provides a 
quantitative measure of the forecast skill, and it is commonly used to evaluate the performance of probabilistic systems
(Joliffe and Stephenson 2003). The value of this score ranges from 1 (perfect forecast system) to -1 
(perfectly bad forecast system). Zero indicates no skill compared with a random prediction. The selected year 
is not included in the computation of the score (operational point of view). Negative values
are written in red while high positive values are in blue. The threshold to highlight high positive values can be
modified with the score.threshold argument. Significance of the Area under the ROC curve is highlighted with an *. 
 
In case of multi-member fields or stations, they are spatially averaged to obtain one single time series
for each member prior to data analysis, with a warning.
}
\note{
The computation of climatological terciles requires a representative period to obtain meaningful results.
}
\examples{
\dontrun{
data(tas.cfs)
data(tas.cfs.operative.2016)
data(tas.ncep)
require(transformeR)
# Select spatial domain
tas.ncep2 <- subsetGrid(tas.ncep, lonLim = c(-80, -35), latLim = c(-12, 12))
tas.cfs2 <- subsetGrid(tas.cfs, lonLim = c(-80, -35), latLim = c(-12, 12))
tas.cfs.operative2.2016 <- subsetGrid(tas.cfs.operative.2016, 
                           lonLim = c(-80, -35), latLim = c(-12, 12))
# Tercile bar plot
tercileBarplot(hindcast = tas.cfs2, obs = tas.ncep2, forecast = tas.cfs.operative2.2016)
}
}
\references{
Jolliffe, I. T. and Stephenson, D. B. 2003. Forecast Verification: A Practitioner's Guide in 
 Atmospheri Science, Wiley, NY
}
\seealso{
Other visualization functions: \code{\link{bubblePlot}},
  \code{\link{reliabilityCategories}},
  \code{\link{spreadPlot}}, \code{\link{tercilePlot}}
}
\author{
M.D. Frias \email{mariadolores.frias@unican.es} and J. Fernandez
}
