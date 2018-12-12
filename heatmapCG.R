library("ggplot2")
library("reshape")
library("dplyr")
library("plyr")
library("stringr")
library("ggpubr")
library("gridExtra")

cg <- read.csv('/home/cristig/Desktop/ComparativeGenomics/resultsTable.csv', header=TRUE)
cgmelt <- melt(cg)
novel <- cgmelt[grep("Novel",cgmelt$X), ]
loss <- cgmelt[grep("Loss",cgmelt$X), ]
ancestral <- cgmelt[grep("Ancestral",cgmelt$X), ]

ancestral$phylum <- factor(ancestral$variable, c("Hemichordata", "Echinodermata", "Cephalochordata", "Urochordata", "Vertebrata", "Rotifera", "Orthonectida", "Platyhelminthes", "Brachiopoda", "Annelida", "Mollusca", "Nematoda", "Tardigrada", "Arthropoda"))

novel$phylum <- factor(novel$variable, c("Hemichordata", "Echinodermata", "Cephalochordata", "Urochordata", "Vertebrata", "Rotifera", "Orthonectida", "Platyhelminthes", "Brachiopoda", "Annelida", "Mollusca", "Nematoda", "Tardigrada", "Arthropoda"))

loss$phylum <- factor(loss$variable, c("Hemichordata", "Echinodermata", "Cephalochordata", "Urochordata", "Vertebrata", "Rotifera", "Orthonectida", "Platyhelminthes", "Brachiopoda", "Annelida", "Mollusca", "Nematoda", "Tardigrada", "Arthropoda"))

aplot <- ggplot(ancestral, aes(x = ancestral$phylum, y = reorder(ancestral$X, ancestral$value))) + geom_tile(aes(fill=ancestral$value),color = "white") + scale_fill_gradient2(low ="violetred1", mid ="steelblue", high ="yellowgreen", midpoint = 0, space = "Lab", na.value = "grey50", guide = "colourbar")
aplot <- aplot + labs(y = "") + scale_x_discrete(expand = c(0, 0)) + scale_y_discrete(expand = c(0, 0)) + theme(legend.position = "none", axis.ticks = element_blank()) + coord_fixed(ratio=1) + theme(axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.text.y = element_text(size = 14, colour = "grey50")) + theme(plot.margin = unit(c(1,2,0,1), "lines"))
aplot

nplot <- ggplot(novel, aes(novel$phylum,novel$X)) + geom_tile(aes(fill=novel$value), color = "white") + scale_fill_gradient2(low ="violetred1", mid ="steelblue", high ="yellowgreen", midpoint = -1, space = "Lab", na.value = "grey50", guide = "colourbar")
nplot <- nplot + labs(y = "") + scale_x_discrete(expand = c(0, 0)) + scale_y_discrete(expand = c(0, 0)) + theme(legend.position = "none", axis.ticks = element_blank()) + coord_fixed(ratio=1) + theme(axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.text.y = element_text(size = 14, colour = "grey50")) + theme(plot.margin = unit(c(0,2,0,1), "lines"))
nplot

lplot <- ggplot(loss, aes(loss$phylum,loss$X)) + geom_tile(aes(fill=loss$value), color = "white") + scale_fill_gradient2(low ="violetred1", mid ="steelblue", high ="yellowgreen", midpoint = 1, space = "Lab", na.value = "grey50", guide = "colourbar")
lplot <- lplot + labs(x = "", y = "", fill = "") + scale_x_discrete(expand = c(0, 0)) + scale_y_discrete(expand = c(0, 0)) + theme(legend.position = "none", axis.ticks = element_blank(), axis.text.x = element_text(angle = 330, hjust = 0, colour = "grey50", size = 14), axis.text.y = element_text(size = 14, colour = "grey50")) + coord_fixed(ratio=1) + theme(plot.margin = unit(c(0,2,0,1), "lines"))
lplot

p <- grid.arrange(rbind(ggplotGrob(aplot), ggplotGrob(nplot), ggplotGrob(lplot), size="first"))
p
ggsave("heatmapCG.pdf")
