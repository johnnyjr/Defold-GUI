local _M=function(args)
	
	if not args then
		args={}
	end
	if not args.click_sound then
		args.click_sound="main:/sounds#menu_click"		
	end
	if not args.default_button then
		args.default_button="button-9"
	end
	if not args.default_button_pressed then
		args.default_button_pressed="button-9_pressed"
	end
	if not args.default_button_disabled then
		args.default_button_disabled="button-9_disabled"
	end
	if not args.default_button_checked then
		args.default_button_checked="button-9_checked"
	end
	local _P={
		textboxes={},
		buttons={},
		alerts={},
		checkboxes={},
		radio_buttons={},
		lists={},
		windows={},
		url=msg.url(),
	}
	
	local function update_text(self, textbox, suffix)
		local box=_P.textboxes[textbox]
		if box.is_password then
			gui.set_text(box.textbox, string.rep("*", string.len(box.text))..suffix)
		else
			gui.set_text(box.textbox, box.text..suffix)			
		end
	end
	
	local function update_checkbox(self, name)
		local box=_P.checkboxes[name]
		if box.value then
			gui.play_flipbook(box.button, box.checked_texture)	
		else
			gui.play_flipbook(box.button, box.texture)	
		end
	end
	
	local function update_list(self, name)
		local list=_P.lists[name]
		for i,row in pairs(list.rows) do
			if row==list.selected_row then
				gui.play_flipbook(row.row, "row_selected")
			elseif row==list.last_selected_row then
				gui.play_flipbook(row.row, "row_deselected")			
			end
		end
		list.last_selected_row=list.selected_row
	end
	
	local function update_radio_group(self, radio_group)
		local group=_P.radio_buttons[radio_group]
		for n,r in pairs(group) do
			gui.play_flipbook(r.button, r.texture)
		end	
	end
	
	local function button_over(self, button)
		if button.pressed_texture~="" then
			gui.play_flipbook(button.button, button.pressed_texture)
		end
		msg.post(_P.url, "button_over", {button=button.name})
		gui.set_position(button.button_text, button.button_text_pos+vmath.vector3(1,-1,0))	
		if button.button_image then
			gui.set_position(button.button_image, button.button_image_pos+vmath.vector3(1,-1,0))	
		end
	end
	
	local function button_blur(self, button)
		if button.texture~="" then
			gui.play_flipbook(button.button, button.texture)
		end
		msg.post(_P.url, "button_blur", {button=button.name})	
		local pos=gui.get_position(button.button_text)
		gui.set_position(button.button_text, button.button_text_pos)	
		if button.button_image then
			gui.set_position(button.button_image, button.button_image_pos)	
		end
	end
		
	function _P.register_textbox(self, name, is_password)
		local box=gui.get_node(name.."_box")
		_P.textboxes[name]={
			box=box,
			textbox=gui.get_node(name.."_text"),
			is_password=is_password,
			text="",
			name=name
		}
	end
	
	function _P.register_button(self, name, button_texture, button_pressed_texture, button_disabled_texture)
		local button=gui.get_node(name.."_button")
		
		local exists, button_image=pcall(function()
			return gui.get_node(name.."_image")
		end)
		if exists then
			button_image_position=gui.get_position(button_image)
		else 
			button_image=nil
		end
		_P.buttons[name]={
			button=button,
			button_text=gui.get_node(name.."_text"),
			button_text_pos=gui.get_position(gui.get_node(name.."_text")),
			button_image=button_image,
			button_image_pos=button_image_position,
			name=name,
			texture=button_texture or args.default_button,
			pressed_texture=button_pressed_texture or args.default_button_pressed,
			disabled_texture=button_disabled_texture or args.default_button_disabled,
			enabled=true
		}
	end
		
	function _P.register_alert(self, name)
		local alert=gui.get_node(name.."_box")
		local alert_text=gui.get_node(name.."_text")
		local text_color=gui.get_color(alert_text)
		local outline=gui.get_outline(alert_text)
		_P.alerts[name]={
			alert=alert,
			alert_text=alert_text,
			name=name,
			color=gui.get_color(alert),
			text_color=text_color,
			outline=outline
		}
		gui.set_text(alert_text, "")
		gui.set_color(alert, vmath.vector4(0,0,0,0))
	end
	
	function _P.register_checkbox(self, name, initial_value, texture, pressed_texture, checked_texture)
		_P.checkboxes[name]={
			box=gui.get_node(name.."_box"),
			button=gui.get_node(name.."_button"),
			value=initial_value,
			texture=texture or args.default_button,
			pressed_texture=pressed_texture or args.default_button_pressed,
			checked_texture=checked_texture or args.default_button_checked
		}
		_P.register_button(self, name, _P.checkboxes[name].texture, _P.checkboxes[name].pressed_texture)
		update_checkbox(self, name)
	end
	
	function _P.register_radio_button(self, name, radio_group, off_texture, on_texture, pressed_texture)
		if _P.radio_buttons[radio_group]==nil then
			_P.radio_buttons[radio_group]={}
		end
		_P.radio_buttons[radio_group][name]={
			button=gui.get_node(name.."_button"),
			value=initial_value,
			texture=off_texture or "button_small-9",
			off_texture=off_texture or "button_small-9",
			pressed_texture=pressed_texture or on_texture or "button_small-9_pressed",
			on_texture=on_texture or "button_checked",
			group=radio_group	
		}
		_P.register_button(self, name, _P.radio_buttons[radio_group][name].off_texture, _P.radio_buttons[radio_group][name].on_texture)		
		update_radio_group(self, radio_group)
	end 
	
	function _P.set_radio_button_value(self, radio_group, name)
		local group=_P.radio_buttons[radio_group]
		local button=group[name]
		for n,r in pairs(group) do
			r.texture=r.off_texture
		end
		button.texture=button.on_texture
		update_radio_group(self, radio_group)
		msg.post(_P.url, "radio_button_value_changed", {button=name, group=radio_group})
	end
	
	function _P.register_list(self, name, data_property, selectable, add_row_function, container_height)
		if type(selectable)=="function" then
			container_height=add_row_function
			add_row_function=selectable
			selectable=true
		end
		_P.lists[name]={
			list = gui.get_node(name.."_list"),
			name = name,
			data_property=data_property,
			add_row_function = add_row_function,
			next_row_pos=vmath.vector3(),
			rows={},
			selectable=selectable,
			position=gui.get_position(gui.get_node(name.."_list")),
			container_height=container_height or 0
		}
	end
	
	function _P.register_window(self, name)
		_P.windows[name]={
			window=gui.get_node(name.."_window")
		}
	end
	
	function _P.hide_window(self, name)
		local win=_P.windows[name].window
		local pos=gui.get_position(win)
		pos.z=pos.z+100
		gui.set_position(win, pos)
	end
	
	function _P.show_window(self, name)
		local win=_P.windows[name].window
		local pos=gui.get_position(win)
		pos.z=0
		gui.set_position(win, pos)	
	end
	
	function _P.add_list_row(self, list_name, data)
		local list=_P.lists[list_name]
		local row=list.add_row_function(data)
		gui.set_parent(row, list.list)
		gui.set_position(row, list.next_row_pos)
		list.next_row_pos.y=list.next_row_pos.y-gui.get_size(row).y
		list.rows[data[list.data_property]]={
			row=row,
			data=data
		}
		local size=gui.get_size(list.list)
		size.y=-list.next_row_pos.y
		gui.set_size(list.list, size)
	end
	
	function _P.remove_list_row(self, list_name, data_name)
		local list=_P.lists[list_name]
		local row=list.rows[data_name]
		local height=gui.get_size(row.row).y
		local y=gui.get_position(row.row).y
		for i,r in pairs(list.rows) do
			local pos=gui.get_position(r.row)
			if pos.y<y then
				pos.y=pos.y+height
				gui.set_position(r.row, pos)
			end
		end
		gui.delete_node(row.row)
		list.rows[data_name]=nil
		list.next_row_pos.y=list.next_row_pos.y+height
	end
	
	function _P.clear_list(self, list_name)
		local list=_P.lists[list_name]
		list.selected_row=nil
		list.next_row_pos=vmath.vector3()
		for i,row in pairs(list.rows) do
			gui.delete_node(row.row)
		end
		list.rows={}
	end
	
	function _P.get_list_data(self, list_name, data_name)
		local list=_P.lists[list_name]
		return list.rows[data_name].data
	end

	function _P.get_selected_list_data(self, list_name)
		local list=_P.lists[list_name]
		
		if list.selected_row ~= nil then
			return list.selected_row.data
		else
			return nil
		end
	end
	
	function _P.set_selected_list_item(seld, list_name, data_name)
		local list=_P.lists[list_name]
		list.selected_row=list.rows[data_name]
		msg.post(_P.url, "list_row_selected", {list=list.name, row=data_name})
		update_list(self, list_name)
	end
	
	function _P.show_alert(self, name, text, duration)
		local alert=_P.alerts[name]
		gui.set_text(alert.alert_text, text)
		gui.set_color(alert.alert, alert.color)
		if duration then
			gui.cancel_animation(alert.alert, "color")
			_P.hide_alert(self, name, true, duration)
		end
	end
	
	function _P.hide_alert(self, name, animated, delay)
		local alert=_P.alerts[name]
		if animated then
			local color=vmath.vector4(alert.color.x, alert.color.y, alert.color.z, 0)
			local text_color=alert.text_color
			local outline=alert.outline
			gui.animate(alert.alert, "color", color, gui.EASING_LINEAR, 0.5, delay or 0, function()
				gui.set_text(alert.alert_text, "")	
			end)
			gui.set_color(alert.alert_text, text_color)
			gui.animate(alert.alert_text, "color.w", 0, gui.EASING_LINEAR, 0.5, delay or 0, function()
				gui.set_color(alert.alert_text, text_color)
			end)
			gui.set_outline(alert.alert_text, outline)
			gui.animate(alert.alert_text, "outline.w", 0, gui.EASING_LINEAR, 0.5, delay or 0, function()
				outline.w=1--outline_alpha
				gui.set_outline(alert.alert_text, outline)
			end)
		else
			gui.set_text(alert.alert_text, "")
			gui.set_color(alert.alert, vmath.vector4(1,1,1,0))
		end
	end

	function _P.set_button_enabled(self, name, enabled)
		local button=_P.buttons[name]
		if enabled then
			gui.play_flipbook(button.button, button.texture)		
		else
			gui.play_flipbook(button.button, button.disabled_texture)
		end
		button.enabled=enabled
	end
	

	function _P.set_button_image(self, name, image)
		local button=_P.buttons[name]
		gui.play_flipbook(button.button_image, image)
	end
	
	function _P.set_button_text(self, name, text)
		local button=_P.buttons[name]
		gui.set_text(button.button_text, text)
	end
	
	function _P.adjust_button_image_to_text(self, name, margin)
		if margin==nil then margin=10 end
		local button=_P.buttons[name]
		local metrics=gui.get_text_metrics_from_node(button.button_text)
		local pivot=gui.get_pivot(button.button_text)
		local pos=gui.get_position(button.button_text)
		local size=gui.get_size(button.button_image)
		size.y=0
		if pivot==gui.PIVOT_CENTER then
			button.button_image_pos=pos-vmath.vector3(metrics.width/2+margin,0,0)
			gui.set_position(button.button_image, button.button_image_pos)
					
		else
			--TODO: Implement the other pivots
		end
	end

	function _P.get_text(self, textbox)
		return _P.textboxes[textbox].text
	end

	function _P.set_text(self, textbox, text)
		_P.textboxes[textbox].text=text
		update_text(self, textbox, "")
	end

	function _P.get_checked(self, textbox)
		return _P.checkboxes[textbox].value
	end
	
	function _P.on_input(self, action_id, action)
		if action_id==hash("mouse") then
			if action.released then
				if self.scrolling and self.scrolling.scrolled then
					self.scrolling=false
					return true
				end
				self.scrolling=false
				if self.selected_textbox then
					update_text(self, self.selected_textbox, "")
					selected_textbox=nil
				end
				if not (args.disable_autohide_android and sys.get_sys_info().system_name=="Android") then
					gui.hide_keyboard()
				end
				for i, box in pairs(_P.textboxes) do
					if gui.pick_node(box.box, action.x, action.y) then
						if args.click_sound then
							pcall(msg.post, args.click_sound, "play_sound")
						end
						self.selected_textbox=box.name
						msg.post(_P.url, "textbox_selected", {textbox=box.name})
						gui.show_keyboard(box.keyboard or gui.KEYBOARD_TYPE_DEFAULT, false)
						update_text(self, box.name, "_")
						return true
					end
				end
				if self.button and gui.pick_node(self.button.button, action.x, action.y) then
					if args.click_sound then
						pcall(msg.post, args.click_sound, "play_sound")
					end
					button_blur(self, self.button)		
					if _P.checkboxes[self.button.name]~=nil then
						_P.checkboxes[self.button.name].value=not _P.checkboxes[self.button.name].value
						update_checkbox(self, self.button.name)
					end
					for i, group in pairs(_P.radio_buttons) do
						if group[self.button.name]~=nil then
							_P.set_radio_button_value(self, i, self.button.name)
							msg.post(_P.url, "radio_button_clicked", {button=self.button.name, group=i})
						end
					end
					msg.post(_P.url, "button_clicked", {button=self.button.name})
					return true
				end
				if self.button then
					self.button=nil
				end
				for i,list in pairs(_P.lists) do
					if list.selectable then
						for j, row in pairs(list.rows) do
							if gui.pick_node(row.row, action.x, action.y) and list.selected_row~=row then
								list.selected_row=row
								if args.click_sound then
									msg.post(args.click_sound, "play_sound")
								end
								msg.post(_P.url, "list_row_selected", {list=list.name, row=row.data[list.data_property]})
							end
						end
						update_list(self, list.name)
					end
				end
			elseif action.pressed then
				for i, list in pairs(_P.lists) do
					if list.container_height>0 and gui.pick_node(list.list, action.x, action.y) then
						if list.container_height<math.abs(list.next_row_pos.y) then
							self.scrolling={
								list=list,
								start_action=action,
								position=gui.get_position(list.list)
							}
						end
					end
				end
				for i, button in pairs(_P.buttons) do
					if gui.pick_node(button.button, action.x, action.y) and button.enabled then
						button_over(self, button)
						self.button=button
						return true
					end
				end
			elseif self.button then
				if not gui.pick_node(self.button.button, action.x, action.y) then
					button_blur(self, self.button)
				else
					button_over(self, self.button)					
				end
				return true
			elseif self.scrolling then
				local dy=action.y-self.scrolling.start_action.y
				local new_pos=self.scrolling.position+vmath.vector3(0,dy,0)
				local size=gui.get_size(self.scrolling.list.list)
				
				if new_pos.y<self.scrolling.list.position.y then new_pos.y=self.scrolling.list.position.y end
				if size.y-new_pos.y<self.scrolling.list.container_height then
					new_pos.y=size.y-self.scrolling.list.container_height
				end
				gui.set_position(self.scrolling.list.list, new_pos)
				if math.abs(dy)>5 then self.scrolling.scrolled=true end
			end
		elseif action_id==hash("text") and self.selected_textbox then
			_P.textboxes[self.selected_textbox].text=_P.textboxes[self.selected_textbox].text..action.text
			update_text(self, self.selected_textbox, "_")
		elseif action_id==hash("backspace") and action.released and self.selected_textbox then
			box=_P.textboxes[self.selected_textbox]
			box.text=string.sub(box.text,1,-2)
			update_text(self, self.selected_textbox, "_")
		elseif action_id==hash("enter") and action.released and sys.get_sys_info().system_name=="Android" then
			gui.hide_keyboard()		
		end
	end

	_P.entry_animation=function(self, node, type, delay)
		if not type then type="scale" end
		if not delay then delay=0.5 end
		
		if type=="scale" then
			local start_scale=vmath.vector3()
			local end_scale=gui.get_scale(node)
			gui.set_scale(node,start_scale)
			gui.animate(node, "scale", end_scale, gui.EASING_OUTBOUNCE, 0.5, delay)	
		elseif type=="slide_left" then
			local end_pos=gui.get_position(node)
			local start_pos=vmath.vector3(-200, end_pos.y, end_pos.z)
			gui.set_position(node,start_pos)
			gui.animate(node, "position", end_pos, gui.EASING_OUTBOUNCE, 0.5, delay)				
		elseif type=="slide_right" then
			local end_pos=gui.get_position(node)
			local start_pos=vmath.vector3(520, end_pos.y, end_pos.z)
			gui.set_position(node,start_pos)
			gui.animate(node, "position", end_pos, gui.EASING_OUTBOUNCE, 0.5, delay)				
		elseif type=="slide_down" then
			local end_pos=gui.get_position(node)
			local start_pos=vmath.vector3(end_pos.x, args.global.window.height+200, end_pos.z)
			gui.set_position(node,start_pos)
			gui.animate(node, "position", end_pos, gui.EASING_OUTBOUNCE, 0.5, delay)				
		elseif type=="slide_up" then
			local end_pos=gui.get_position(node)
			local start_pos=vmath.vector3(end_pos.x, -200, end_pos.z)
			gui.set_position(node,start_pos)
			gui.animate(node, "position", end_pos, gui.EASING_OUTBOUNCE, 0.5, delay)				
		end
	end
	
	_P.exit_animation=function(self, node, type, delay)
		if not type then type="scale" end
		if not delay then delay=0 end
		
		if type=="scale" then
			local end_scale=vmath.vector3()
			gui.animate(node, "scale", end_scale, gui.EASING_INBOUNCE, 0.5, delay)	
		elseif type=="slide_left" then
			local pos=gui.get_position(node)
			pos.x=-200
			gui.animate(node, "position", pos, gui.EASING_INBOUNCE, 0.5, delay)				
		elseif type=="slide_right" then
			local pos=gui.get_position(node)
			pos.x=520
			gui.animate(node, "position", pos, gui.EASING_INBOUNCE, 0.5, delay)				
		end
	end
		
	return _P
end

local _new_text_node=gui.new_text_node
gui.new_text_node=function(pos, text)
	local node=_new_text_node(pos, text)
	gui.set_layer(node, "text")
	return node
end

--[[
local _new_box_node=gui.new_box_node
gui.new_box_node=function(pos, size)
	local node=_new_box_node(pos, size)
	gui.set_layer(node, "gfx")
	return node
end
--]]

return _M