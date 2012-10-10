from HTMLParser import HTMLParser

class MLStripper(HTMLParser):
    def __init__(self):
        self.reset()
        self.fed = []
    def handle_data(self, d):
        self.fed.append(d)
    def get_data(self):
        return ''.join(self.fed)

def strip_tags(html):
    s = MLStripper()
    s.feed(html)
    return s.get_data()
    
#import re
#r = re.compile('\(.*Bolet(.*\d*\.{0,1}\d+-\d+)*.*\)')
#import urllib
#file = urllib.urlopen("http://www.senado.cl/appsenado/index.php?mo=sesionessala&ac=getDoctoSesion&iddocto=35414")
#html = ""
#for line in file:
	#html += line
#import MLStripper
#clean = MLStripper.strip_tags(html)
#bills = r.findall(clean)
#
