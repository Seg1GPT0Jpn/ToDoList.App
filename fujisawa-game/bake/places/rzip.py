import io,zipfile,urllib.request,sys,os
class HF(io.RawIOBase):
    def __init__(s,url):
        s.url=url;s.pos=0
        r=urllib.request.urlopen(urllib.request.Request(url,method='HEAD'));s.size=int(r.headers['Content-Length'])
    def seekable(s):return True
    def readable(s):return True
    def tell(s):return s.pos
    def seek(s,o,w=0):
        s.pos=o if w==0 else s.pos+o if w==1 else s.size+o;return s.pos
    def read(s,n=-1):
        if n<0:n=s.size-s.pos
        if n==0 or s.pos>=s.size:return b''
        e=min(s.size,s.pos+n)-1
        for a in range(5):
            try:
                r=urllib.request.urlopen(urllib.request.Request(s.url,headers={'Range':'bytes=%d-%d'%(s.pos,e)}),timeout=120);d=r.read();break
            except Exception as ex: print('retry',ex,file=sys.stderr)
        s.pos+=len(d);return d
    def readinto(s,b):
        d=s.read(len(b));b[:len(d)]=d;return len(d)
def open_zip(url):return zipfile.ZipFile(io.BufferedReader(HF(url),buffer_size=1<<20))
if __name__=='__main__':
    z=open_zip(sys.argv[1])
    for i in z.infolist():
        if sys.argv[2] in i.filename: print(i.filename,i.file_size,i.compress_size)
