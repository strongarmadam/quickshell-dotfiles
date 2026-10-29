import json, subprocess, time
from pathlib import Path
config=str(Path.home()/'.config/quickshell/overview')
launcher=str(Path.home()/'.local/bin/workspace-overview')
def run(*args):
    p=subprocess.run(args,capture_output=True,text=True,timeout=8)
    return p

def state():
    p=run('quickshell','ipc','-p',config,'call','overview','state')
    try: return json.loads(p.stdout)
    except ValueError: return None

def wait_for(predicate):
    for _ in range(50):
        if predicate(): return
        time.sleep(.1)
    raise AssertionError('Timed out')

def key(key,mods=''):
    code='; '.join('hl.dispatch(hl.dsp.send_key_state({mods=%s,key=%s,state=%s}))'%(json.dumps(mods),json.dumps(key),json.dumps(s)) for s in ('down','up'))
    assert run('hyprctl','eval',code).stdout.strip()=='ok'

original=json.loads(run('hyprctl','-j','activeworkspace').stdout)['id']
try:
    run('hyprctl','dispatch','hl.dsp.focus({workspace=7})')
    run(launcher)
    wait_for(lambda: state() and state()['workspaces']==7)
    assert state()['selected']==7, state()
    print('PASS: expands to workspace 7 and selects current workspace')
    key('Escape')
    wait_for(lambda: state() is None)
    print('PASS: Escape dismisses and process exits')
    run('hyprctl','dispatch',f'hl.dsp.focus({{workspace={original}}})')
    run('hyprctl','dispatch','hl.dsp.exec_cmd("@HOME@/.local/bin/workspace-overview")')
    wait_for(lambda: state() is not None)
    print('PASS: configured Super+W launch action opens overview')
    key('w','SUPER')
    wait_for(lambda: state() is None)
    print('PASS: Super+W dismisses')
    run(launcher)
    wait_for(lambda: state() is not None)
    run('quickshell','ipc','-p',config,'call','overview','setPreviews','false')
    assert state()['previews'] is False
    key('Right')
    assert state()['selected']==2, state()
    key('Return')
    wait_for(lambda: state() is None)
    assert json.loads(run('hyprctl','-j','activeworkspace').stdout)['id']==2
    print('PASS: fallback, Right and Enter activate workspace 2')
    run(launcher)
    wait_for(lambda: state() is not None)
    run(launcher)
    wait_for(lambda: state() is None)
    print('PASS: launcher toggles without duplicate instances')
finally:
    run('quickshell','ipc','-p',config,'call','overview','close')
    run('hyprctl','dispatch',f'hl.dsp.focus({{workspace={original}}})')
