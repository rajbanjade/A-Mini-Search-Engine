########################################################################################
# Assignment: 4
# Does some preprocessing on different web page contents crawled and saved in a folder.
# Removes the following during the preprocessing:
#	- digits
#	- punctuation
#	- stop words (use the generic list available at ...ir-websearch/papers/english.stopwords.txt)
#	- urls and other html-like strings
#	- uppercases
#	- morphological variations 
#
# VERSION HISTORY:
# Rajendra Banjade 10/5/2012 
# 
require "stemmer.pl";                             # porter stemmer (http://tartarus.org/~martin/PorterStemmer/)

my $preprocessedPageCount = 0;                    # counter for preprocessed pages.
my $tokenCount = 0;                               # total number of tokens found
my $wordCount = 0;                                # total number of words remained (after removing stop words etc). 

# stop words hash
%stopWords = {};

# initialize the porter stemmer
&initialise();

# module to trim any whitespace in the string. 
sub trim($)
{
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
}

# Populate stop word hash with the list of words from a file.
open(SWFILE, "<stopwords.txt" )  or die("Failed to read stop word file: stopwords.txt\n");
while (<SWFILE>) {
	$stopWords{&trim($_)} = 1;
}
close (SWFILE);

# For each raw file, remove links and html tags, stopwords, punctuation etc. And save to a file (if anything remains).   
opendir(RAWDIR, "raw") || die "Can't opedir: $!\n";
while (readdir(RAWDIR)) {
	$file = ($_);
	next unless (!($file =~ /^\./));              # skip file that starts with ., some hidden files.
	open (RAWFILE, "<raw/$file") || die ("Failed to ope :raw/$file");

	# open a file in the preprocessed folder for each raw file and write the preprocessed texts.
	open (OUTFILE, ">preprocessed/$file") || die ("Failed to create output file:  $preprocessed/$file");
	
	$fileContent = join (" ", <RAWFILE>);       # bring whole content in a single string. Processing linewise can be difficult while applying regular expressin.

	$fileContent =~ s/\s+/ /g;                  # replace any sequence of whitespaces by a single whitespace (for easy split)
	$fileContent =~ s/<.+?>//g;                    # remove valid html tags (opening | closing), do shortest match (?).
	$fileContent =~ s/[0-9]+//g;                   # remove any digits
	$fileContent =~ tr/[A-Z]/[a-z]/;               # change everything to lowercase
    $fileContent =~ s/&nbsp;//g;                   # remove nbsp;
	$fileContent =~ s/(http:\/\/|ftp:\/\/)?(\.?\w+-*\w+)+\.(com|net|org|gov|edu)\/*//gi; # remove urls in text, <taken from web>.
	$fileContent =~ s/mailto://g;                  # remove mailto:
	#$fileContent =~ s/(.+)@(.+)\.(.{2,4})?//g;     # simple regex to remove some email addresses, maynot match all email addresses.
	$fileContent =~ s/[[:punct:]]/ /g;	           # remove puncutation
	$fileContent =~ s/[‘|’|“|”]?//g;               # remove quotes, they are still there.
	my @tokens = split /\s+/, $fileContent;        # split by whitespace(s)
	$tokenCount += @tokens;                        # these are the tokens (before removing stop words)
	
	my @words = ();                                # array that contains index words.
	# foreach token, do not add to index words if it is an stopword. 
	foreach $word (@tokens) {			    # Case sensitive, match.
		if (! (exists $stopWords{$word})){
			$word = &stem ($word);
			#$word =~ s/'//g;				# remove apostrophe
			if($word){
				push @words, $word;
			}
		}
	}
	if (@words >0) {
		print OUTFILE join(" ", @words ) . "\n";   # write line to file
	}

	$preprocessedPageCount++;
	close (RAWFILE);
	close (OUTFILE);
}
closedir(RAWDIR);

# print some statistics
print ("\n\n Total files processed: $preprocessedPageCount , Total word count: $tokenCount. \n\n"); 
