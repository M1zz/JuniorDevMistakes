# 9차: 새 소재, 플랫. python3 make_v9.py → N1~N6.svg
H='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="1024" height="1024">'
R='stroke-linecap="round" stroke-linejoin="round"'
I={}
# N1 고무 오리: 오리에게 설명하다 보면 버그가 보인다 (러버덕 디버깅)
I['N1']=H+'''<rect width="100" height="100" fill="#2F6BFF"/>
<path d="M30 60 Q30 80 54 80 Q80 80 82 58 Q86 52 82 46 Q78 54 70 54 L44 56 Z" fill="#FFD43B"/>
<circle cx="40" cy="42" r="16" fill="#FFD43B"/>
<path d="M46 62 Q58 58 66 64 Q58 72 48 68 Z" fill="#F2B705"/>
<path d="M24 43 Q16 44 15 48 Q20 52 28 50 Z" fill="#FF7A1A"/>
<circle cx="38" cy="38" r="3" fill="#111111"/>
<rect x="14" y="84" width="72" height="5" rx="2.5" fill="#FFFFFF" opacity=".35"/>
</svg>'''
# N2 안경: 시니어의 상징, 동그란 뿔테
I['N2']=H+f'''<rect width="100" height="100" fill="#FF5A4E"/>
<g fill="none" stroke="#1A1A1A" stroke-width="6" {R}>
<circle cx="31" cy="52" r="15"/><circle cx="69" cy="52" r="15"/>
<path d="M46 50 Q50 45 54 50"/><line x1="16" y1="48" x2="9" y2="42"/><line x1="84" y1="48" x2="91" y2="42"/>
</g>
<g stroke="#FFFFFF" stroke-width="3" {R}><line x1="25" y1="47" x2="30" y2="42"/><line x1="63" y1="47" x2="68" y2="42"/></g>
</svg>'''
# N3 반창고 붙인 버그: 실수(버그)를 고쳐 준다
I['N3']=H+f'''<rect width="100" height="100" fill="#22C55E"/>
<g stroke="#14532D" stroke-width="4.5" {R}>
<line x1="34" y1="44" x2="22" y2="38"/><line x1="33" y1="56" x2="20" y2="56"/><line x1="35" y1="68" x2="23" y2="75"/>
<line x1="66" y1="44" x2="78" y2="38"/><line x1="67" y1="56" x2="80" y2="56"/><line x1="65" y1="68" x2="77" y2="75"/>
<line x1="44" y1="27" x2="38" y2="18"/><line x1="56" y1="27" x2="62" y2="18"/>
</g>
<circle cx="50" cy="33" r="9" fill="#14532D"/>
<ellipse cx="50" cy="58" rx="18" ry="22" fill="#14532D"/>
<g transform="rotate(-35 50 58)">
<rect x="26" y="51" width="48" height="14" rx="7" fill="#FFE2B8"/>
<rect x="42" y="51" width="16" height="14" fill="#F5C68C"/>
<g fill="#E0A766"><circle cx="46" cy="55" r="1.2"/><circle cx="54" cy="55" r="1.2"/><circle cx="46" cy="61" r="1.2"/><circle cx="54" cy="61" r="1.2"/><circle cx="50" cy="58" r="1.2"/></g>
</g>
</svg>'''
# N4 경험치 바: 네 칸 중 세 칸이 찼고, 끝에 별(시니어)
I['N4']=H+'''<rect width="100" height="100" fill="#15122B"/>
<rect x="10" y="41" width="62" height="18" rx="9" fill="none" stroke="#FFFFFF" stroke-width="4"/>
<rect x="15" y="46" width="12" height="8" rx="4" fill="#FF6B5E"/>
<rect x="29" y="46" width="12" height="8" rx="2" fill="#FF6B5E"/>
<rect x="43" y="46" width="12" height="8" rx="2" fill="#FF6B5E"/>
<polygon points="85,37 88.5,46 98,46.5 90.5,52.5 93,62 85,56.5 77,62 79.5,52.5 72,46.5 81.5,46" fill="#FFD43B" transform="translate(1,-1)"/>
</svg>'''
# N5 깃 그래프: 가지를 쳤다가 다시 합쳐지고 위로 자란다
I['N5']=H+f'''<rect width="100" height="100" fill="#5B4BDB"/>
<g transform="translate(6,0)"><g fill="none" stroke="#FFFFFF" stroke-width="6" {R}>
<line x1="38" y1="84" x2="38" y2="22"/>
<path d="M38 70 Q62 66 62 50 Q62 36 38 32"/>
</g>
<g fill="#5B4BDB" stroke="#FFFFFF" stroke-width="5">
<circle cx="38" cy="78" r="6"/><circle cx="62" cy="50" r="6"/>
</g>
<circle cx="38" cy="22" r="9" fill="#3DDC84" stroke="#FFFFFF" stroke-width="5"/>
</g></svg>'''
# N6 픽셀 왕관: 8비트 게임처럼, 시니어 = 왕관
px=["1..1..1",
    "11.1.11",
    "1111111",
    "1111111",
    "1111111"]
cells=''.join(f'<rect x="{18+c*9.14:.2f}" y="{30+r*9.14:.2f}" width="9.3" height="9.3" fill="{"#FFC21A" if ch=="1" else "none"}"/>' for r,row in enumerate(px) for c,ch in enumerate(row) if ch=="1")
gems=''.join(f'<rect x="{18+c*9.14:.2f}" y="{30+3*9.14:.2f}" width="9.3" height="9.3" fill="#FF4D6D"/>' for c in (1,5))+f'<rect x="{18+3*9.14:.2f}" y="{30+3*9.14:.2f}" width="9.3" height="9.3" fill="#2EC4FF"/>'
I['N6']=H+'<rect width="100" height="100" fill="#111111"/>'+cells+gems+'</svg>'
for k,v in I.items(): open(f'{k}.svg','w').write(v)
