class_name Layout

static func scale_number(value: float) -> float:
	return value * max(OS.get_screen_dpi(OS.get_current_screen()) / 160.0, 1)

## This modifies the passed StyleBox
static func scale_stylebox(style_box: StyleBox) -> StyleBox:
	style_box.content_margin_left = scale_number(style_box.content_margin_left)
	style_box.content_margin_right = scale_number(style_box.content_margin_right)
	style_box.content_margin_top = scale_number(style_box.content_margin_top)
	style_box.content_margin_bottom = scale_number(style_box.content_margin_bottom)
	return style_box

## This modifies the passed StyleBox
static func scale_font(font: Font) -> Font:
	if font is DynamicFont:
		var df: DynamicFont = font
		df.size = scale_number(font.size)
	return font
## This modifies the passed Theme
static func scale_theme(theme: Theme) -> Theme:
	var scaled: Array
	for node_type in theme.get_type_list(""):
		for name in theme.get_constant_list(node_type):
			var constant: int = theme.get_constant(name, node_type)
			theme.set_constant(name, node_type, scale_number(constant))

		for name in theme.get_stylebox_list(node_type):
			var sb = theme.get_stylebox(name, node_type)
			if ! scaled.has(sb):
				scaled.append(sb)
				scale_stylebox(sb)

		for name in theme.get_font_list(node_type):
			var fn = theme.get_font(name, node_type)
			if ! scaled.has(fn):
				scaled.append(fn)
				scale_font(fn)
	if theme.default_font && ! scaled.has(theme.default_font):
		scale_font(theme.default_font)
	return theme

## This applies all values to the `out` theme
## Keeps the out values that are not overridden by the other themes
## @param themes: Array<Theme>
static func apply_themes(out: Theme, themes: Array) -> Theme:
	for theme in themes:
		for node_type in theme.get_type_list(""):
			for name in theme.get_color_list(node_type):
				out.set_color(name, node_type, theme.get_color(name, node_type))
			for name in theme.get_constant_list(node_type):
				out.set_constant(name, node_type, theme.get_constant(name, node_type))
			for name in theme.get_font_list(node_type):
				out.set_font(name, node_type, theme.get_font(name, node_type))
			for name in theme.get_icon_list(node_type):
				out.set_icon(name, node_type, theme.get_icon(name, node_type))
			for name in theme.get_stylebox_list(node_type):
				out.set_stylebox(name, node_type, theme.get_stylebox(name, node_type))
		if theme.default_font:
			out.default_font = theme.default_font
	return out
