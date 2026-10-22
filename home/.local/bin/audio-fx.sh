#!/usr/bin/env bash
# Clean mic (RNNoise) + Headset EQ presets. Made by Claude.
#   audio-fx.sh mic on|off       audio-fx.sh eq on|off       audio-fx.sh preset flat|music|games|vocal|bass
#   audio-fx.sh status (JSON)    audio-fx.sh restore (re-apply saved state, used at login)
ST="$HOME/.local/state/audio-fx.json"
HEADSET_OUT="alsa_output.usb-XiiSound_Technology_Corporation_Fuxi-H3-00.playback.0.0"
HEADSET_IN="alsa_input.usb-XiiSound_Technology_Corporation_Fuxi-H3-00.capture.0.0"
[ -f "$ST" ] || echo '{"mic":false,"eq":false,"preset":"flat"}' > "$ST"
get() { python3 -I -c "import json;print(str(json.load(open('$ST'))['$1']).lower())"; }
put() { python3 -I -c "import json;d=json.load(open('$ST'));v='$2';d['$1']=(v=='true') if v in('true','false') else v;json.dump(d,open('$ST','w'))"; }
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
  mic)    [ "$2" = on ] && pactl set-default-source clean_mic || pactl set-default-source "$HEADSET_IN"; put mic $([ "$2" = on ] && echo true || echo false) ;;
  eq)     [ "$2" = on ] && pactl set-default-sink headset_eq || pactl set-default-sink "$HEADSET_OUT"; put eq $([ "$2" = on ] && echo true || echo false) ;;
  preset) apply_preset "$2" && put preset "$2" ;;
  status) cat "$ST" ;;
  restore)
    for i in $(seq 1 20); do [ -n "$(eq_id)" ] && break; sleep 1; done
    apply_preset "$(get preset)"
    [ "$(get mic)" = true ] && pactl set-default-source clean_mic
    [ "$(get eq)" = true ] && pactl set-default-sink headset_eq
    ;;
esac
