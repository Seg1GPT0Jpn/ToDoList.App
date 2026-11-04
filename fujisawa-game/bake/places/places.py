import math
PLACES={ # key: (name, lat, lon, radius_m, city)
 'shonandai':('湘南台駅',35.3965,139.4670,450,'f'),
 'honmachi':('藤沢本町駅',35.3480,139.4761,300,'f'),
 'fujisawa':('藤沢駅',35.3388,139.4875,450,'f'),
 'yokohama':('横浜駅',35.4657,139.6223,550,'y'),
 'totsuka':('戸塚駅',35.4009,139.5343,400,'y'),
 'yamato':('大和駅',35.4699,139.4612,350,'o'),
 'kamiooka':('上大岡駅',35.4090,139.5960,350,'y'),
 'mutsuai_es':('六会小学校',35.38889,139.46542,200,'f'),
 'shonandai_jhs':('湘南台中学校',35.39580,139.47216,200,'f'),
 'mutsuai_jhs':('六会中学校',35.38445,139.46659,220,'f'),
 'shonandai_es':('湘南台小学校',35.40136,139.46726,200,'f'),
 'shonandai_hs':('湘南台高校',35.39886,139.45988,230,'f'),
 'shonan_hs':('湘南高校',35.34420,139.47278,240,'f'),
 'akibadai_es':('秋葉台小学校',35.38888,139.44146,200,'f'),
 'akibadai_jhs':('秋葉台中学校',35.38710,139.44421,200,'f'),
}
def mesh3(lat,lon):
    p=int(lat*1.5);u=int(lon-100);a=(lat*1.5-p)*8;q=int(a);b=(lon-100-u)*8;v=int(b);r=int((a-q)*10);w=int((b-v)*10)
    return '%02d%02d%d%d%d%d'%(p,u,q,v,r,w)
def meshes(lat,lon,rad):
    s=set()
    for dy in (-1,-.5,0,.5,1):
        for dx in (-1,-.5,0,.5,1):
            s.add(mesh3(lat+dy*rad/110940,lon+dx*rad/90807))
    return s
