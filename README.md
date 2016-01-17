#A Mini Search Engine

Are you willing to build your own search engine like Google?  

Let's first build a mini search engine in order to understand the  fundamentals of web searching. Some of the steps are universal and need to be performed by any web search engine, such as  web crawling. 
Here, we build our mini search engine step-by-step. The engine is based on Vector Space Model with tf-idf weighting scheme and is implemented in Perl. The main steps of our mini search engine are listed below. 


1.	Web-Crawling:  Automatically retrieves web pages and documents from the web.   
2.	Preprocessing : Clean up the retrieved documents and make it easier for indexing.  
3.	Indexing: Create inverted index for fast searching.   
4.	Query processing: Preprocess query similar to documents.  
5.	Searching and Relevance Ranking:  Given a query, find out the relevant documents and rank them based on some relevance criteria.   
6.	Presentation (display): Show the results to the user along with (optional) relevance score.  
 
 
Please read the document Mini-search-engine-documentation.pdf and readme files available in each folder.

Note:  
 We have to be ethical. When we crawl someone else's website, we should keep some delay in between subsequent requests. Also, first read robot.txt page of each web directory and do not crawl pages or directories explicitly mentioned in that file.


Thanks!  

Rajendra
