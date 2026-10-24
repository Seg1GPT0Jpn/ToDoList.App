# 音楽理論の計算（問題の正解を計算で求める）
from fractions import Fraction
LET='CDEFGAB'; NAT=[0,2,4,5,7,9,11]
JP={'C':'ハ','D':'ニ','E':'ホ','F':'ヘ','G':'ト','A':'イ','B':'ロ'}
def pc(n): return (NAT[n[0]]+n[1])%12
def de(n):
    l,a=LET[n[0]],n[1]
    if a==0: return 'H' if l=='B' else l
    if a>0: return ('H' if l=='B' else l)+'is'*a
    if l=='B': return 'B' if a==-1 else 'Heses'
    if l=='E': return 'E'+'s'+'es'*(-a-1)
    if l=='A': return 'A'+'s'+'es'*(-a-1)
    return l+'es'*(-a)
def jp(n):
    p={0:'',1:'嬰',2:'重嬰',-1:'変',-2:'重変'}[n[1]]
    return p+JP[LET[n[0]]]
def it(n):
    name=['ド','レ','ミ','ファ','ソ','ラ','シ'][n[0]]
    return name+{0:'',1:'♯',2:'𝄪',-1:'♭',-2:'𝄫'}[n[1]]
def parse(s):
    # ドイツ音名 → (letter, acc)
    base={'C':0,'D':1,'E':2,'F':3,'G':4,'A':5,'H':6}
    if s=='B': return (6,-1)
    if s=='Es': return (2,-1)
    if s=='As': return (5,-1)
    l=base[s[0]]; rest=s[1:]; a=rest.count('is')-rest.count('es')
    return (l,a)
def step(n,semi):
    l=(n[0]+1)%7; want=(pc(n)+semi)%12; a=(want-NAT[l])%12
    if a>6: a-=12
    return (l,a)
def scale(t,minor=False,kind='natural'):
    pat=[2,1,2,2,1,2,2] if minor else [2,2,1,2,2,2,1]
    s=[t]
    for x in pat[:-1]: s.append(step(s[-1],x))
    if minor and kind in('harmonic','melodic'):
        s[6]=(s[6][0],s[6][1]+1)
    if minor and kind=='melodic':
        s[5]=(s[5][0],s[5][1]+1)
    return s
PERF={1:0,4:5,5:7,8:12}; MAJ={2:2,3:4,6:9,7:11}
def interval(a,b,octave=False):
    deg=(b[0]-a[0])%7+1
    if deg==1 and octave: deg=8
    semi=(pc(b)-pc(a))%12
    if deg==8: semi+=12 if semi<6 else 0
    if deg in PERF:
        d=semi-PERF[deg]
        if d>6: d-=12
        if d<-6: d+=12
        q={-2:'重減',-1:'減',0:'完全',1:'増',2:'重増'}.get(d)
    else:
        d=semi-MAJ[deg]
        if d>6: d-=12
        if d<-6: d+=12
        q={-3:'重減',-2:'減',-1:'短',0:'長',1:'増',2:'重増'}.get(d)
    return (q+str(deg)+'度') if q else None
def consonance(name):
    q=name[:-2] if name[-2:]=='度' else name
    if name in('完全1度','完全8度'): return '完全協和音程'
    if name in('完全4度','完全5度'): return '完全協和音程'
    if name in('長3度','短3度','長6度','短6度'): return '不完全協和音程'
    return '不協和音程'
MAJ_SHARP=['C','G','D','A','E','H','Fis','Cis']; MAJ_FLAT=['C','F','B','Es','As','Des','Ges','Ces']
MIN_SHARP=['a','e','h','fis','cis','gis','dis','ais']; MIN_FLAT=['a','d','g','c','f','b','es','as']
def keyjp(name,minor):
    n=parse(name[0].upper()+name[1:])
    return jp(n)+('短調' if minor else '長調')
def keyde(name,minor): return (name.lower() if minor else name)+(' moll' if minor else ' dur')
def keys():
    out=[]
    for i,k in enumerate(MAJ_SHARP): out.append((k,False,i,'♯'))
    for i,k in enumerate(MAJ_FLAT[1:],1): out.append((k,False,i,'♭'))
    for i,k in enumerate(MIN_SHARP): out.append((k,True,i,'♯'))
    for i,k in enumerate(MIN_FLAT[1:],1): out.append((k,True,i,'♭'))
    return out
def sig(k):
    _,_,n,s=k
    return '調号なし' if n==0 else f'{s}{n}個'
def tonic(k): return parse(k[0][0].upper()+k[0][1:])
def triad(notes):
    a=(pc(notes[1])-pc(notes[0]))%12; b=(pc(notes[2])-pc(notes[1]))%12
    return {(4,3):'長三和音',(3,4):'短三和音',(3,3):'減三和音',(4,4):'増三和音'}.get((a,b))
def frac(x):
    x=Fraction(x)
    return str(x.numerator) if x.denominator==1 else f'{x.numerator}/{x.denominator}'
