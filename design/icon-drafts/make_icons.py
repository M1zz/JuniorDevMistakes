import json
# 공통 기하: 여백을 두고(15~85), 체크가 주인공
def glyph(p, bracket, slash, check_fill, glow, bracket_op=1, slash_op=.55):
    return f'''
  <g fill="none" stroke-linecap="round" stroke-linejoin="round">
    <polyline points="28,36 16,50 28,64" stroke="{bracket}" stroke-opacity="{bracket_op}" stroke-width="6.5"/>
    <polyline points="72,36 84,50 72,64" stroke="{bracket}" stroke-opacity="{bracket_op}" stroke-width="6.5"/>
    <line x1="58.5" y1="64" x2="66" y2="36" stroke="{slash}" stroke-opacity="{slash_op}" stroke-width="6.5"/>
    {f'<polyline points="34,50.5 41.5,59 54,38" stroke="{glow}" stroke-width="12" filter="url(#{p}blur)" opacity=".75"/>' if glow else ''}
    <polyline points="34,50.5 41.5,59 54,38" stroke="url(#{p}chk)" stroke-width="8.5"/>
  </g>'''
V = {
 'P1': dict(name='미드나잇 터미널', bg=('#2B2B36','#0D0D12'), chk=('#7CF2A0','#22B35E'), glow='#2BD46C', bracket='#FFFFFF', bop=.92, slash='#FFFFFF', sop=.45, hl=.10,
            desc='깊은 남색이 섞인 검정 위에 초록 체크가 은은하게 빛납니다. 어두운 에디터에서 테스트가 통과하는 순간입니다. 슬래시를 반투명하게 눌러서 체크가 먼저 눈에 들어옵니다.'),
 'P2': dict(name='인디고 글로우', bg=('#6158D6','#2A236E'), chk=('#FFC2A8','#FF6B6B'), glow='#FF7A6E', bracket='#FFFFFF', bop=.95, slash='#FFFFFF', sop=.5, hl=.14,
            desc='앱 메인 색 인디고 위에 코랄 체크가 빛납니다. 앱을 열었을 때 화면 색과 그대로 이어집니다.'),
 'P3': dict(name='페이퍼', bg=('#FFFFFF','#ECEAF6'), chk=('#FF8F7A','#E5484D'), glow=None, bracket='#403985', bop=1, slash='#403985', sop=.4, hl=0,
            desc='살짝 라벤더가 도는 흰 종이에 인디고 코드, 코랄 체크입니다. 그림자 없이 가장 깔끔하고, 코드 리뷰에서 빨간 펜으로 체크한 느낌입니다.'),
 'P4': dict(name='선라이즈', bg=('#FFB36B','#F0566A'), chk=('#FFFFFF','#FFE9DC'), glow=None, bracket='#FFFFFF', bop=.95, slash='#FFFFFF', sop=.55, hl=.16,
            desc='코랄에서 주황으로 넘어가는 따뜻한 바탕에 흰 기호만 썼습니다. 밝고 친근해서 홈 화면에서 가장 눈에 띕니다.'),
}
def svg(k,v,standalone=False):
    p=k
    defs=f'''<linearGradient id="{p}bg" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0" stop-color="{v['bg'][0]}"/><stop offset="1" stop-color="{v['bg'][1]}"/></linearGradient>
    <linearGradient id="{p}chk" x1="0" y1="0" x2="0" y2="1" gradientUnits="userSpaceOnUse" x1="0" y1="38" x2="0" y2="60"><stop offset="0" stop-color="{v['chk'][0]}"/><stop offset="1" stop-color="{v['chk'][1]}"/></linearGradient>
    <radialGradient id="{p}hl" cx=".5" cy="0" r=".9"><stop offset="0" stop-color="#FFFFFF" stop-opacity="{v['hl']}"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
    <filter id="{p}blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="3.2"/></filter>'''
    # 중복 속성 정리
    defs=defs.replace('x1="0" y1="0" x2="0" y2="1" gradientUnits','gradientUnits')
    body=f'''<rect width="100" height="100" fill="url(#{p}bg)"/>
  <rect width="100" height="100" fill="url(#{p}hl)"/>{glyph(p,v['bracket'],v['slash'],None,v['glow'],v['bop'],v['sop'])}'''
    if standalone:
        return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="1024" height="1024"><defs>{defs}</defs>{body}</svg>'
    return defs, f'<symbol id="pp{k}" viewBox="0 0 100 100">{body}</symbol>'
out={'defs':'','syms':'','meta':[]}
for k,v in V.items():
    d,s=svg(k,v); out['defs']+=d; out['syms']+=s; out['meta'].append([k,v['name'],v['desc'],v['bg'][1]])
    open(f'{k}.svg','w').write(svg(k,v,True))
json.dump(out,open('parts.json','w'),ensure_ascii=False)
