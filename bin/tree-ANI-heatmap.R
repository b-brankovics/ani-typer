#!/usr/bin/env Rscript

options(warn=0) #Set this value back to 0 if you want to display Rscript warnings in the terminal.

args <- commandArgs(trailingOnly = TRUE)

say = function(x) {
    write(x, stdout())
}

if (length(args) < 2) {
   say("ERROR: The script requires at least two arguments.")
   say("USAGE:")
   say("\ttree-ANI-heatmap.R <newick tree file> <tab-separated table> [<output file>]")
   say("\tWarning: The tab-separated table needs to be symmetrical table (rownames and colnames have to be the same.)")
   .Internal(.invokeRestart(list(NULL, NULL), NULL))
}


say("Executing R script for plotting tree and heatmap")

# install.packages('dendextend', repos='http://cran.us.r-project.org')
# install.packages('phylogram', repos='http://cran.us.r-project.org')
# install.packages('phangorn', repos='http://cran.us.r-project.org')
# install.packages('circlize', repos='http://cran.us.r-project.org')
# install.packages("BiocManager", repos = "https://cloud.r-project.org")
# BiocManager::install("ComplexHeatmap")


# For Newick and tree handeling
suppressPackageStartupMessages(library(dendextend))
suppressPackageStartupMessages(library('phylogram'))
suppressPackageStartupMessages(library('phangorn'))
# For Heatmap
suppressPackageStartupMessages(library("ComplexHeatmap"))
# For color scale
suppressPackageStartupMessages(library(circlize))


# Arguments:
# 1. tree file
newick=args[1]
# 2. table for heatmap
infile=args[2]
# 3. outputfile (=args[3])
plotfile = "heatmap.pdf"

if (length(args) > 2) {
   plotfile = args[3]
   }

# Read tree and convert to ultramteric dendogram
tree = ape::read.tree(newick)

force.ultrametric<-function(tree,method=c("nnls","extend")){
  method<-method[1]
  if(method=="nnls") tree<-nnls.tree(cophenetic(tree),tree,
                                     rooted=TRUE,trace=0)
  else if(method=="extend"){
    h<-diag(vcv(tree))
    d<-max(h)-h
    ii<-sapply(1:Ntip(tree),function(x,y) which(y==x),
               y=tree$edge[,2])
    tree$edge.length[ii]<-tree$edge.length[ii]+d
  } else 
    cat("method not recognized: returning input tree\n\n")
  tree
}
ultra = force.ultrametric(tree)
dendro = as.dendrogram.phylo(ultra)
coldendrogram  = rev( dendro %>% set("branches_lwd", 2) )

# Set data in proper order and format with names
d <- read.table(infile, sep = "\t", header = TRUE, row.names = 1)
# colnames(d) = rownames(d)
# ok = 0
# for (i in rownames(d)) {
#     if (d[i,i] == 1) {
#         ok = ok + 1
#     }
# }
# if ( ok == length(rownames(d)) ) {
#     say('ANI table appears to be sorted')
# } else {
#     say("\nERROR: The script requires a symmetrical table (rownames and colnames have to be the same.)")
#     say("USAGE:")
#     say("\ttree-ANI-heatmap.R <newick tree file> <tab-separated table> [<output file>]")
#     .Internal(.invokeRestart(list(NULL, NULL), NULL))
# }
d = d[tree$tip.label, tree$tip.label]
data <- as.matrix(d)

# Set output
pdf(file=plotfile, width=12, height=12, pointsize = 8) # default pointsize = 16 , family="Arial"

# Color breaks (above max and below min color stays the same
max = 1
cutoff = 0.95
min = 0.7

col_fun = colorRamp2(c(max, cutoff, cutoff - 0.000001, min), c("darkgreen", "lightgreen", "yellow", "red"))

say("Generating heatmap plot")
Heatmap(data, name = "ANI",
	cluster_rows = coldendrogram,
	cluster_columns = coldendrogram,
# Add values
#	cell_fun = function(j, i, x, y, width, height, fill) {grid.text(sprintf("%.3f", data[i, j]), x, y, gp = gpar(fontsize = 20))},
	col = col_fun, column_title = "ANI"
)

invisible(dev.off())

say('Finished R script for plotting.')

