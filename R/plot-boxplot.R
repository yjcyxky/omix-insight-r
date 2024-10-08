#' Draw boxplot
#'
#' `boxplot()` requires a dataframe containing at least three columns: gene_symbol, group, and value.
#' The gene_symbol column may contain multiple genes, and the value column contains the corresponding gene expression values.
#'
#' Optionally, an organ column can be included for further grouping, but the function doesn't support the case of multiple genes across multiple groups.
#'
#' For more details, refer to:
#' 1. Points: https://r-graph-gallery.com/89-box-and-scatter-plot-with-ggplot2.html
#' 2. Grouped Boxplot: https://r-graph-gallery.com/265-grouped-boxplot-with-ggplot2.html
#' 3. P-Value: http://www.sthda.com/english/articles/24-ggpubr-publication-ready-plots/76-add-p-values-and-significance-levels-to-ggplots/
#'
#' @param d A dataframe that contains the columns: gene_symbol, group, and value.
#' @param method Statistical test to use ("t.test", "wilcox.test", "anova", "kruskal.test").
#' @param log_scale Logical; if TRUE, log2 transformation is applied to the value column.
#' @param custom_theme_fn A custom theme function for the plot (optional).
#' @param ordered_groups Custom ordering of the group factor levels (optional).
#' @param enable_log2fc Logical; if TRUE, log2 fold change is calculated and annotated.
#' @param enable_label Logical; if TRUE, sample_id is annotated on the plot.
#'
#' @return A ggplot object representing the boxplot.
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 geom_boxplot
#' @importFrom ggplot2 geom_jitter
#' @importFrom ggplot2 geom_text
#' @importFrom ggplot2 labs
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 annotate
#' @importFrom ggplot2 position_dodge
#' @importFrom ggplot2 geom_segment
#' @importFrom ggsci scale_fill_npg
#' @export
#' @examples
#' # Example with one gene and two groups
#' d <- data.frame(
#'   gene_symbol = rep("TP53", 18),
#'   group = rep(c("Control", "Test1"), each = 9),
#'   value = round(runif(18), 1)
#' )
#' boxplot(d)
#'
#' #' # Example with one gene and multiple groups
#' d <- data.frame(
#'   gene_symbol = rep("TP53", 18),
#'   group = rep(c("Control", "Test1", "Test2"), each = 6),
#'   value = round(runif(18), 1)
#' )
#' boxplot(d)
#'
#' # Example with two genes and two groups
#' d <- data.frame(
#'   gene_symbol = rep(c("TP53", "ERBB2"), each = 12),
#'   group = rep(rep(c("Control", "Test"), each = 12 / 2), 2),
#'   value = round(runif(24), 1)
#' )
#' boxplot(d)
#'
boxplot <- function(d, method = "t.test", log_scale = FALSE, enable_label = FALSE,
                    custom_theme_fn = NULL, ordered_groups = NULL, enable_log2fc = FALSE) {
  # Check if gene_symbol, group, value columns exist
  if (!all(c("gene_symbol", "group", "value") %in% colnames(d))) {
    stop("Dataframe must contain 'gene_symbol', 'group', and 'value' columns.")
  }

  # Apply log transformation if needed
  if (log_scale) {
    d$value <- log2(d$value + 1)
    ytitle <- "Expression [log2(ExprValue + 1)]"
  } else {
    ytitle <- "Expression [ExprValue]"
  }

  title <- "Expression on BoxPlot"

  # Check custom theme function
  if (is.null(custom_theme_fn) || !is.function(custom_theme_fn)) {
    warning("Invalid custom_theme_fn provided. Using default theme.")
    custom_theme_fn <- custom_theme
  }

  if (is.null(ordered_groups)) {
    ordered_groups <- sort(unique(d$group))
  }

  # Set group factor levels if provided
  if (!is.null(ordered_groups)) {
    d$group <- factor(d$group, levels = ordered_groups)
  }

  gene_symbols <- sort(unique(d$gene_symbol))
  d$gene_symbol <- factor(d$gene_symbol, levels = gene_symbols)

  # Set id factor levels if id column exists
  if ("id" %in% colnames(d)) {
    d$id <- factor(d$id, levels = sort(unique(d$id)))
  }

  print(paste("gene_symbols =", gene_symbols))
  print(paste("unique(d$group) =", unique(d$group)))
  print(paste("ordered_groups =", ordered_groups))

  # 修改计算log2FC的函数，让它同时返回p值
  calc_log2fc_and_pvalue <- function(d, log_scale, method) {
    comparisons <- combn(unique(as.character(d$group)), 2, simplify = FALSE)
    labels <- c()

    for (comparison in comparisons) {
      group1 <- comparison[1]
      group2 <- comparison[2]

      # 选择只包含 group1 和 group2 的数据
      gene_data <- d[d$group %in% c(group1, group2), ]

      # 计算 log2 fold change
      log2foldchange <- if (log_scale) {
        mean(log2(gene_data$value[gene_data$group == group1])) -
          mean(log2(gene_data$value[gene_data$group == group2]))
      } else {
        log2(mean(gene_data$value[gene_data$group == group1]) /
               mean(gene_data$value[gene_data$group == group2]))
      }

      # 计算p值
      if (method == "t.test") {
        test_result <- t.test(value ~ group, data = gene_data)
        p_value <- test_result$p.value
      } else if (method == "wilcox.test") {
        test_result <- wilcox.test(value ~ group, data = gene_data)
        p_value <- test_result$p.value
      }

      # 格式化p值
      p_format <- if (p_value < 0.001) {
        "p < 0.001"
      } else {
        sprintf("p = %.3f", p_value)
      }

      # 组合log2FC和p值
      combined_label <- sprintf("log2FC = %.2f %s", log2foldchange, p_format)
      labels <- c(labels, combined_label)
    }

    return(list(comparisons = comparisons, labels = labels))
  }

  log2fc_result <- calc_log2fc_and_pvalue(d, log_scale, method)
  comparisons <- log2fc_result$comparisons
  log2fc_labels <- log2fc_result$labels
  print(paste("comparisons =", comparisons))
  print(paste("log2fc_labels =", log2fc_labels))

  # Plot logic based on group and gene symbol combinations
  if (length(gene_symbols) == 1 && length(unique(d$group)) == 2) {
    print("Case 1: One gene in two groups (log2FC and p-value for the two groups)")
    p <- ggplot(d, aes(x = group, y = value, fill = group)) +
      geom_boxplot(position = position_dodge(width = 0.75)) +
      labs(x = "Group", y = paste0(gene_symbols[1], " ", ytitle), fill = "Group", title = title) +
      custom_theme_fn()

    for (i in 1:length(log2fc_labels)) {
      # The x position is the middle of the two groups
      p <- p + annotate("text", x = 1.5, y = max(d$value) * 1.05, label = log2fc_labels[i], size = 5, fontface = "italic", hjust = 0.5)
    }
  } else if (length(gene_symbols) == 1 && length(unique(d$group)) > 2) {
    print("Case 2: One gene in multiple groups (only p-value for multiple group comparisons)")
    p <- ggplot(d, aes(x = group, y = value, fill = group)) +
      geom_boxplot(position = position_dodge(width = 0.75)) +
      labs(x = "Group", y = ytitle, fill = "Group", title = title) +
      custom_theme_fn()

    comparisons <- combn(unique(as.character(d$group)), 2, simplify = FALSE)
    for (i in 1:length(comparisons)) {
      group1 <- comparisons[[i]][1]
      group2 <- comparisons[[i]][2]
      
      x_start <- match(group1, levels(d$group))
      x_end <- match(group2, levels(d$group))
      
      y_position <- max(d$value) * (1.05 + 0.05 * i)

      p <- p + 
        annotate("segment", x = x_start, xend = x_end, y = y_position, yend = y_position) +
        annotate("text", x = (x_start + x_end) / 2, y = y_position + 0.02, 
                label = log2fc_labels[i], size = 5, fontface = "italic", hjust = 0.5)
    }
  } else if (length(gene_symbols) > 1 && length(unique(d$group)) == 2) {
    print("Case 3: Multiple genes in two groups (log2FC and p-value for each gene separately)")
    p <- ggplot(d, aes(x = gene_symbol, y = value, fill = group)) +
      geom_boxplot(position = position_dodge(width = 0.75)) +
      labs(x = "Gene Symbol", y = ytitle, fill = "Group", title = title) +
      custom_theme_fn()

    log2fc_results <- list()
    for (i in 1:length(gene_symbols)) {
      gene_data <- d[d$gene_symbol == gene_symbols[i], ]
      log2fc_result <- calc_log2fc_and_pvalue(gene_data, log_scale, method)
      log2fc_results[[gene_symbols[i]]] <- log2fc_result
    }

    log2fc_labels <- unlist(lapply(log2fc_results, function(x) x$labels))

    for (i in 1:length(log2fc_labels)) {
      p <- p + annotate("text", x = i, y = max(d$value) * 1.05, label = log2fc_labels[i], size = 5, fontface = "italic", hjust = 0.5)
    }
  } else if (length(gene_symbols) > 1 && length(unique(d$group)) > 2) {
    print("Case 4: Multiple genes in multiple groups (p-value for multiple group comparisons per gene)")
    p <- ggplot(d, aes(x = gene_symbol, y = value, fill = group)) +
      geom_boxplot(position = position_dodge(width = 0.75)) +
      labs(x = "Gene Symbol", y = ytitle, fill = "Group", title = title) +
      custom_theme_fn()
  } else {
    stop("Invalid input data. Please provide a dataframe with the required columns: gene_symbol, group, and value. We only support one gene and two groups, one gene and multiple groups, multiple genes and two groups, or multiple genes and multiple groups.")
  }

  # Optionally add labels to points
  if (enable_label) {
    p <- p + geom_text(aes(label = sample_id),
                       position = position_jitter(width = 0.2),
                       size = 3, vjust = -0.5, alpha = 0.8)
  }

  p <- p + geom_jitter(size = 2, alpha = 0.6, color = "black", position = position_dodge(width = 0.75)) +
    theme(legend.position = "top", plot.title = element_text(hjust = 0.5)) + scale_fill_npg()

  return(p)
}

#' Draw boxplot and save it as JSON and PDF files.
#' @param d A dataframe that contains the columns: gene_symbol, group, value.
#' @param output_file File path to save the output.
#' @param filetype The file format to save as (e.g., "pdf", "png").
#' @param ... Additional arguments passed to the boxplot function.
#'
#' @return A ggplot object.
#' @importFrom plotly ggplotly
#' @importFrom plotly layout
#' @importFrom plotly plotly_json
#' @importFrom jsonlite toJSON
#' @importFrom fs path_ext_remove
#' @importFrom dplyr %>%
#' @export
boxplotly <- function(d, output_file = "", filetype = "pdf", ...) {
  p <- boxplot(d, ...)

  # If output file is specified, save JSON and PDF
  if (!is.null(output_file) && nchar(output_file) > 0) {
    json <- plotly_json(ggplotly(p) %>% layout(boxmode = "group"), FALSE)
    write(json, file = output_file)

    # Save as PDF
    filepath <- dirname(output_file)
    filename <- basename(output_file)
    save2pdf(p, filename = paste0(fs::path_ext_remove(filename), ".", filetype),
             filepath = filepath, width = 8, height = 8)
  }

  return(p)
}

#' Query expression data and sample info from external files (expression.csv, sample_info.csv)
#' @param exp_file Path to the expression file.
#' @param sample_info_file Path to the sample info file.
#' @param which_ids IDs to filter the expression data.
#' @param which_gene_symbols Gene symbols to filter the expression data.
#' @param which_groups Groups to filter the sample info.
#'
#' @return A dataframe containing the expression data and sample info.
#' @importFrom readr read_delim
#' @importFrom dplyr left_join
#' @importFrom tidyr pivot_longer
#' @export
#' @examples
#' # Two groups, two genes
#' d <- query_data(exp_file = "./examples/gene_expression.tsv", sample_info_file = "./examples/sample_info.tsv", which_ids = c("SL003951", "SL003970"), which_groups = c("Female_MECFS", "Female_Control"))
#'
#' # One group, multiple genes
#' d <- query_data(exp_file = "./examples/gene_expression.tsv", sample_info_file = "./examples/sample_info.tsv", which_gene_symbols = c("TP53", "ERBB2"), which_groups = c("Female_MECFS"))
#'
#' # Two groups, multiple genes
#' d <- query_data(exp_file = "./examples/gene_expression.tsv", sample_info_file = "./examples/sample_info.tsv", which_ids = c("SL003951", "SL003970", "SL003980"), which_groups = c("Female_MECFS", "Female_Control", "Male_MECFS"))
query_data <- function(exp_file, sample_info_file, which_ids = NULL, which_gene_symbols = NULL, which_groups = NULL) {
  # Set the separator to tab or comma depending on the file extension
  exp_file_ext <- fs::path_ext(exp_file)
  sample_info_file_ext <- fs::path_ext(sample_info_file)

  if (exp_file_ext == "csv") {
    sep <- ","
  } else if (exp_file_ext == "tsv") {
    sep <- "\t"
  }

  # Read the expression and group files
  exp <- read_delim(exp_file, delim = sep)
  sample_info <- read_delim(sample_info_file, delim = sep)

  exp_colnames <- colnames(exp)
  sample_info_colnames <- colnames(sample_info)

  if (!'gene_symbol' %in% exp_colnames) {
    stop("Expression file must contain a 'gene_symbol' column.")
  }

  if (!'id' %in% exp_colnames) {
    stop("Expression file must contain an 'id' column.")
  }

  if (!'group' %in% sample_info_colnames) {
    stop("Sample info file must contain a 'group' column.")
  }

  if (!'sample_id' %in% sample_info_colnames) {
    stop("Sample info file must contain a 'sample_id' column.")
  }

  sample_ids <- exp_colnames[!exp_colnames %in% c('gene_symbol', 'id')]
  if (length(sample_ids) == 0) {
    stop("Expression file must contain at least one sample column.")
  }

  sample_ids_in_sample_info <- sample_info$sample_id
  if (!all(sample_ids %in% sample_ids_in_sample_info)) {
    stop("All sample IDs must be present in the sample info file.")
  }

  if (!all(sample_ids_in_sample_info %in% sample_ids)) {
    stop("All sample IDs must be present in the expression file.")
  }

  if (!is.null(which_ids) && length(which_ids) > 0) {
    exp <- exp[exp$id %in% which_ids, ]
  } else if (!is.null(which_gene_symbols) && length(which_gene_symbols) > 0) {
    exp <- exp[exp$gene_symbol %in% which_gene_symbols, ]
  } else {
    stop("which_ids or which_gene_symbols is required.")
  }

  if (!is.null(which_groups) && length(which_groups) > 0) {
    sample_info <- sample_info[sample_info$group %in% which_groups, ]
  } else {
    stop("which_groups is required.")
  }

  # if (length(which_ids) > 1 && length(which_groups) > 2) {
    # stop("Multiple genes and multiple groups are not supported.")
  # }

  # Convert the group + exp to long format. It contains columns: group, sample_id, value, id, gene_symbol
  d <- pivot_longer(exp, cols = all_of(sample_ids), names_to = "sample_id", values_to = "value")
  d <- dplyr::left_join(d, sample_info, by = "sample_id")
  # Filter out rows with NA values in the group column
  d <- d[!is.na(d$group), ]

  if (nrow(d) == 0) {
    stop("No data left after filtering, please check your input parameters, such as which_ids, which_gene_symbols, and which_groups.")
  }

  return(d)
}
