local module=assert(loadfile(assert(arg[2])))()
local path=assert(arg[1])
local handlers,calls={},{}
local mon={name='test',x=0,y=0,width=1920,height=1080,scale=1,transform=0,reserved={0,30,0,0}}
hl={on=function(e,f) handlers[e]=f end,get_monitor=function() return mon end,
    dispatch=function(c) calls[#calls+1]=c end,dsp={window={}}}
for _,name in ipairs({'float','resize','move'}) do hl.dsp.window[name]=function(c) c.op=name; return c end end
local records=module.start(path)
local w={initial_class='app',initial_title='Document - app',mapped=true,floating=true,fullscreen=0,monitor=mon,at={x=100,y=120},size={x=800,y=500}}
handlers['window.close'](w)
assert(records.app.w==800 and records.app.x==100)
records=module.start(path)
w.floating=false;handlers['window.open'](w)
assert(#calls==3 and calls[1].op=='float' and calls[2].x==800 and calls[3].x==100 and calls[3].y==120)
handlers['window.close'](w);assert(records.app==nil)
calls={};handlers['window.open'](w);assert(#calls==0)
w.floating=true;w.initial_title='Save File';handlers['window.close'](w);assert(records.app==nil)
w.initial_title='app';w.fullscreen=2;handlers['window.close'](w);assert(records.app==nil)
local g=module.geometry({x=5000,y=-500,w=3000,h=1800},mon)
assert(g.x>=0 and g.y>=30 and g.x+g.w<=1920 and g.y+g.h<=1080)
local f=assert(io.open(path,'w'));f:write('os.execute("false")\nmalformed\n');f:close()
records=module.start(path);assert(next(records)==nil)
print('PASS: floating persistence, exact geometry, tiled reset, dialog separation, fullscreen exclusion, monitor bounds, malformed data.')
