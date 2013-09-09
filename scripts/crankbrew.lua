require ("gpio") -- import library
local COMPRESSOR_DELAY = 180 -- 3 minute delay
local device_path = '/sys/bus/w1/devices/28-00000449da30/w1_slave'
local compressor_off_time = gre.mstime()
local ssr_fired = false
local report_temp_c = ""
local points = ""
local temp_c = 0
local cur_x = 0;
local points = {}
--configureOutGPIO(60)
--writeGPIO(60,0)


local startx = 0
local starty = 150
local amplitude = 60
local freq = 30
local incx = 0
local incy = 0
local max_idx = 560 --[280
local cur_w_idx = 1
local wrapped = 0 
local cur_rad = 0
local x = {}
local y = {}

function read_temp()
	local f = assert(io.open(device_path, 'r'))
	local t = f:read("*all")
	local temp
	local data_table  = {}
	
	
	f:close()
	for w in string.gmatch(t,"t=*=(%d+)") do
		temp = w
	end
	report_temp_c = string.format("%.2f",temp / 1000)
	data_table["probeTemp"] = report_temp_c
	gre.set_data(data_table)
	temp_c = temp/1000
	--print (string.format("Got temp of %s C",temp_c))
	if ( temp_c > 24 ) then
		if ( ssr_fired == false ) then
			local data_table  = {}
			local current_time = gre.mstime()
			
			local current_delay = (current_time - compressor_off_time) / 1000
			if (  current_delay >= COMPRESSOR_DELAY ) then 
				print("Turning on")
				ssr_fired = true
				data_table["Layer1.Cooling_On.grd_hidden"] = 0
				data_table["Layer1.Compressor_Delay.grd_hidden"] = 1
				gre.set_data(data_table)
				writeGPIO(60,1)
			else
				print(string.format("Current delay is %d seconds", current_delay))
				data_table["Layer1.Compressor_Delay.grd_hidden"] = 0
				data_table["compDelay"] = string.format("%d",COMPRESSOR_DELAY-current_delay)
				gre.set_data(data_table)
			end 
		end	
	else
		if ( ssr_fired == true) then
			local data_table  = {}
			print("Turning off")
			compressor_off_time = gre.mstime()
			ssr_fired = false
			writeGPIO(60,0)
			data_table["Layer1.Cooling_On.grd_hidden"] = 1
			gre.set_data(data_table)
		end
	end
	

end

function hide_control(mapargs) 
	
	local data_table  = {}
	print("Hiding table")
	data_table["Layer1.Cooling_On.grd_hidden"] = 1
	gre.set_data(data_table)
end

function show_control(mapargs) 
	local data_table  = {}
	print("Showing Table")
	data_table["Layer1.Cooling_On.grd_hidden"] = 0
	gre.set_data(data_table)
end

function draw_trend(mapargs)
	local points
	local v = {}
	local iter
	local points = ""
	local radinc
	local theta
	
	-- Use a circular buffer to keep points in a sin wave, adjusting position in screen
	-- and then change points into a polygon string  
	if cur_w_idx > max_idx then
		cur_w_idx = 1
		wrapped = 1
	end		
	
	--frequency calcuated as increments need to reach 2 pi.
	radinc = 6.283185/freq
	
	if cur_rad > 6.283185 then
		cur_rad = cur_rad - 6.283185
	end
	
	-- get sin value at current pos, magnify to match amplitude
	tmp = math.sin(cur_rad)	
	tmp = tmp * amplitude			
	y[cur_w_idx] = math.floor(tmp) + incy + starty
	
	iter = cur_w_idx
	
	points = {}
	
	while (iter > 0) do
		newstr = string.format("%d:%d", max_idx - (cur_w_idx-iter) - 1, temp_c)
		print(string.format("Adding point %s", newstr))
		table.insert(points, newstr)
		iter = iter -1
	end
	
	-- Gone around once so now fill in the old point data
	if (wrapped == 1) then
		iter = max_idx		
		
		while (iter > cur_w_idx) do		
			newstr = string.format("%d:%d", iter - cur_w_idx - 1, temp_c)
			print(string.format("Adding point after wrap %s", newstr))
			table.insert(points, newstr)
			iter = iter -1
		end
	else
		-- extend to start of trend window for a flat line 
		if (cur_w_idx < max_idx) then 
			newstr = string.format(" %d:%d",startx,starty)
			print(string.format("Adding point first pass %s", newstr))		
			table.insert(points, newstr)
		end
	end

	cur_w_idx = cur_w_idx + 1

	cur_rad = cur_rad + radinc
	
	v["temps"] = table.concat(points, " ")
	
	gre.set_data(v)
	--local v = {}
	--local newstr = ""
	
	
	--newstr = string.format(" %d:%d",cur_x,temp_c )		
	--print(string.format("created new string %s", newstr))
	--table.insert(points, newstr)
	--cur_x = cur_x + 1
	
	--v["temps"] = table.concat(points, " ")
	
	--gre.set_data(v)
end
