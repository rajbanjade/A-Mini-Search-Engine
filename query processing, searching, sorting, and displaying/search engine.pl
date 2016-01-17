# Search engine using tf, idf and vector space model
#
# VERSION HISTORY:
# Rajendra Banjade 11/17/2012 
# The University of Memphis, TN, USA 
#

require "stemmer.pl";                 # stem words in query.
#use Data::Dumper;					  # for formatted printing of various datastructures including Hash.

my $docCount = 0;                     # counter for processed files.
my $tokenCount = 0;                   # total number of index terms in the corpus.
my $MAX_DOCUMENTS_TO_DISPLAY = 200;	  # maximum document to display
my $MAX_DOCUMENTS_TO_INDEX = 1500;     # maximum preprocessed documents to index..

my $indexFile = "index-dump.txt";
my $docLenFile = "doc-length-dump.txt";

# main inverted index structure
%indexHash = ();
# hash for storing document vector length.
%docLengthHash = ();
# document frequency hash <token, df>
%dfHash = ();
# idf hash <token, idf>
%idfHash = ();

# relevant document hash
%relevantDocs = ();

# initialize the porter stemmer
&initialise();

print "Content-type: text/html\n\n";
print '<html>';
print '<title> My search engine </title>';
print '<body>';

# module to trim any whitespace in the string. 
sub trim($)
{
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
}

# Populate stop word hash with the list of words from a file.
open(SWFILE, "<../stopwords.txt" )  or die("Failed to read stop word file: stopwords.txt\n");
while (<SWFILE>) {
	my $w = &trim($_);
	$w =~ s/'//;
	$stopWords{$w} = 1;
}
close (SWFILE);

# subroutine to calculate log base 2. log function gives the natural log and
# we apply basic algebra to calculate log base 2.
sub log2($) {
	my $n = shift;
	return log($n)/log(2);
}

my $processedDir = "../processed";

# generates index, tf, idf etc..

sub doIndexing() {
	# For each preprocessed file, iterates over the terms and creates inverted index.   
	my $fileTokenCount = 0;
	opendir(PPDIR, $processedDir) || die "Can't opedir: $!\n";
	while ($file = readdir(PPDIR)) {
		next unless (($file =~ /\.txt+$/));              # skip file that starts with ., some hidden files.
		open (PPFILE, "<$processedDir/$file") ||  die ("Failed to open :$processedDir/$file");

		if ($docCount > $MAX_DOCUMENTS_TO_INDEX) { last; }
		# get the body 
		$fileContent = join (" ", <PPFILE>);       # bring whole content in a single string. 
		my @temp = $fileContent =~ /<body>(.*?)<\/body>/gi; # get the main text..
		$fileContent = shift @temp;

		my @tokens = split /\s+/, $fileContent;    # split by whitespace(s)
		$tokenCount += @tokens;                    # count the tokens.
		$fileTokenCount = @tokens;

		$file =~ s/\.txt//g;					   # just put the document name as id (removing file extension).

		my %uniqueTokens = (); 	
		# foreach token, create/update inverted index. 
		foreach my $token (@tokens) {	
			my %docHash = ();	
			if (exists $indexHash{$token}){
				%docHash = %{$indexHash{$token}};
			}
			# update the term frequency. If hash doesn't contain $file, 
			# it adds and initializes to zero (no need to check explicitly).
			$docHash{$file}++;
			
			# update the index hash as document and/or term frequency hash has been updated.	
			$indexHash{$token} = \%docHash; 
			if (! exists $uniqueTokens{$token}) {
				$uniqueTokens{$token} = 1;
			}
		}
		# normalize the tf
		#
		#foreach my $token (keys %uniqueTokens) {	
		#	my %docHash = %{$indexHash{$token}};
		#	# normalize  dividing by the number of words in the document.
		#	$docHash{$file} /= $fileTokenCount;
		#	
		#	# update the index hash as term frequency hash has been updated.	
		#	$indexHash{$token} = \%docHash; 
		#}
		
		# close the file handler
		close (PPFILE);
		$docCount++;
	}
	closedir(PPDIR);

	# calculate the tf, idf
	foreach my $token (keys %indexHash) {
		my $df =  keys %{$indexHash{$token}};
		$dfHash{$token} = $df;
		#idf is log2(N/n), N - total number of documents and n - document frequency.
		$idfHash{$token} = &log2($docCount/$df);
	}

	# calculate document vector length.
	foreach my $token (keys %indexHash) {
		$idf = $idfHash{$token};
		my %docHash = %{$indexHash{$token}};
		# sum of square of weight of each term in the document vector. 
		# need to calculate the square root of the result (please see the next loop).
		foreach my $docId (keys %docHash) {
			$docLengthHash{$docId} += ($docHash{$docId}*$idf)**2; 
		}
	}
	# take the square root of sum of squares of term weights (calculated above).
	foreach my $docId (keys %docLengthHash){
		$docLengthHash{$docId} = sqrt($docLengthHash{$docId});
	}
}


# =========================== SAVING INDEX DATA ================
sub saveIndexData() {
	open FILE, ">$indexFile";
	foreach my $token (keys %indexHash) {
		my $df = $dfHash{$token};
		my $idf = $idfHash{$token};
		print FILE "<$token $df $idf>";
		foreach my $doc (keys %{$indexHash{$token}}) {
			print FILE "<$doc " . $indexHash{$token}->{$doc}.">";
		}
		print FILE "\n";
	}
	close (FILE);
	open FILE, ">$docLenFile";
	foreach my $docId (keys %docLengthHash) {
		my $dl = $docLengthHash{$docId};
		print FILE "$docId $dl\n";
	}
	close (FILE);
}

# =========================== Loading INDEX DATA ================
sub loadIndexData() {
	my $line = "";
	open IFILE, "<$indexFile";
	foreach $line (<IFILE>){
		my %docHash = ();
		my @items = ();
		my @itemTokens = ();
		@items = $line =~ /<(.*?)>/gi;
		my $item = shift @items;
		@itemTokens = split /\s+/, $item;
		my $token = shift @itemTokens;
		my $df = shift @itemTokens;
		$dfHash{$token} = $df;
		my $idf = shift @itemTokens;
		$idfHash{$token} = $idf;
		foreach $item (@items) {
			@itemTokens = ();
			@itemTokens = split /\s+/, $item;
			my $docId = shift @itemTokens;
			my $wf = shift @itemTokens;
			$docHash{$docId} = $wf;
		}
		$indexHash{$token} = \%docHash;
	}
	close (IFILE);
	open DLFILE, "<$docLenFile";
	foreach $line (<DLFILE>){
		my @kv = ();
		@kv = split /\s+/, $line;
		my $docId = shift @kv;
		my $dlen = shift @kv;
		$docLengthHash{$docId} = $dlen;
	}
	close (DLFILE);
}

#=========== before processing query make sure that indexing has been done.. ===============

if ((-e $indexFile) && (-e $docLenFile)) {
	print "\n Loading index data from file... \n";
	&loadIndexData();
} else {
	print "\n Generating index data.. dump file not found \n";
	&doIndexing();
	&saveIndexData();
}	


####################### Searching ####################################
local ($buffer, @pairs, $pair, $name, $value, %FORM);
    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "GET")
    {
		$buffer = $ENV{'QUERY_STRING'};
    }
    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
		($name, $value) = split(/=/, $pair);
		$value =~ tr/+/ /;
		$value =~ s/%(..)/pack("C", hex($1))/eg;
		$FORM{$name} = $value;
    }
    $queryInput = $FORM{"query-text"};
	$queryInput =~ tr/[A-Z]/[a-z]/;   # change to lowercase
	$queryInput =~ s/[[:punct:]]//;      # remove punctuation
	#$queryInput = "graduate admission";

# query word and frequency.
%queryHash = ();

#candidate list of document (doc id, weight)
%candidateDocs = ();
# ranked documents (doc id, rank)
%rankedDocs = ();

# preprocess and add in the query hash.. 
foreach my $qw (split /\s+/, $queryInput) {
	if (! (exists $stopWords{$qw})){
			$qw = &stem ($qw);
		if($qw){
			$queryHash{$qw}++; 
		}
	}
}
my $querySize = keys %queryHash;	
# normalize..
#my $queryWordCount = keys %queryHash;
#foreach my $qw (keys %queryHash) {
#	$queryHash{$qw} /= $queryWordCount;
#}

# generate the candidate set of documents.
my $totalCandidates = 0;
sub generateCandidateDocs() {
	my $qLength = 0;
	foreach my $qw (keys %queryHash) {
		# if word is not in the vocabulary, skip.
		next unless (exists $indexHash{$qw});  
        #print "\n Query term exists... ";
		my $idf = $idfHash{$qw};
		if ($idf == 0) {next; }
		#Calculate the weight for the query word.. different formula.
		my $qww = (0.5 + 0.5 * $queryHash{$qw}) * $idf; # query word weight.
		
		#print "\n Query words: $qw and weight: $qww";
		
		$qLength += $qww**2;
		my %docHash = %{$indexHash{$qw}}; # documents containing the query word (doc id, tf)
		# for each document, calculate the query weight and 
		foreach my $docId (keys %docHash) {
			$candidateDocs{$docId} += $qww * $idf * $docHash{$docId}; 
			$relevantDocs{$docId}++;
			#print "\n Relevant document... $docId";
		}
	}
	# take the square root of qLength
	$qLength = sqrt($qLength);
	# normalize dividing by the document lengths.
	foreach my $docId (keys %candidateDocs) {
		$totalCandidates++;
		$candidateDocs{$docId} /= $docLengthHash{$docId} * $qLength;
	}
}

# My own way.. determine the number of relevant documents.. To calculate the recall.
my $relDocCount = 0;
my %qSizeDocFrequency = ();  # To find the number of documents containing all the query terms, one less than query size, and so on
print "<br><br><br><br><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  Total query terms (after preprocessing):$querySize</b>"; 
sub calcExpectedRelevantDocs() {
#foreach my $docId (sort {$relevantDocs{$b} <=> $relevantDocs{$a}} keys %relevantDocs) {
	foreach my $docId (keys %relevantDocs){
		my $count = $relevantDocs{$docId};
		#print "\n $docId has $count query terms ";
		$qSizeDocFrequency{$count}++;
	}
	foreach my $ql (keys %qSizeDocFrequency) {
		print "<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <b>".$qSizeDocFrequency{$ql}." documents contain $ql query terms</b>";
		my $dampingFactor = $querySize ** ((($querySize/$ql) - 1) *3);
		$relDocCount += (1/$dampingFactor)*($qSizeDocFrequency{$ql});
	}
	print "<br>";
	$relDocCount = int($relDocCount);
	my $docContaingAllTerms = $qSizeDocFrequency{$querySize};
	$MAX_DOCUMENTS_TO_DISPLAY = int (0.70 * $relDocCount); # retrieve only 90% of the predicted documents.
}

# generate the ranked list of documents (doc id, rank) from the candidate set by filtering out
# based on the threshold
my $totalDisplaying = 0;
sub doRanking() {
	my $counter = 0;
	if ((keys %candidateDocs) > $MAX_DOCUMENTS_TO_DISPLAY) {
		$counter = $MAX_DOCUMENTS_TO_DISPLAY;
	} else {
		$counter = keys %candidateDocs;
	}	
	$totalDisplaying = $counter;
	# sort the documents by the descending order of score	
	foreach my $docId (sort {$candidateDocs{$b} <=> $candidateDocs{$a}} keys %candidateDocs) {
		$rankedDocs{$docId} = $candidateDocs{$docId};
		#$rank++;
		$counter--;
		if($counter == 0) {
			last;
		}
	}
}

&generateCandidateDocs();
&calcExpectedRelevantDocs();
&doRanking();

####################### Printing #######################################

# print the candidate documents.
$localBasePath = "<your server directory>/htdocs";
print "<br> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Total candidate documents = $totalCandidates <br>";
print "<br> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Predicted relevant documents = $relDocCount <br>";
foreach $id (keys %candidateDocs){
	#print "\n$id ". $candidateDocs{$id};
}

# print the ranked documents.
my $rank = 0;
print "<br><br><i>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Showing $totalDisplaying results out of $totalCandidates for your query: $queryInput</i><br>";
foreach my $docId (sort {$rankedDocs{$b} <=> $rankedDocs{$a}} keys %rankedDocs){
	open (PPFILE, "<$processedDir/$docId.txt") ||  die ("Failed to open :$processedDir/$docId.txt");
	my $fileContent = join (" ", <PPFILE>);       # bring whole content in a single string. 
	my @temp = ($fileContent =~ /<title>(.*?)<\/title>/gi);
	my $title = shift @temp; # get title.
	@temp = ($fileContent =~ /<web>(.*?)<\/web>/gi);
	my $webUrl = shift @temp;
	@temp = ($fileContent =~ /<local>(.*?)<\/local>/gi);
	my $localPath = shift @temp; # get the local file path.
	$localPath =~ s/\.\.//;
	$localPath = $localBasePath.$localPath;
	$rank++;
	print "<br><br>&nbsp;&nbsp;&nbsp;$rank&nbsp;&nbsp;<a href=\"$webUrl\">$title</a>";
	print "<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$webUrl <a href=\"$localPath\">Local copy</a>";
	printf (" Score = %.4f", $rankedDocs{$docId});
	close(PPFILE);
}
print '</body>';
print '</html>';

#print Dumper (\%docLengthHash);

# Print the values. We can use Dumper for formatted output but here we want to mix up from different
# hashes for readability and conciseness.
# prints '<token>' df idf { list of <document-id ==> tf> }
=pod
foreach my $token (keys %indexHash) {
	my $df = $dfHash{$token};
	my $idf = $idfHash{$token};
	print "'$token' $df $idf\n		{\n";
	foreach my $doc (keys %{$indexHash{$token}}) {
		print "			$doc => " . $indexHash{$token}->{$doc} . "\n";
	}
	print "\n		}\n";
}

print "\Doc length...";
foreach my $docId (keys %docLengthHash) {
	print "$docId ".$docLengthHash{$docId}."\n";
}


# print the formatted output using Dumper. 
print "\n ======= Document length ============ \n"; 
print Dumper (\%docLengthHash);

# print some statistics
print ("\n\n Total files processed: $docCount , Total token count: $tokenCount, Vocabulary size: ".keys(%indexHash)."\n\n"); 
=cut
