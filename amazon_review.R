
install.packages("rJava")  

library(rJava)
library(tm)		# load all required packages, install if not loaded
library(SnowballC)
library(wordcloud)
library(RWeka)	
library(qdap)		
library(textir)
library(igraph)
library(maptpx)
makewordc = function(a){	# plot wordcloud func opens
  
a.colsum = apply(a, 2, sum);
  
min1 = min(150, length(a.colsum))	# no more than 150 terms in wordcloud
  
words = colnames(a)[1:min1]
  
freq = a.colsum*100
  
wordcloud(words, freq, scale=c(8, 0.3), colors=1:10)	} # func ends

# --- func to make cluster dendograms --- #

clusdend = function(a){	# writing func clusdend() 	
  
  mydata.df = as.data.frame(inspect(a));	
  
  mydata1.df = mydata.df[, order(-colSums(mydata.df))];
  
  min1 = min(ncol(mydata.df), 40) 	# minimum dimn of dist matrix
  
  test = matrix(0,min1,min1)
  
  test1 = test
  
  for(i1 in 1:(min1-1)){ 
    
    for(i2 in i1:min1){
      
      test = sum(mydata1.df[ ,i1]-mydata1.df[ ,i2])^2
      
      test1[i1,i2] = test; test1[i2, i1] = test1[i1, i2] 	}
    
  }
  
  # making dissimilarity matrix out of the freq one
  
  test2 = test1
  
  rownames(test2) = colnames(mydata1.df)[1:min1]
  
  # now plot collocation dendogram
  
  d <- dist(test2, method = "euclidean") # distance matrix
  
  fit <- hclust(d, method="ward")
  
  plot(fit) # display dendogram
  
} # clusdend() func ends

### --- Elementary sentiment analysis --- ###

pos=scan(file.choose(), what="character", comment.char=";")	# read-in positive-words.txt

neg=scan(file.choose(), what="character", comment.char=";") 	# read-in negative-words.txt

pos.words=c(pos,"wow", "kudos", "hurray") 			# including our own positive words to the existing list

neg.words = c(neg)

# positive sentiment wordcloud

makeposwordc = function(a){	# plot wordcloud func opens
  
  pos.matches = match(colnames(a), pos.words) 		# match() returns the position of the matched term or NA
  
  pos.matches = !is.na(pos.matches)
  
  b1 = apply(a, 2, sum)[pos.matches];	 b1 = as.data.frame(b1);
  
  colnames(b1) = c("freq");
  
  wordcloud(rownames(b1), b1[,1], scale=c(5, 1), colors=1:10)  	# wordcloud of positive words
  
}	# function ends for positive wordcloud

# negative sentiment wordlist

makenegwordc = function(a){	# plot wordcloud func opens
  
  neg.matches = match(colnames(a), neg.words) 		# match() returns the position of the matched term or NA
  
  neg.matches = !is.na(neg.matches)
  
  b1 = apply(a, 2, sum)[neg.matches];	 b1 = as.data.frame(b1);
  
  colnames(b1) = c("freq");
  
  wordcloud(rownames(b1), b1[,1], scale=c(5, 1), colors=1:10)  	# wordcloud of negative words
  
}	# func ends


### --- making social network of top-40 terms --- ###

semantic.na <- function(dtm1){		# dtm has terms in columns 
  
  dtm1.new = inspect(dtm1[, 1:40]); dim(dtm1.new)	# top-25 tfidf weighted terms
  
  term.adjacency.mat = t(dtm1.new) %*% dtm1.new;
  dim(term.adjacency.mat)
  
  term.adjacency.mat1 = 1*(term.adjacency.mat != 0) 	# adjacency matrix ready
  
  require(igraph)
  
  
  g <- graph.adjacency(term.adjacency.mat, weighted = T, mode = "undirected")
  
  
  g <- simplify(g)
  V(g)$label <- V(g)$name	# set labels and degrees of vertices
  
  V(g)$degree <- degree(g)
  set.seed(1234)
  layout1 <- layout.fruchterman.reingold(g)
  plot(g, layout=layout1)
  
} 


ppl.semantic.na <- function(dtm1, names){		# dtm has terms in columns, names is names list corres to docs
  
  dtm2.new = inspect(dtm1[,]); dim(dtm2.new)	
  
  term.adjacency.mat2 = dtm2.new %*% t(dtm2.new);	dim(term.adjacency.mat2)
  
  if (is.null(names)) {names = seq(1, nrow(term.adjacency.mat2), 1)}
  
  rownames(term.adjacency.mat2) = as.matrix(names)
  colnames(term.adjacency.mat2) = as.matrix(names)
  
  g1 <- graph.adjacency(term.adjacency.mat2, weighted = T, mode = "undirected")
  
  g1 <- simplify(g1)		 # remove loops
  
  V(g1)$label <- V(g1)$name	# set labels and degrees of vertices
  
  V(g1)$degree <- degree(g1)
  
  # -- now the plot itself
  
  set.seed(1234)		# set seed to make the layout reproducible
  
  layout2 <- layout.fruchterman.reingold(g1)
  
  plot(g1, layout=layout2)	# its beautiful, isn't it?
  
} # func ends


x = readLines(file.choose("C:/Users/Monika Raju/Desktop/courseera/udemy/codes/a/reviews"))
length(x)	
x1 = Corpus(VectorSource(x))  	# Constructs a source for a vector as input

x1 = tm_map(x1, stripWhitespace) 	# removes white space
x1 = tm_map(x1, tolower)		# converts to lower case
x1 = tm_map(x1, removePunctuation)	# removes punctuation marks
x1 = tm_map(x1, removeNumbers)		# removes numbers in the documents
x1 = tm_map(x1, removeWords, c(stopwords('english'), "project", "null"))
x1 = tm_map(x1, PlainTextDocument)
ngram <- function(x1) NGramTokenizer(x1, Weka_control(min = 3, max = 3))	
tdm0 <- TermDocumentMatrix(x1, control = list(tokenize = ngram,tolower = TRUE, 
                                              removePunctuation = TRUE,
                                              stripWhitespace = TRUE,
                                              removeNumbers = TRUE,
                                              stopwords = TRUE,
                                              stemDocument = TRUE
))		# patience. Takes a minute.

tdm1 = TermDocumentMatrix(x1, control = list(weighting = function(x) weightTfIdf(x, normalize = FALSE), stopwords = TRUE));
tdm0 = TermDocumentMatrix(x1); 
dim(tdm1)
a0 = NULL;
for (i1 in 1:ncol(tdm0)){ if (sum(tdm0[, i1]) == 0) {a0 = c(a0, i1)} }

length(a0)		# no. of empty docs in the corpus

if (length(a0) >0) { tdm01 = tdm0[, -a0]} else {tdm01 = tdm0};	
dim(tdm01)	# under TF weighing

if (length(a0) >0) { tdm11 = tdm1[, -a0]} else {tdm11 = tdm1};
dim(tdm11)	# under TFIDF weighing
inspect(tdm01[1:5, 1:10])		# to view elements in tdm1, use inspect()
dtm0 = t(tdm01)				# docs are rows and terms are cols

dtm = t(tdm11)					# new dtm with TfIdf weighting

# rearrange terms in descending order of Tf and view

a1 = apply(dtm0, 2, sum);

a2 = sort(a1, decreasing = TRUE, index.return = TRUE)

dtm01 = dtm0[, a2$ix];	inspect(dtm01[1:10, 1:10])

dtm1 = dtm[, a2$ix];	inspect(dtm1[1:10, 1:10])
windows()

makewordc(dtm1)
title(sub = "UNIGRAM - Wordcloud using TFIDF")

windows();	semantic.na(dtm1)

windows();	clusdend(dtm01)

windows();	makeposwordc(dtm1)
title(sub = "UNIGRAM - POSITIVE Wordcloud using TFIDF")

windows();	makenegwordc(dtm1)
title(sub = "UNIGRAM - NEGATIVE Wordcloud using TFIDF")


  
  
  