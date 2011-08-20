#!/usr/bin/python
import os,sys,time
import lxml.html
import urlparse

time_start = time.time()
book_url = 'http://www.xysa.com/xysafz/book/quansongci/t-index.htm'
save_dir = 'book'

if not os.path.exists(save_dir):
	os.mkdir(save_dir)

html = lxml.html.parse(book_url)
authors = html.xpath('//table[@id="table3"]/tr/td/a')
i = 0
for author in authors:
        name = author.text.encode('utf-8')
        url = author.attrib['href']
        url = urlparse.urljoin(book_url, url)
	#remove posible / from filename
	name = name.replace('/','_')
	i+=1
	f_name = os.path.join(save_dir,'%04d_%s.txt' % (i,name))
	if os.path.exists(f_name):
		continue
        try:
                f = open(f_name, 'w')
		print "Downloading article of %s from %s" % (name, url)
		author_html = lxml.html.parse(url)
		content = author_html.xpath('//table[@id="table4"]/tr/td')[0]
		for c in content:
			if c.text:
				text = c.text.encode('utf-8').strip()
				f.write(text)
				if text != '': f.write('\n\n')
			if c.tail:
				text = c.tail.encode('utf-8').strip()
				f.write(text)
				if text != '': f.write('\n')
        	f.close()
        except IOError as (errno,errstr):
               sys.stderr.write('error downloading %s: %s\n' %(f_name,errstr))

time_end = time.time()
print "*" * 80
print "%d files downloaded in total,time spent %d seconds" % (len(authors),time_end - time_start)
print "*" * 80 
