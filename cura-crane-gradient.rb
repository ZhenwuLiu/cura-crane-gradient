# adds a four-color gradient to Cura g-code for M3D Crane Quad
# usage: ruby cura-crane-gradient.rb in.gcode > out.gcode

def interpolate_gradient(layer, count)
	layers_per_part = count / 3
	part = layer / layers_per_part
	ratio = (layer % layers_per_part).to_f / layers_per_part
	mix = case part
	when 0
		"#{1-ratio}:#{ratio}:0:0"
	when 1
		"0:#{1-ratio}:#{ratio}:0"
	when 2
		"0:0:#{1-ratio}:#{ratio}"
	else
		"0:0:0:1"
	end
	cmd = "M567 P0 E#{mix}"
	puts cmd
end

def rewrite_gcode
	# get layer count
	while true
		line = ARGF.readline
		puts line
		if line =~ /^;LAYER_COUNT:(\d+)\s*$/
			layer_count = $1.to_i
			break
		end
	end

	# insert M567 commands
	while true
		line = ARGF.readline
		puts line
		if line =~ /^;LAYER:(\d+)\s*$/
			layer = $1.to_i
			interpolate_gradient(layer, layer_count)
		end
	end

rescue EOFError
	if layer_count.nil?
		STDERR.puts "layer count not found!"
		return false
	else
		STDERR.puts "processed layers: #{layer + 1} / #{layer_count}"
		return true
	end
end

exit 1 unless rewrite_gcode