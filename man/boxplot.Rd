% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot-boxplot.R
\name{boxplot}
\alias{boxplot}
\title{Draw boxplot}
\usage{
boxplot(
  d,
  method = "t.test",
  log_scale = FALSE,
  enable_label = FALSE,
  custom_theme_fn = NULL,
  ordered_groups = NULL,
  enable_log2fc = FALSE
)
}
\arguments{
\item{d}{A dataframe that contains the columns: gene_symbol, group, and value.}

\item{method}{Statistical test to use ("t.test", "wilcox.test", "anova", "kruskal.test").}

\item{log_scale}{Logical; if TRUE, log2 transformation is applied to the value column.}

\item{enable_label}{Logical; if TRUE, sample_id is annotated on the plot.}

\item{custom_theme_fn}{A custom theme function for the plot (optional).}

\item{ordered_groups}{Custom ordering of the group factor levels (optional).}

\item{enable_log2fc}{Logical; if TRUE, log2 fold change is calculated and annotated.}
}
\value{
A ggplot object representing the boxplot.
}
\description{
\code{boxplot()} requires a dataframe containing at least three columns: gene_symbol, group, and value.
The gene_symbol column may contain multiple genes, and the value column contains the corresponding gene expression values.
}
\details{
Optionally, an organ column can be included for further grouping, but the function doesn't support the case of multiple genes across multiple groups.

For more details, refer to:
\enumerate{
\item Points: https://r-graph-gallery.com/89-box-and-scatter-plot-with-ggplot2.html
\item Grouped Boxplot: https://r-graph-gallery.com/265-grouped-boxplot-with-ggplot2.html
\item P-Value: http://www.sthda.com/english/articles/24-ggpubr-publication-ready-plots/76-add-p-values-and-significance-levels-to-ggplots/
}
}
\examples{
# Example with one gene and two groups
d <- data.frame(
  gene_symbol = rep("TP53", 18),
  group = rep(c("Control", "Test1"), each = 9),
  value = round(runif(18), 1)
)
boxplot(d)

#' # Example with one gene and multiple groups
d <- data.frame(
  gene_symbol = rep("TP53", 18),
  group = rep(c("Control", "Test1", "Test2"), each = 6),
  value = round(runif(18), 1)
)
boxplot(d)

# Example with two genes and two groups
d <- data.frame(
  gene_symbol = rep(c("TP53", "ERBB2"), each = 12),
  group = rep(rep(c("Control", "Test"), each = 12 / 2), 2),
  value = round(runif(24), 1)
)
boxplot(d)

}
