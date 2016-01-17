use LWP::Simple; 				# utility package (use get() to fetch content of url etc).
use CAM::PDF;                   # to process pdf files.
use CAM::PDF::PageText;         # for pdf to text conversion.

my $link = "http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/PageRankFranceschet.pdf";  #IR course homepage.
my $tempPdfFile = "temp.pdf";

		$pageContent = get ($link) || next;             # fetch the pdf content, otherwise skip.	
		next unless (open (TEMPFILE, ">$tempPdfFile")); # if can't create temp file, just skip that pdf.
		binmode(TEMPFILE); 		                        # pdf must be saved as binary file !!!
		print TEMPFILE $pageContent;                    
		close (TEMPFILE);
		#my $pdf = CAM::PDF->new($tempPdfFile);           # read pdf file.
		#my $pageCount = $pdf->numPages();                # get number of pages
		#next unless (open (TEMPFILE, ">$tempTextFile")); # if can't create temp file, just skip that pdf.
		# Convert each pdf page to txt and Append to.
		#foreach my $pageNum (1..$pageCount) {
		#	my $page = $pdf->getPageContentTree($pageNum);
		#	print TEMPFILE CAM::PDF::PageText->render($page);
		#}
		#close (TEMPFILE);