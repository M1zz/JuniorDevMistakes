# 7차: 쌈뽕 버전. python3 make_v7.py → K1~K4.svg
H='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="1024" height="1024">'
icons={}

# K1 키캡: 기계식 키보드 키 하나에 체크
icons['K1']=H+'''<defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6A5CF0"/><stop offset="1" stop-color="#2A1F7A"/></linearGradient>
<linearGradient id="side" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9E7F2"/><stop offset="1" stop-color="#A9A5BF"/></linearGradient>
<linearGradient id="top" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEAF5"/></linearGradient>
<linearGradient id="chk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5BE38A"/><stop offset="1" stop-color="#16A34A"/></linearGradient>
<filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feGaussianBlur stdDeviation="3.5"/></filter>
</defs>
<rect width="100" height="100" fill="url(#bg)"/>
<rect x="18" y="26" width="64" height="62" rx="13" fill="#140E40" opacity=".55" filter="url(#sh)"/>
<rect x="17" y="17" width="66" height="66" rx="14" fill="url(#side)"/>
<rect x="23" y="19" width="54" height="52" rx="10" fill="url(#top)"/>
<rect x="23" y="19" width="54" height="52" rx="10" fill="none" stroke="#FFFFFF" stroke-width="1"/>
<g fill="none" stroke="#6B6688" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><polyline points="31,25 28,28.5 31,32"/><line x1="33" y1="32.5" x2="35.5" y2="24.5"/><polyline points="37.5,25 40.5,28.5 37.5,32"/></g>
<polyline points="38,48 47,57 64,35" fill="none" stroke="#0F7A36" stroke-opacity=".25" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" transform="translate(0,1.6)"/>
<polyline points="38,48 47,57 64,35" fill="none" stroke="url(#chk)" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
</svg>'''

# K2 네온: 어두운 벽에 네온 </> 와 체크
def neon(el,color,w):
    return (f'<g filter="url(#glowW)" opacity=".9">{el.format(c=color,w=w+6)}</g>'
            f'<g filter="url(#glowN)">{el.format(c=color,w=w+1.5)}</g>'
            f'{el.format(c="#FFFFFF",w=w*0.42)}')
lt='<polyline points="27,35 14,50 27,65" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
gt='<polyline points="73,35 86,50 73,65" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
sl='<line x1="57" y1="66" x2="65" y2="34" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
ck='<polyline points="33,50 41,59 53,37" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
icons['K2']=H+'''<defs>
<radialGradient id="bg" cx=".5" cy=".45" r=".75"><stop offset="0" stop-color="#1E1438"/><stop offset="1" stop-color="#07050F"/></radialGradient>
<filter id="glowW" filterUnits="userSpaceOnUse" x="0" y="0" width="100" height="100"><feGaussianBlur stdDeviation="4"/></filter>
<filter id="glowN" filterUnits="userSpaceOnUse" x="0" y="0" width="100" height="100"><feGaussianBlur stdDeviation="1.2"/></filter>
</defs>
<rect width="100" height="100" fill="url(#bg)"/>'''+neon(lt,'#2EE6FF',4.5)+neon(gt,'#2EE6FF',4.5)+neon(sl,'#B57BFF',4)+neon(ck,'#FF3D9A',5.5)+'</svg>'

# K3 리퀴드 글래스: 번지는 색 위에 유리 카드
icons['K3']=H+'''<defs>
<filter id="blob" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="9"/></filter>
<filter id="sh" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.5"/></filter>
<linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".18"/></linearGradient>
<linearGradient id="rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".95"/><stop offset=".5" stop-color="#FFFFFF" stop-opacity=".2"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".6"/></linearGradient>
</defs>
<rect width="100" height="100" fill="#3B2DB8"/>
<g filter="url(#blob)">
<circle cx="22" cy="24" r="30" fill="#FF6B8B"/>
<circle cx="84" cy="30" r="26" fill="#FFB547"/>
<circle cx="74" cy="86" r="32" fill="#22D3EE"/>
<circle cx="18" cy="88" r="22" fill="#7C5CFF"/>
</g>
<rect x="19" y="22" width="62" height="62" rx="16" fill="#1A1060" opacity=".25" filter="url(#sh)"/>
<rect x="19" y="19" width="62" height="62" rx="16" fill="url(#glass)"/>
<rect x="19.5" y="19.5" width="61" height="61" rx="15.5" fill="none" stroke="url(#rim)" stroke-width="1.2"/>
<g fill="none" stroke="#FFFFFF" stroke-linecap="round" stroke-linejoin="round">
<polyline points="34,40 27,50 34,60" stroke-width="4.5"/>
<polyline points="66,40 73,50 66,60" stroke-width="4.5"/>
<polyline points="38.5,50 44.5,57 55,41" stroke-width="6.5"/>
<line x1="56.5" y1="61" x2="61" y2="40" stroke-width="4.5" stroke-opacity=".6"/>
</g>
</svg>'''

# K4 레벨업: 체크의 긴 획이 위로 솟는 화살표가 된다 + 롱 섀도
shape=('<polyline points="24,54 39,69 74,28" fill="none" stroke="{c}" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/>'
       '<polygon points="79.2,21.9 79.0,37.5 63.8,24.5" fill="{c}" stroke="{c}" stroke-width="3" stroke-linejoin="round"/>')
shadow=''.join(f'<g transform="translate({i*0.8},{i*0.8})" opacity="{0.22*(1-i/45):.3f}">'+shape.format(c="#9E1B3A")+'</g>' for i in range(1,45))
icons['K4']=H+'''<defs>
<linearGradient id="bg" x1="0" y1="1" x2="1" y2="0"><stop offset="0" stop-color="#FF4D6D"/><stop offset=".55" stop-color="#FF7A45"/><stop offset="1" stop-color="#FFC24B"/></linearGradient>
</defs>
<rect width="100" height="100" fill="url(#bg)"/>'''+shadow+shape.format(c="#FFFFFF")+'</svg>'

for k,v in icons.items(): open(f'{k}.svg','w').write(v)
