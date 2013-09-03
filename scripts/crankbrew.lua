require ("gpio") -- import library
local COMPRESSOR_DELAY = 180 -- 3 minute delay
local device_path = '/sys/bus/w1/devices/28-00000449da30/w1_slave'
local compressor_off_time = gre.mstime()
local ssr_fired = false

--configureOutGPIO(60)
--writeGPIO(60,0)

function read_temp()
	local f = assert(io.open(device_path, 'r'))
	local t = f:read("*all")
	local temp
	local data_table  = {}
	
	
	f:close()
	for w in string.gmatch(t,"t=*=(%d+)") do
		temp = w
	end
	local report_temp_c = string.format("%.2f",temp / 1000)
	data_table["probeTemp"] = report_temp_c
	gre.set_data(data_table)
	local temp_c = temp/1000
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
