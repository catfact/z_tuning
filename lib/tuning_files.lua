local scala = dofile('tuning_scala.lua')

local TuningFiles = {}

local user_data_path = _path.data..'tuning/tunings'
local factory_data_path = _path.code..'tuning/lib/data'

TuningFiles.bootstrap = function()
   local dir = io.open(user_data_path)
   if not dir then
      dir.close()
      os.execute("mkdir -p "..user_data_path)
      os.execute("cp "..factory_data_path.."/*.* "..user_data_path)
   end   
end

-- needs to use a callback :/
TuningFiles.load_files = function(callback)
   local tunings = {} 
   local handle_scanned_files = function(list)
      for _,path in pairs(list) do
	 local file = string.match(path, ".+/(.*)$")
	 local name, ext  = string.match(file, "(.*)%.(.*)")
	 if ext == '.scl' then
	    local r = scala.load_file(path)
	    tunings[name] = Tuning.new(ratios=r)	 
	 elseif ext == '.lua' then
	    local data = dofile(path)
	    if data then
	       tunings[name] = Tuning.new(data)
	    elseif data.cents then
	       local r = {}
	       for i,v in ipairs(data.cents)
	       table.insert(r, 2 ^ v / 1200)
	       tunings[name] = Tuning.new(ratios=r)
	    end
	 else
	    print('WARNING: tuning module encountered unrecognized file: '..file)
	 end
      end
      callback(tunings)
   end
   norns.system_cmd('find '..factory_data_path, handle_scanned_files)
end

return TuningFiles
