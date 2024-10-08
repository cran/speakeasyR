## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----load-Matrix--------------------------------------------------------------
library(Matrix)

## ----mixing-param-------------------------------------------------------------
igraph_from_mixing_param <- function(n_nodes, n_types, mu) {
  pref <- matrix(mu, n_types, n_types)
  diag(pref) <- 1 - mu
  igraph::sample_pref(n_nodes, types = n_types, pref.matrix = pref)
}

## ----small-graph--------------------------------------------------------------
if (requireNamespace("igraph")) {
  g <- igraph_from_mixing_param(n_nodes = 50, n_types = 5, mu = 0.1)
}

## ----simple-cluster-----------------------------------------------------------
if (requireNamespace("igraph")) {
  memb <- speakeasyR::cluster(g, seed = 222, max_threads = 2)
}

## ----ordering-----------------------------------------------------------------
if (requireNamespace("igraph")) {
  ordering <- speakeasyR::order_nodes(g, memb)
  adj <- as(g[], "matrix")[ordering, ordering]
  color <- rainbow(length(unique(memb)))[memb[ordering]]
  heatmap(adj, scale = "none", Rowv = NA, Colv = NA, RowSideColors = color)
}

## ----tougher------------------------------------------------------------------
if (requireNamespace("igraph")) {
  g <- igraph_from_mixing_param(n_nodes = 1000, n_types = 10, mu = 0.4)
  memb <- speakeasyR::cluster(g, seed = 222, max_threads = 2)
  ordering <- speakeasyR::order_nodes(g, memb)
  adj <- as(g[], "matrix")[ordering, ordering]
  color <- rainbow(length(unique(memb)))[memb[ordering]]
  heatmap(adj, scale = "none", Rowv = NA, Colv = NA, RowSideColors = color)
}

## ----obtaining-data-----------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  expression <- scRNAseq::FletcherOlfactoryData()
  counts <- SummarizedExperiment::assay(expression, "counts")
  cell_types <- expression$cluster_id
}

## ----filtering----------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  indices <- rowSums(counts > 0) > 10
  counts <- counts[indices, ]
}

## ----normalization------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  target <- median(colSums(counts))
  size_factors <- colSums(counts) / target
  counts_norm <- log(t(t(counts) / size_factors + 1))
}

## ----pca----------------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  counts_norm <- t(prcomp(t(counts_norm), scale. = FALSE)$x)[1:50, ]
}

## ----knn-graph----------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  adj <- speakeasyR::knn_graph(counts_norm, 10)
}

## ----celltypes----------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  memb <- speakeasyR::cluster(adj, verbose = TRUE, seed = 222, max_threads = 2)
  ordering <- speakeasyR::order_nodes(adj, memb)
}

## ----display-cells------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  adj <- as.matrix(as(adj, "dMatrix"))
  row_colors <- rainbow(length(unique(cell_types)))[cell_types[ordering]]
  col_colors <- rainbow(length(unique(memb)))[memb[ordering]]
  heatmap(
    adj[ordering, ordering],
    Colv = NA, Rowv = NA,
    labRow = NA, labCol = NA,
    RowSideColors = row_colors, ColSideColors = col_colors,
    xlab = "SE2 Cluster", ylab = "Cell Type",
    scale = "none"
  )
}

## ----subclust-----------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  memb <- speakeasyR::cluster(
    adj,
    subcluster = 2,
    verbose = TRUE,
    seed = 222,
    max_threads = 2
  )
  ordering <- speakeasyR::order_nodes(adj, memb)
}

## ----viewsubtypes-------------------------------------------------------------
if (requireNamespace("scRNAseq") && requireNamespace("SummarizedExperiment")) {
  level <- 2
  level_order <- ordering[level, ]
  level_memb <- memb[level, level_order]
  row_colors <- rainbow(length(unique(cell_types)))[cell_types[level_order]]
  col_colors <- rainbow(length(unique(level_memb)))[level_memb]
  heatmap(
    adj[level_order, level_order],
    Colv = NA, Rowv = NA,
    labRow = NA, labCol = NA,
    RowSideColors = row_colors, ColSideColors = col_colors,
    xlab = "SE2 Cluster", ylab = "Cell Type",
    scale = "none", main = paste0("Level ", level, "structure")
  )
}

