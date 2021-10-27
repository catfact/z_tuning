local scala = require 'tuning/lib/tuning_scala'
local tuning = require 'tuning/lib/tuning'

local TuningFiles = {}

local user_data_path = _path.data..'tuning/tunings'
local factory_data_path = _path.code..'tuning/lib/data'

TuningFiles.bootstrap = function()
   print('bootstrapping tunings...')
   local dir = io.open(user_data_path)
   if not dir then
      print('creating tuning data directory...')
      os.execute("mkdir -p "..user_data_path)
      print('copying tuning data...')
      os.execute("cp "..factory_data_path.."/*.* "..user_data_path)
   else
      dir.close()
   end   
end

function splitlines(s)
   if s:sub(-1)~="\n" then s=s.."\n" end
   return s:gmatch("(.-)\n")
end


-- needs to use a callback :/
TuningFiles.load_files = function(callback)
   local tunings = {} 
   local handle_scanned_files = function(list)
      print('----------------------------------')
      print('handling scanned tuning files:')
      print(list)
      print('----------------------------------')

      for file in splitlines(list) do
	 print('handling tuning file: '..file)
	 --local file = string.match(path, ".+/(.*)$")
	 --print(file)
	 if file then
	    local name, ext  = string.match(file, "(.*)%.(.*)")
	    print('name = '..name..'; ext = '..ext)	    
	    if ext == 'scl' then
	       print('loading tuning file (.scl): '..file)
	       local r = scala.load_file(user_data_path..'/'..file)
	       tunings[name] = tuning.new({ratios=r})	 
	    elseif ext == 'lua' then
	       print('loading tuning file (.lua): '..file)
	       local data = dofile(user_data_path..'/'..file)
	       if data then
		  tunings[name] = tuning.new(data)
	       elseif data.cents then
		  local r = {}
		  for i,v in ipairs(data.cents) do
		     table.insert(r, 2 ^ v / 1200)
		  end
		  tunings[name] = tuning.new({ratios=r})
	       end
	    else
	       print('WARNING: tuning module encountered unrecognized file: '..file)
	    end
	    print('added: '..name)-- : '..tunings[name])
	 end
      end
      tab.print(tunings)
      return tunings
   end
   local scan_cmd = 'ls '..user_data_path
   print('scanning: ')
   print(scan_cmd)
   --norns.system_cmd(scan_cmd, handle_scanned_files)
   ---- local res = os.execute(scan_cmd)
   --- UUUUUGH   
   local stdout = io.popen(scan_cmd, 'r')
   local res = stdout:read('*a')
   return handle_scanned_files(res)
end

return TuningFiles
