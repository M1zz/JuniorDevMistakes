# 8차: 플랫. 그라데이션 · 그림자 · 블러 없음. python3 make_v8.py → F1~F6.svg
H='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="1024" height="1024">'
R='stroke-linecap="round" stroke-linejoin="round" fill="none"'
I={}
# F1 큰 체크: 전기 파랑 바탕에 꽉 찬 흰 체크
I['F1']=H+f'<rect width="100" height="100" fill="#2B3BFF"/><polyline points="22,52 41,71 78,30" stroke="#FFFFFF" stroke-width="15" {R}/></svg>'
# F2 반반: 빨강(실수)과 초록(통과)이 대각선으로 갈리고 흰 체크가 가로지른다
I['F2']=H+f'<rect width="100" height="100" fill="#22C55E"/><polygon points="0,0 100,0 0,100" fill="#FF4D4F"/><polyline points="24,52 41,69 76,32" stroke="#FFFFFF" stroke-width="12" {R}/></svg>'
# F3 터미널: 검정 바탕에 프롬프트 > 와 초록 체크, 깜빡이는 커서
I['F3']=H+f'''<rect width="100" height="100" fill="#111111"/>
<polyline points="20,36 32,48 20,60" stroke="#FFFFFF" stroke-width="7" {R}/>
<polyline points="40,49 49,58 66,37" stroke="#3DDC84" stroke-width="8" {R}/>
<rect x="70" y="58" width="13" height="6" rx="1.5" fill="#FFFFFF"/></svg>'''
# F4 크롭: 화면 밖으로 잘려 나가는 거대한 < > 사이에 체크
I['F4']=H+f'''<rect width="100" height="100" fill="#FFD43B"/>
<polyline points="16,14 -16,50 16,86" stroke="#111111" stroke-width="13" {R}/>
<polyline points="84,14 116,50 84,86" stroke="#111111" stroke-width="13" {R}/>
<polyline points="33,51 45,63 68,36" stroke="#111111" stroke-width="12" {R}/></svg>'''
# F5 체크리스트: 세 줄 중 위 두 줄은 체크 완료, 마지막 줄만 남음
I['F5']=H+f'''<rect width="100" height="100" fill="#5B4BDB"/>
<g {R} stroke-width="5.5">
<polyline points="22,30 27,35 35,25" stroke="#FFB4A8"/><line x1="44" y1="30" x2="78" y2="30" stroke="#FFFFFF" stroke-opacity=".45"/>
<polyline points="22,50 27,55 35,45" stroke="#FFB4A8"/><line x1="44" y1="50" x2="78" y2="50" stroke="#FFFFFF" stroke-opacity=".45"/>
<rect x="21" y="64" width="14" height="14" rx="3.5" stroke="#FFFFFF" stroke-width="4.5"/><line x1="44" y1="71" x2="70" y2="71" stroke="#FFFFFF"/>
</g></svg>'''
# F6 코랄 원: 흰 바탕에 꽉 찬 코랄 원, 그 안에 흰 <V/>
I['F6']=H+f'''<rect width="100" height="100" fill="#FFFFFF"/><circle cx="50" cy="50" r="34" fill="#FF5A5F"/>
<g {R} stroke="#FFFFFF" stroke-width="5">
<polyline points="31,42 24,50 31,58"/><polyline points="69,42 76,50 69,58"/>
<polyline points="35.5,50 41,56 50,42" stroke-width="6"/><line x1="55" y1="58" x2="61" y2="42"/>
</g></svg>'''
for k,v in I.items(): open(f'{k}.svg','w').write(v)
