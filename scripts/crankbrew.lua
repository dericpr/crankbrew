require ("gpio") -- import library
local COMPRESSOR_DELAY = 180 -- 3 minute delay
local device_path = '/sys/bus/w1/devices/28-00000449da30/w1_slave'
local device_path_2 = '/sys/bus/w1/devices/28-000004f1d675/w1_slave'
local compressor_off_time = gre.mstime()
local ssr_fired = false
local report_temp_c = ""
local report_temp_2_c = ""
local temp_c = 0
local temp_2_c = 0
local cur_x = 0;
local points = {}
local points2 = {}
local max_idx = 560 --[280
local cooling_start = 0
local cooling_end = 0

configureOutGPIO(60)
writeGPIO(60,0)



function read_temp()
	
	local temp
	local temp_2
	local data_table  = {}
	local f = assert(io.open(device_path, 'r'))
	local t = f:read("*all")
	f:close()
	local second_device = assert(io.open(device_path_2, 'r'))
	local t1 = second_device:read("*all")
	second_device:close()
	for w in string.gmatch(t,"t=*=(%d+)") do
		temp = w
	end
	for m in string.gmatch(t1,"t=*=(%d+)") do
		temp_2 = m
	end
	--print(string.format("Got temp 2 of %d",temp_2))
	report_temp_c = string.format("%.2f",temp / 1000)
	report_temp_2_c = string.format("%.2f", temp_2 / 1000)
	--print(string.format("Temp2 in degrees c : %s",report_temp_2_c))
	data_table["probeTemp"] = report_temp_c
	data_table["probeTemp2"] = report_temp_2_c
	gre.set_data(data_table)
	
	temp_c = temp/1000
	temp_2_c = temp_2/1000
	local get_data_table  = {}
  	get_data_table = gre.get_data("SetPoint")
  	local setPoint = get_data_table["SetPoint"] * 1 
	if ( temp_c > setPoint+0.5 ) then
		if ( ssr_fired == false ) then
			local data_table  = {}
			local current_time = gre.mstime()
			
			local current_delay = (current_time - compressor_off_time) / 1000
			if (  current_delay >= COMPRESSOR_DELAY ) then 
				print("Turning on")
				ssr_fired = true
				cooling_start = gre.mstime()
				data_table["Layer1.Cooling_On.grd_hidden"] = 0
				data_table["Layer1.Compressor_Delay.grd_hidden"] = 1 
				gre.set_data(data_table)
				writeGPIO(60,1)
			else
		--		print(string.format("Current delay is %d seconds", current_delay))
				data_table["Layer1.Compressor_Delay.grd_hidden"] = 0
				data_table["compDelay"] = string.format("%d",COMPRESSOR_DELAY-current_delay)
				gre.set_data(data_table)
			end 
		end	
	else if ( temp_c < setPoint-0.2 ) then
		if ( ssr_fired == true) then
			local data_table  = {}
			print("Turning off")
			compressor_off_time = gre.mstime()
			print(string.format("Compressor ran for %d seconds", (compressor_off_time - cooling_start)/1000 ))
			ssr_fired = false
			writeGPIO(60,0)
			data_table["Layer1.Cooling_On.grd_hidden"] = 1
			gre.set_data(data_table)
		end
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
--	local v = {}
--	local newstr = ""
--	local newstr2 = ""
		
	-- Loop after 500 points
--	if ( cur_x > max_idx ) then
--		cur_x = 0
--	end
	-- subtract max height of trend area to plot line from bottom left corner
--	newstr = string.format(" %d:%d",cur_x,200-temp_c )	
--	newstr2 = string.format(" %d:%d", cur_x,200-temp_2_c)	
--	table.insert(points, newstr)
--	table.insert(points2,newstr2)
--	cur_x = cur_x + 1
--	v["temps"] = table.concat(points, " ")
--	v["temps2"] = table.concat(points2, " ")
	
--	gre.set_data(v)
end

function increment_setpoint(mapargs) 
 	local data_table  = {}
  	data_table = gre.get_data("SetPoint")
  	data_table["SetPoint"] = data_table["SetPoint"] + 0.1
  	print(string.format("SetPoint now at %f", data_table["SetPoint"]))
  	gre.set_data(data_table)
end
