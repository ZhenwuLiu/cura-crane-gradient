# adds a gradient to Cura g-code for M3D Crane Quad
# usage: ruby cura-crane-gradient.rb in.gcode POINT [POINT...] > out.gcode
#  where POINT is e.g. 13P0:0:1:0 (third filament at 13 percent) or 112L0:1:0:0 (second filament at layer 112)
NUMBER_REGEX = /(?:\d*\.)?\d+/

def check_mix!(mix, arg = nil)
	sum = mix.inject(:+)
	raise "bad mix in #{arg || mix.inspect}; must add to 1" unless sum > 0.99 && sum < 1.01
end

def interpolate_mix(mix0, mix1, fraction)
	raise "mismatched mixes" unless mix0.size == mix1.size
	mix = []
	mix0.each_index do |i|
		mix << mix0[i] * (1 - fraction) + mix1[i] * fraction
	end
	check_mix!(mix)
	mix
end

def get_gradient_points(layer_count)
	points = {}
	ARGV.each do |arg|
		if arg =~ /(#{NUMBER_REGEX})(P|L)(#{NUMBER_REGEX}):(#{NUMBER_REGEX}):(#{NUMBER_REGEX}):(#{NUMBER_REGEX})/
			layer = if $2 == 'P'
				[($1.to_f * layer_count / 100).to_i, layer_count - 1].min
			else
				[$1.to_i, layer_count - 1].min
			end
			mix = [$3.to_f, $4.to_f, $5.to_f, $6.to_f]
			check_mix! mix, arg
			points[layer] = mix
		end
	end
	raise "no gradient points given" if points.empty?
	points
end

def get_gradient(layer_count)
	gradient = []
	points = get_gradient_points(layer_count)
	point_layers = points.keys.sort
	last_layer = 0
	last_mix = points[point_layers.first]
	point_layers.each do |layer|
		mix = points[layer]
		for i in last_layer...layer
			gradient[i] = interpolate_mix(last_mix, mix, (i - last_layer).to_f / (layer - last_layer))
		end
		gradient[layer] = mix
		last_layer = layer + 1
		last_mix = mix
	end
	gradient
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

	# compute the color mix for each layer
	gradient = get_gradient(layer_count)

	# insert M567 commands
	while true
		line = ARGF.readline
		puts line
		if line =~ /^;LAYER:(\d+)\s*$/
			layer = $1.to_i
			mix = gradient[layer]
			puts "M567 P0 E#{mix.map(&:to_s).join(':')}" if mix
		end
	end

rescue EOFError, Errno::ENOENT
	if layer_count.nil?
		STDERR.puts "layer count not found!"
		return false
	else
		STDERR.puts "processed layers: #{layer + 1} / #{layer_count}"
		return true
	end
end

exit 1 unless rewrite_gcode