#!/usr/bin/env python
# --------------------------------------------------------------------------------------------
#
#  listold.py:  Provided a source directory, listold.py will recursively list all files older  
#				than the provided date and output to  a csv formatted file.
#
# --------------------------------------------------------------------------------------------
#
#__author__  = "Eric Anderson"
#__created__ = "10/14/2017"
#__version__ = "1.0.1"
#
# Usage: 	'listold.py -p <directory> -d <date> -o <outputfile>'
#         	directory = source directory
#		  	date 		= search for files older than this date
#			outputfile 	= the fully qualified output csv filename e.g. "c:\temp\results.csv"
#
#=============================================================================================
import csv, datetime, time, getopt, os, sys

def validate(date): 
    try:
        return datetime.datetime.strptime(date, '%Y-%m-%d').date()
    except ValueError:
        return 
		
def main(argv):
	START_T = time.time()
	SRC_DIR = os.getcwd()
	CSVFILE = 'results.txt'
	OLDER_T = datetime.datetime.now().strftime ("%Y%m%d")

	# PARSE INPUT PARAMETERS
	try:
		opts, args = getopt.getopt(sys.argv[1:],"hp:d:o:")
	except getopt.GetoptError:
		print 'listold.py -p <directory> -d <date> -o <outputfile>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'listold.py -p <directory> -d <date> -o <outputfile>'
			sys.exit()
		elif opt in ("-p"):
			SRC_DIR = arg
		elif opt in ("-o"):
			CSVFILE = arg
		elif opt in ("-d"):
			OLDER_T = validate(arg)
			if not OLDER_T:
					print "Invalid starting date."
					exit
					
	print 'Starting directory is :', SRC_DIR
	print 'For files older than  :', OLDER_T
	print 'Output file is        :', CSVFILE

	# START
	ans = raw_input('Proceed? [y/n] ')
	with open(CSVFILE, "ab") as output:
		csvhead = ["Directory","Name","CreationTime","LastAccesstime","ModifiedTime","Length"]
		writer = csv.writer(output, dialect='excel')
		writer.writerow(csvhead)    
	if (ans=="y") :
		dt=datetime.datetime.strftime(OLDER_T,'%Y%m%d')

		for root, directories, filenames in os.walk(SRC_DIR):
			for directory in directories:
				print os.path.join(root, directory) 
			for filename in filenames: 
				thisfile = os.path.join(root, filename)
				t_created  = time.ctime(os.path.getctime(thisfile))
				if (t_created < OLDER_T):
					print thisfile
				t_accessed = time.ctime(os.stat(thisfile).st_atime)
				t_modified = time.ctime(os.path.getmtime(thisfile))
				n_bytes = os.stat(thisfile).st_size
				csvrow = [root,filename,t_created,t_accessed,t_modified,n_bytes]
				if (
				with open(CSVFILE, "ab") as output:
					writer = csv.writer(output, dialect='excel')
					writer.writerow(csvrow)    
		ttaken = time.time() - START_T
		print "Running time: ", ttaken
if __name__ == "__main__":
	main(sys.argv[1:])
   
	 