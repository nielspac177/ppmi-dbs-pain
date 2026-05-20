#' Estimate a GLASSO partial-correlation network with safe fallback
#'
#' Wraps `bootnet::estimateNetwork` with EBICglasso + a fixed-ρ fallback
#' when the EBIC-selected lambda yields an empty network in small samples.
#'
#' @param data Numeric data frame; one row per observation.
#' @param rho_fallback Fixed regularisation parameter for fallback
#'   GLASSO (default 0.12).
#' @return A bootnet `estimateNetwork` object.
#' @export
build_glasso_network <- function(data, rho_fallback = 0.12) {
  net <- bootnet::estimateNetwork(
    data, default = "EBICglasso",
    corMethod = "cor_auto", missing = "pairwise",
    tuning = 0, lambda.min.ratio = 0.001, verbose = FALSE
  )
  if (all(net$graph == 0)) {
    S <- stats::cor(data, use = "pairwise.complete.obs")
    g <- glasso::glasso(S, rho = rho_fallback)
    P <- -stats::cov2cor(g$wi); diag(P) <- 0
    rownames(P) <- colnames(P) <- names(data)
    net$graph <- P
  }
  net
}

#' Network Comparison Test wrapper
#'
#' @param net_a,net_b bootnet `estimateNetwork` objects (one per arm).
#' @param it Permutations (default 500).
#' @return The `NCT` result object.
#' @export
network_comparison <- function(net_a, net_b, it = 500) {
  NetworkComparisonTest::NCT(
    net_a, net_b, it = it,
    test.edges = TRUE, edges = "all",
    test.centrality = FALSE, progressbar = FALSE
  )
}
