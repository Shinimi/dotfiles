#!/usr/bin/env bash
# Clean mic (RNNoise) + Headset EQ presets. Switching the mic also moves apps that are recording (calls). Made by Claude.
#   audio-fx.sh mic on|off       audio-fx.sh eq on|off       audio-fx.sh preset flat|music|games|vocal|bass
#   audio-fx.sh troll on|off|toggle   audio-fx.sh voice demon|chipmunk|robot|alien|radio|glitch   (the Troll mic)
#   audio-fx.sh status (JSON)    audio-fx.sh restore (re-apply saved state, used at login)
ST="$HOME/.local/state/audio-fx.json"
HEADSET_OUT="alsa_output.usb-XiiSound_Technology_Corporation_Fuxi-H3-00.playback.0.0"
HEADSET_IN="alsa_input.usb-XiiSound_Technology_Corporation_Fuxi-H3-00.capture.0.0"
[ -f "$ST" ] || echo '{"mic":false,"eq":false,"preset":"flat"}' > "$ST"
python3 -I -c "import json;d=json.load(open('$ST'));d.setdefault('troll',False);d.setdefault('voice','demon');json.dump(d,open('$ST','w'))"
get() { python3 -I -c "import json;print(str(json.load(open('$ST'))['$1']).lower())"; }
put() { python3 -I -c "import json;d=json.load(open('$ST'));v='$2';d['$1']=(v=='true') if v in('true','false') else v;json.dump(d,open('$ST','w'))"; }
node_id() { pw-dump 2>/dev/null | python3 -I -c "import json,sys;print(next((o['id'] for o in json.load(sys.stdin) if o.get('info',{}).get('props',{}).get('node.name')=='$1'),''))"; }
# move everything that's recording right now (calls too) to a mic, except the filters' own inputs
move_rec() {
  pactl -f json list source-outputs 2>/dev/null | python3 -I -c "
import json,sys
for o in json.load(sys.stdin):
    if not o.get('properties',{}).get('node.name','').startswith('effect_input.'): print(o['index'])" | while read -r id; do pactl move-source-output "$id" "$1" 2>/dev/null; done
}
apply_voice() {   # pitch, ring depth/Hz, bits, rate, drive, gsm mix/passes/errors, highpass, lowpass
  case "$1" in
    demon)    v=(0.62 0 50  24 48000 1.6 0 1 0   20  20000) ;;   # very deep, a bit of grit
    chipmunk) v=(1.75 0 50  24 48000 1.0 0 1 0   20  20000) ;;   # very high
    robot)    v=(1.0  2 45  12 24000 1.2 0 1 0   80  9000)  ;;   # ring-modulated, metallic
    alien)    v=(1.35 1 160 24 48000 1.0 0 1 0   120 12000) ;;   # high and wobbly
    radio)    v=(1.0  0 50  8  11025 2.6 0 1 0   600 3400)  ;;   # old walkie-talkie
    glitch)   v=(1.0  0 50  6  8000  1.4 1 3 40  200 4000)  ;;   # breaking-up internet call
    *) return 1 ;;
  esac
  id=$(node_id troll_mic); [ -n "$id" ] || return 1
  pw-cli s "$id" Props "{ params = [ \"pitch:Pitch co-efficient\" ${v[0]} \"ring:Modulation depth (0=none, 1=AM, 2=RM)\" ${v[1]} \"ring:Frequency (Hz)\" ${v[2]} \"crush:Bit depth\" ${v[3]} \"crush:Sample rate (Hz)\" ${v[4]} \"drive:Drive level\" ${v[5]} \"gsm:Dry/wet mix\" ${v[6]} \"gsm:Number of passes\" ${v[7]} \"gsm:Error rate (bits/block)\" ${v[8]} \"hp:Freq\" ${v[9]} \"lp:Freq\" ${v[10]} ] }" >/dev/null
}
normal_mic() { [ "$(get mic)" = true ] && echo clean_mic || echo "$HEADSET_IN"; }
eq_id() { pw-dump 2>/dev/null | python3 -I -c "import json,sys;print(next((o['id'] for o in json.load(sys.stdin) if o.get('info',{}).get('props',{}).get('node.name')=='headset_eq'),''))"; }
apply_preset() {
  # gentle curves; pre-gain = minus the biggest boost, so nothing ever clips
  case "$1" in            #    105sh  250   1k   3k  6.5k  10ksh  pre-gain
    music) g=(3   -1    0   1   -1.5  1.5  0.67) ;;   # warm, Harman-like: fuller bass, tamed harshness, a bit of air
    games) g=(-2  -1.5  0   2.5  1    1    0.71) ;;   # footsteps/voices forward, boom cut
    vocal) g=(-1.5 -2   1   2   -1    0.5  0.71) ;;   # voices/podcasts/calls: clear mids, less mud
    bass)  g=(5.5 -1    0   0.5  0    1    0.52) ;;   # deep bass without muddying the mids
    *)     g=(0   0     0   0    0    0    1.0) ;;
  esac
  id=$(eq_id); [ -n "$id" ] || return 1
  pw-cli s "$id" Props "{ params = [ \"low:Gain\" ${g[0]} \"lowmid:Gain\" ${g[1]} \"mid:Gain\" ${g[2]} \"upmid:Gain\" ${g[3]} \"pres:Gain\" ${g[4]} \"high:Gain\" ${g[5]} \"pre:Mult\" ${g[6]} ] }" >/dev/null
}
case "$1" in
  mic)    to=$([ "$2" = on ] && echo clean_mic || echo "$HEADSET_IN")
          put mic $([ "$2" = on ] && echo true || echo false)
          [ "$(get troll)" = true ] && exit 0      # the Troll mic stays on top; this only changes what's under it
          pactl set-default-source "$to"; move_rec "$to" ;;
  eq)     [ "$2" = on ] && pactl set-default-sink headset_eq || pactl set-default-sink "$HEADSET_OUT"; put eq $([ "$2" = on ] && echo true || echo false) ;;
  preset) apply_preset "$2" && put preset "$2" ;;
  voice)  apply_voice "$2" && put voice "$2" ;;
  troll)
    want="$2"; [ "$want" = toggle ] && { [ "$(get troll)" = true ] && want=off || want=on; }
    if [ "$want" = on ]; then apply_voice "$(get voice)"; pactl set-default-source troll_mic; move_rec troll_mic; put troll true
    else to=$(normal_mic); pactl set-default-source "$to"; move_rec "$to"; put troll false; fi ;;
  status) cat "$ST" ;;
  restore)
    for i in $(seq 1 20); do [ -n "$(eq_id)" ] && break; sleep 1; done
    apply_preset "$(get preset)"
    [ "$(get mic)" = true ] && pactl set-default-source clean_mic
    [ "$(get eq)" = true ] && pactl set-default-sink headset_eq
    for i in $(seq 1 10); do [ -n "$(node_id troll_mic)" ] && break; sleep 1; done
    apply_voice "$(get voice)"
    [ "$(get troll)" = true ] && pactl set-default-source troll_mic
    ;;
esac
