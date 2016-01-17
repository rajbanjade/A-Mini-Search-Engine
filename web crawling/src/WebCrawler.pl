########################################################################################
# Displays the vocabulary and frequency of each word in the main page of the given page and
# on all other documents directly linked from it. For each word, also computes 
# how many different documents it occurs in the collection. 
#
# VERSION HISTORY:
# Rajendra Banjade 9/26/2012 
# The University of Memphis, Tennessee, USA
# 

use LWP::Simple; 				# utility package (use get() to fetch content of url etc).
use CAM::PDF;                   # to process pdf files.
use CAM::PDF::PageText;         # for pdf to text conversion.

$baseUrl = "http://www.<your provide a link to a page>/";  #

$homePageContent = get($baseUrl) || die "\nCouldn't fetch $baseUrl\n";  # first fetch the home page content.

my @links = $homePageContent =~ /href="(.*?)"/gi; # get all (g) the url's the page linked to.
my $crawledPageCount = 0;                         # counter for pages crawled (not all links be crawled - duplication, anchor links etc).  
my $wordCount = 0;                                # total number of words found. 
my %wordDocFrequencyTable = ();                   # word document frequency table.
my %wordFrequencyTable = ();                      # word frequency table. 
my %uniqueLinkTable = ();                         # unique links crawled. 

# Parses the page content, and counts word frequency & document frequency for each word. 
sub processData{
	my ($pageData, $url) = @_;
	my %tempHash = ();				            # Store words whose document frequency has been updated.

	$pageData =~ s/\s+/ /g;                     # replace any sequence of whitespaces by a single whitespace (for easy split)
	$pageData =~ s/<.+?>//g;                    # remove valid html tags (opening | closing), do shortest match (?).
	my @tokens = split /\s+/, $pageData;        # split by whitespace
	my @words = grep /^[A-Za-z0-9]+$/, @tokens; # get the valid word list
	$wordCount += @words;
	
	#update the word frequency, and document frequency (if needed) tables.
	foreach $word (@words) {					 # Case sensitive, match.
		$wordFrequencyTable{$word}++;
		if (! (exists $tempHash{$word})){
			$wordDocFrequencyTable{$word}++;     # update in the document frequency table.
			$tempHash{$word} = 1;  		         # Flag: Document frequency for this word has been updated.
		}
	}
}

# First process the course home page.
&processData ($homePageContent, $baseUrl);
$uniqueLinkTable{$baseUrl} = 1;                   # mark home page as processed. Avoid potential duplications.
$crawledPageCount++;

# for each link, either discard or get data and process.
foreach $link (@links) {
	next unless (!($link =~ /#|mailto:/));			# if anchor link or email link, just skip.	
	next unless (!($link =~ /\.ppt/));   			# .ppt file, skip it (for now).

	if (!($link =~ /^http\:\/\//)) {                # if relative path, change to absolute. Assume no link to secure (https) pages
		$link = $baseUrl.$link;
	}
	
	next unless (! (exists $uniqueLinkTable{$link}));   # Avoid redundant processing (i.e. Already processed link, skip it)
	
	# Handle different type of files differently (.pdf,.html etc).
	if ($link =~ /\.pdf/){
		my $tempPdfFile = "temp.pdf";                   # temporary pdf dump file.
		my $tempTextFile = "temp.txt";                  # temporary file for pdf to .txt  
		$pageContent = get ($link) || next;             # fetch the pdf content, otherwise skip.	
		next unless (open (TEMPFILE, ">$tempPdfFile")); # if can't create temp file, just skip that pdf.
		binmode(TEMPFILE); 		                        # pdf must be saved as binary file !!!
		print TEMPFILE $pageContent;                    
		close (TEMPFILE);
		my $pdf = CAM::PDF->new($tempPdfFile);           # read pdf file.
		my $pageCount = $pdf->numPages();                # get number of pages
		next unless (open (TEMPFILE, ">$tempTextFile")); # if can't create temp file, just skip that pdf.
		# Convert each pdf page to txt and Append to.
		foreach my $pageNum (1..$pageCount) {
			my $page = $pdf->getPageContentTree($pageNum);
			print TEMPFILE CAM::PDF::PageText->render($page);
		}
		close (TEMPFILE);
		next unless (open (TEMPFILE, "<$tempTextFile")); # if can't read converted text, just skip that pdf.
		my @content = <TEMPFILE>;
		$pageContent = join " ",@content;   # change to single string (space separated for each line).
											# Just to process like other HTML page's content.
		close (TEMPFILE);
		#remove temp (.pdf and .txt) files.
		unlink($tempPdfFile);
		unlink($tempTextFile);
	} else {
		$pageContent = get ($link) || next;  # otherwise, assume the page is html and fetch it.
	}
	&processData ($pageContent, $link);      # Process the page data. 
	$uniqueLinkTable{$link} = 1;             # mark as processed.
	$crawledPageCount++;
}

# print crawled page urls (some converted to absolute though they were originally relative to the course home page)
print ("\n ======== Crawled page urls ====== \n");
my $count = 0;
foreach $url (sort keys %uniqueLinkTable ){ 
	$count++;
	print ("\n$count> $url"); 
}

# sort in the alphabetical order and display word frequency table.
print ("\n\n ===  Word => Frequency table === \n");
foreach $word (sort keys %wordFrequencyTable ){ 
	print ("\n$word ----> $wordFrequencyTable{$word}"); 
}

# Sort words in the alphabetical order and print document frequency table.
print ("\n ===  Word => Document frequency table === \n");
foreach $word (sort keys %wordDocFrequencyTable ){ 
	print ("\n$word ----> $wordDocFrequencyTable{$word}"); 
}

# print some statistics
print ("\n\n Total pages crawled: $crawledPageCount , Total word count: $wordCount , Unique word count: ".keys(%wordFrequencyTable). "\n\n"); 
