local _M={
	TYPE_SPHERE=0,
	TYPE_CONE=1,
	emitters={}
}

function _M.get_default_options()
		return {
			auto_start = false,
			type=_M.TYPE_SPHERE,
			size=vmath.vector3(0,0,1),
			spawn_rate=200,
			duration=1,
			speed=200,
			particle_life_time=0.5,
			texture="texture",
			animation="anim",
			particle_layer="",
			particle_size=vmath.vector3(30,30,0),
		}
end

function _M.get_angles(o, dt)
	if o.type==_M.TYPE_SPHERE then
		return 2*math.pi / (o.spawn_rate*dt), 0, 2*math.pi
	end
end

function _M.update(self, dt)
	for e,_P in pairs(_M.emitters) do
		if _P.running then
			local opt=_P.options
			if _P.run_duration==nil then _P.run_duration=opt.duration end
			
			_P.run_duration=_P.run_duration-dt
			
			local angle_step, min_angle, max_angle = _M.get_angles(_P.options, dt)
			local angle = angle_step * math.random() + min_angle
			local p = _P.position
			local start_distance=vmath.length(_P:get_value(opt.size))
			local end_distance=opt.particle_life_time*_P:get_value(opt.speed)
			for i=0,_P:get_value(opt.spawn_rate)*dt do
				angle=angle+angle_step
				local dir = vmath.vector3(math.cos(angle), math.sin(angle), 0)
				local start_p = p + dir * start_distance
				local end_p = p + dir * end_distance
				local particle=_P.get_particle(start_p)
				
				gui.animate(particle, gui.PROP_POSITION, end_p, gui.EASING_LINEAR, _P:get_value(opt.particle_life_time), 0, function()
					gui.delete_node(particle)
				end)
				
				_P.apply_animations(particle)
			end
			
			if _P.run_duration<0 then
				_P.running=false
				table.remove(_M.emitters, e)
			end
		end	
	end
end

function _M.set_particle(node, system)
	gui.set_texture(node, system:get_value(system.options.texture))
	gui.play_flipbook(node, hash(system:get_value(system.options.animation)))
end

function _M.play(system)
	system.running=true
end

function _M.create(self, position, options)
	math.randomseed(os.time())
	local default_options=_M.get_default_options()
	for k,v in pairs(default_options) do
		if options[k]==nil then
			options[k]=v
		end
	end
	local _P = {
		started=false,
		position = position or vmath.vector3(),
		options = options
	}
	
	table.insert(_M.emitters, _P)

	function _P.play(self)
		_M.play(_P)
	end
	
	function _P.get_value(system, value)
		if type(value)=="function" then
			return value(system)
		else
			return value
		end
	end
	
	function _P.get_particle(position)
		local node=gui.new_box_node(vmath.vector3(position.x, position.y, 0), _P:get_value(_P.options.particle_size))
		_M.set_particle(node, _P)
		gui.set_layer(node, hash(_P:get_value(_P.options.particle_layer)))
		return node
	end
	
	function _P.apply_animations(particle)
		gui.set_color(particle, vmath.vector4(1, 1, 1, 0))
		gui.animate(particle, gui.PROP_COLOR, vmath.vector4(1, 1, 1, 1), gui.EASING_OUTQUAD, _P:get_value(_P.options.particle_life_time)*0.2, 0.0, function()
			gui.animate(particle, gui.PROP_COLOR, vmath.vector4(1, 1, 1, 0), gui.EASING_INOUTQUAD, _P:get_value(_P.options.particle_life_time)*0.8)
		end)
	end
	
	if _P.options.auto_start then
		_P.play(self)
	end
	
	return _P
end

return _M

