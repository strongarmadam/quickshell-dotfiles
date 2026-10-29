-- Remember the last closed floating window per app. Data is never executed as Lua.
local M = {}
local function hex(s) return (s:gsub('.', function(c) return string.format('%02x', c:byte()) end)) end
local function unhex(s)
    if #s % 2 ~= 0 or s:find('[^0-9a-f]') then return nil end
    return (s:gsub('..', function(c) return string.char(tonumber(c,16)) end))
end
local function clamp(n, lo, hi) return math.max(lo, math.min(n, hi)) end
local function key(w)
    local class = w.initial_class
    if not class or class == '' then class = w.class end
    if not class or class == '' then return nil end
    -- Dialogs must not overwrite their parent application's normal geometry.
    local title = (w.initial_title or ''):lower()
    if class:match('^xdg%-desktop%-portal') or class == 'org.gtk.FileChooser'
        or title:match('^save ') or title:match('^open file') or title:match('^open folder')
        or title:match('^select .*file') or title:match('^select .*folder')
        or title:match('^choose .*file') or title:match('^choose .*folder')
        or title == 'file operation progress' then return nil end
    -- Quickshell hosts separate application windows under one app ID.
    if class == 'org.quickshell' then return class .. ':' .. (w.initial_title or '') end
    return class
end
M.key = key
function M.geometry(saved, mon)
    local width, height = mon.width / mon.scale, mon.height / mon.scale
    if mon.transform % 2 == 1 then width, height = height, width end
    local r = mon.reserved or {}
    local left, top, right, bottom = r.left or r[1] or 0, r.top or r[2] or 0, r.right or r[3] or 0, r.bottom or r[4] or 0
    local ww = math.min(saved.w, math.max(1, width-left-right-4))
    local hh = math.min(saved.h, math.max(1, height-top-bottom-4))
    return {w=math.floor(ww),h=math.floor(hh),
        x=mon.x+math.floor(clamp(saved.x,left+2,width-right-ww-2)),
        y=mon.y+math.floor(clamp(saved.y,top+2,height-bottom-hh-2))}
end
function M.start(path)
    local records = {}
    local input = io.open(path,'r')
    if input then
        local count = 0
        for line in input:lines() do
            count=count+1; if count>4096 then break end
            local k,m,x,y,w,h = line:match('^(%x+)\t(%x+)\t(%-?%d+)\t(%-?%d+)\t(%d+)\t(%d+)$')
            if k and #k<2048 and #m<1024 then
                k,m,x,y,w,h=unhex(k),unhex(m),tonumber(x),tonumber(y),tonumber(w),tonumber(h)
                if k and m and math.abs(x)<100000 and math.abs(y)<100000 and w>0 and w<32768 and h>0 and h<32768 then
                    records[k]={monitor=m,x=x,y=y,w=w,h=h}
                end
            end
        end
        input:close()
    end
    local function save()
        local out=io.open(path..'.new','w')
        if not out then return end
        for k,v in pairs(records) do
            out:write(string.format('%s\t%s\t%d\t%d\t%d\t%d\n',hex(k),hex(v.monitor),v.x,v.y,v.w,v.h))
        end
        out:close(); assert(os.rename(path..'.new',path))
    end
    hl.on('window.close',function(w)
        local k=w and key(w)
        if not k or w.fullscreen~=0 then return end
        if not w.floating then
            if records[k] then records[k]=nil;save() end
            return
        end
        local mon,at,size=w.monitor,w.at,w.size
        if not mon or not at or not size or size.x<=0 or size.y<=0 then return end
        records[k]={monitor=mon.name,x=at.x-mon.x,y=at.y-mon.y,w=size.x,h=size.y}
        save()
    end)
    hl.on('window.open',function(w)
        local k=w and key(w);local saved=k and records[k]
        if not saved or not w.mapped or w.fullscreen~=0 then return end
        local mon=hl.get_monitor(saved.monitor) or w.monitor
        if not mon then return end
        local g=M.geometry(saved,mon)
        hl.dispatch(hl.dsp.window.float({action='set',window=w}))
        if w.monitor and mon.name~=w.monitor.name then
            hl.dispatch(hl.dsp.window.move({monitor=mon.name,silent=true,window=w}))
        end
        hl.dispatch(hl.dsp.window.resize({x=g.w,y=g.h,relative=false,window=w}))
        hl.dispatch(hl.dsp.window.move({x=g.x,y=g.y,relative=false,window=w}))
    end)
    return records
end
if hl then
    local dir=(os.getenv('XDG_STATE_HOME') or (os.getenv('HOME')..'/.local/state'))..'/floating-window-memory'
    local quoted="'"..dir:gsub("'","'\\''").."'"
    os.execute('umask 077; mkdir -p -- '..quoted)
    M.start(dir..'/windows.tsv')
end
return M
