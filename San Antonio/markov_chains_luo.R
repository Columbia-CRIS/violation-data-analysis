rm(list=ls())

# initialize ----
require(dplyr)
require(plyr)
require(markovchain)
require(reshape)
setwd("~/Git/violation-data-analysis")
if(!exists("complete.active.quarters")){load("./San Antonio/output/result.RData")}

# clustering ----
temp <- complete.active.quarters %>% filter(active==TRUE)
set.seed(20)
clustering <- kmeans(temp[, 6:ncol(temp)], 3, nstart=20)
freq_table <- table(clustering$cluster)
print(clustering$centers)
print(clustering$size)

# assign low, mid, high risk labels
risk.labels <- c("low", "mid", "high")
cluster.to.risk.label <- sort.int(clustering$centers[,1], index.return = TRUE)$ix

# Melted format containing quarter-year, mine_id allowing for markov chain analysis ----
temp$cluster <- clustering$cluster
temp$date <- paste(as.character(temp$year), "-" , as.character(temp$quarter))
temp2 <- temp %>% select(mine_id, cluster, date)
melted <- melt(temp2, id=c("mine_id", "date"))
aggregate_cluster_seq <- cast(melted, mine_id~date)

# Markov Chain function ----
markov <- function(x){
  x <- as.integer(x)
  cluster_seq_raw <- x[!is.na(x)]
  if(length(cluster_seq_raw) > 1){
    cluster_sequence <- cluster_seq_raw[2:length(cluster_seq_raw)]
    cur_markov_chain <- createSequenceMatrix(cluster_sequence, sanitize = FALSE)
    return (list("mine_id" = x[1], 
                 "markov_chain" = cur_markov_chain, 
                 "num_rows" = length(cluster_seq_raw),
                 "low" = cluster.to.risk.label[1] %in% cluster_sequence, 
                 "mid" = cluster.to.risk.label[2] %in% cluster_sequence, 
                 "high" = cluster.to.risk.label[3] %in% cluster_sequence
    )
    )
  }
  return (list("mine_id" = x[1], 
               "markov_chain" = NA, 
               "num_rows" = 0,
               "low" = FALSE, "mid" = FALSE, "high" = FALSE
  )
  )
}

# create mine-date transition matrices ----
result<-alply(aggregate_cluster_seq, 1, markov)

# create overall transition matrix ----
markov_chains_ind <- sapply(result, "[[", 2)

#adding matrix of different dimentions, source: http://stackoverflow.com/questions/13571359/join-and-sum-not-compatible-matrices
add_matrices_1 <- function(...) {
  a <- list(...)
  cols <- sort(unique(unlist(lapply(a, colnames))))
  rows <- sort(unique(unlist(lapply(a, rownames))))
  out <- array(0, dim=c(length(rows), length(cols)), dimnames=list(rows,cols))
  for(M in a) { out[rownames(M), colnames(M)] <- out[rownames(M), colnames(M)] + M }
  return(out)
}

final_transition<- matrix(rep(0,times= 9), ncol = 3, nrow = 3)
colnames(final_transition) <- c(1,2,3)
rownames(final_transition) <- c(1,2,3)

for(i in 1:length(markov_chains_ind)){
  final_transition <- add_matrices_1(final_transition,markov_chains_ind[[i]])
}
print("Tranition matrix frequency")
final_transition

final_markov<- matrix(rep(0,times= 9), ncol = 3, nrow = 3)
for(i in 1:3){
  final_markov[i,] <- final_transition[i,]/sum(final_transition[i,])  
}

print("Transition matrix probability")
sorted.final.markov <- final_markov[cluster.to.risk.label, cluster.to.risk.label]
colnames(sorted.final.markov) <- risk.labels
rownames(sorted.final.markov) <- risk.labels
print(sorted.final.markov)

# create Markov chain object
markov.mine <- new("markovchain", states = risk.labels, byrow = TRUE,
                   transitionMatrix = sorted.final.markov, name = "Mine")

save(sorted.final.markov, clustering, markov.mine, 
     risk.labels, cluster.to.risk.label,
     file="./San Antonio/output/results_markov.RData")