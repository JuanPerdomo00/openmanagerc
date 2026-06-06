// Openmanagerc
// Copyright (C) 2026  jakepys
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

package main

import "core:strconv"
import "core:strings"
import raylib "vendor:raylib"


Buttom :: struct {
	rect:  raylib.Rectangle,
	label: cstring,
}

vec2 :: proc(x, y: i32) -> raylib.Vector2 {
	return {f32(x), f32(y)}
}

draw_buttom :: proc(app: ^App, btn: Buttom) -> bool {
	mouse := raylib.GetMousePosition()
	hovered := raylib.CheckCollisionPointRec(mouse, btn.rect)
	color := COL_BTN_HOV if hovered else COL_BTN

	raylib.DrawRectangleRec(btn.rect, color)
	raylib.DrawRectangleLinesEx(btn.rect, 1, raylib.Color{100, 130, 200, 255})

	tw := raylib.MeasureTextEx(app.font_sm, btn.label, f32(FONT_SM), 1)
	tx := btn.rect.x + (btn.rect.width - tw.x) / 2
	ty := btn.rect.y + (btn.rect.height - tw.y) / 2
	raylib.DrawTextEx(app.font_sm, btn.label, {tx, ty}, f32(FONT_SM), 1, COL_TEXT)

	return hovered && raylib.IsMouseButtonPressed(.LEFT)
}

draw_tabs :: proc(app: ^App) {
	tab_w := i32(140)
	labels := []cstring{"Services", "Boot Logs"}

	raylib.DrawRectangle(0, 0, WINDOW_W, TAB_H, COL_TAB_BAR)

	for label, i in labels {
		x := i32(i) * tab_w
		is_active := app.active_tab == Tab(i)

		bg := COL_TAB_ACT if is_active else COL_TAB_BAR
		raylib.DrawRectangle(x, 0, tab_w, TAB_H, bg)

		if is_active {
			raylib.DrawRectangle(x, TAB_H - 2, tab_w, 2, COL_TAB_LINE)
		}

		raylib.DrawTextEx(app.font_sm, label, vec2(x + 12, 11), f32(FONT_SM), 1, COL_TEXT)

		tab_rect := raylib.Rectangle{f32(x), 0, f32(tab_w), f32(TAB_H)}
		mouse := raylib.GetMousePosition()
		if raylib.CheckCollisionPointRec(mouse, tab_rect) && raylib.IsMouseButtonPressed(.LEFT) {
			app.active_tab = Tab(i)
		}
	}
}

status_color :: proc(status: string) -> raylib.Color {
	if strings.contains(status, "started") do return COL_GREEN
	if strings.contains(status, "stopped") do return COL_RED
	return COL_YELLOW
}

draw_table :: proc(app: ^App) {
	raylib.DrawRectangle(0, TABLE_Y, WINDOW_W, ROW_H, COL_HEADER)
	raylib.DrawTextEx(app.font_sm, "Service", vec2(12, TABLE_Y + 5), f32(FONT_SM), 1, COL_DIM)
	raylib.DrawTextEx(
		app.font_sm,
		"Runlevel",
		vec2(12 + COL_NAME_W, TABLE_Y + 5),
		f32(FONT_SM),
		1,
		COL_DIM,
	)
	raylib.DrawTextEx(
		app.font_sm,
		"Status",
		vec2(12 + COL_NAME_W + COL_LEVEL_W, TABLE_Y + 5),
		f32(FONT_SM),
		1,
		COL_DIM,
	)

	table_body_y := TABLE_Y + ROW_H
	table_body_h := WINDOW_H - table_body_y - 50
	visible_rows := int(table_body_h / ROW_H)

	for i in 0 ..< visible_rows {
		svc_idx := i + app.scroll_offset
		if svc_idx >= len(app.services) do break

		svc := app.services[svc_idx]
		row_y := table_body_y + i32(i) * ROW_H

		bg: raylib.Color
		if svc_idx == app.selected_row {
			bg = COL_ROW_SEL
		} else if i % 2 == 0 {
			bg = COL_ROW_A
		} else {
			bg = COL_ROW_B
		}
		raylib.DrawRectangle(0, row_y, WINDOW_W, ROW_H, bg)

		name_cs := strings.clone_to_cstring(svc.name)
		defer delete(name_cs)
		level_cs := strings.clone_to_cstring(svc.runlevel)
		defer delete(level_cs)
		status_cs := strings.clone_to_cstring(svc.status)
		defer delete(status_cs)

		raylib.DrawTextEx(app.font_sm, name_cs, vec2(12, row_y + 5), f32(FONT_SM), 1, COL_TEXT)
		raylib.DrawTextEx(
			app.font_sm,
			level_cs,
			vec2(12 + COL_NAME_W, row_y + 5),
			f32(FONT_SM),
			1,
			COL_DIM,
		)
		raylib.DrawTextEx(
			app.font_sm,
			status_cs,
			vec2(12 + COL_NAME_W + COL_LEVEL_W, row_y + 5),
			f32(FONT_SM),
			1,
			status_color(svc.status),
		)

		row_rect := raylib.Rectangle{0, f32(row_y), f32(WINDOW_W), f32(ROW_H)}
		mouse := raylib.GetMousePosition()
		if raylib.CheckCollisionPointRec(mouse, row_rect) && raylib.IsMouseButtonPressed(.LEFT) {
			app.selected_row = svc_idx
		}
	}

	if len(app.services) > visible_rows {
		sb_h := i32(visible_rows) * table_body_h / i32(len(app.services))
		sb_y := table_body_y + i32(app.scroll_offset) * table_body_h / i32(len(app.services))
		raylib.DrawRectangle(WINDOW_W - 6, sb_y, 4, sb_h, raylib.Color{80, 90, 140, 255})
	}

	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 {
		max_scroll := len(app.services) - visible_rows
		if max_scroll < 0 do max_scroll = 0
		app.scroll_offset -= int(wheel)
		if app.scroll_offset < 0 do app.scroll_offset = 0
		if app.scroll_offset > max_scroll do app.scroll_offset = max_scroll
	}
}

draw_logs :: proc(app: ^App) {
	raylib.DrawRectangle(
		0,
		TABLE_Y,
		WINDOW_W,
		WINDOW_H - TABLE_Y - 50,
		raylib.Color{18, 18, 24, 255},
	)

	body_y := TABLE_Y + 4
	body_h := WINDOW_H - TABLE_Y - 54
	visible_rows := int(body_h / ROW_H)

	for i in 0 ..< visible_rows {
		line_idx := i + app.log_scroll
		if line_idx >= len(app.log_lines) do break

		line := app.log_lines[line_idx]
		row_y := body_y + i32(i) * ROW_H

		color: raylib.Color
		if strings.contains(line, "ERROR") || strings.contains(line, "error") {
			color = COL_RED
		} else if strings.contains(line, "WARNING") || strings.contains(line, "warn") {
			color = COL_YELLOW
		} else if strings.contains(line, "started") || strings.contains(line, "start") {
			color = COL_GREEN
		} else {
			color = raylib.Color{160, 170, 190, 255}
		}

		line_cs := strings.clone_to_cstring(line)
		defer delete(line_cs)
		raylib.DrawTextEx(app.font_sm, line_cs, vec2(12, row_y + 4), f32(FONT_SM), 1, color)
	}

	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 {
		max_scroll := len(app.log_lines) - visible_rows
		if max_scroll < 0 do max_scroll = 0
		app.log_scroll -= int(wheel)
		if app.log_scroll < 0 do app.log_scroll = 0
		if app.log_scroll > max_scroll do app.log_scroll = max_scroll
	}

	total_cs := strings.clone_to_cstring(
		strings.concatenate(
			{"Lines: ", strconv.write_int(make([]byte, 16), cast(i64)len(app.log_lines), 10)},
		),
	)
	defer delete(total_cs)
	raylib.DrawTextEx(
		app.font_sm,
		total_cs,
		vec2(WINDOW_W - 120, TABLE_Y + 6),
		f32(FONT_SM),
		1,
		COL_DIM,
	)
}
draw_disclaimer :: proc(app: ^App) {
	raylib.DrawRectangle(0, 0, WINDOW_W, WINDOW_H, raylib.Color{0, 0, 0, 180})

	box_w := i32(520)
	box_h := i32(280)
	box_x := (WINDOW_W - box_w) / 2
	box_y := (WINDOW_H - box_h) / 2

	raylib.DrawRectangle(box_x, box_y, box_w, box_h, raylib.Color{28, 28, 40, 255})
	raylib.DrawRectangleLinesEx(
		raylib.Rectangle{f32(box_x), f32(box_y), f32(box_w), f32(box_h)},
		2,
		raylib.Color{100, 130, 200, 255},
	)

	raylib.DrawTextEx(
		app.font,
		"  Security Warning",
		vec2(box_x + 20, box_y + 20),
		f32(FONT_SIZE),
		1,
		COL_RED,
	)

	raylib.DrawRectangle(box_x + 20, box_y + 46, box_w - 40, 1, raylib.Color{60, 60, 80, 255})

	lines := []cstring {
		"This tool can start, stop and delete system services.",
		"Modifying critical services may prevent your system",
		"from booting correctly on next startup.",
		"",
		"Use it only if you know what you are doing.",
	}
	for line, i in lines {
		color := COL_DIM if line == "" else COL_TEXT
		raylib.DrawTextEx(
			app.font_sm,
			line,
			vec2(box_x + 20, box_y + 60 + i32(i) * 22),
			f32(FONT_SM),
			1,
			color,
		)
	}

	cb_x := box_x + 20
	cb_y := box_y + box_h - 80

	raylib.DrawRectangleLinesEx(raylib.Rectangle{f32(cb_x), f32(cb_y), 16, 16}, 1, COL_TEXT)
	if app.disclaimer_check {
		raylib.DrawRectangle(cb_x + 3, cb_y + 3, 10, 10, COL_GREEN)
	}
	raylib.DrawTextEx(
		app.font_sm,
		"I understand the risks and will be careful",
		vec2(cb_x + 24, cb_y + 1),
		f32(FONT_SM),
		1,
		COL_TEXT,
	)

	cb_rect := raylib.Rectangle{f32(cb_x), f32(cb_y), 200, 18}
	mouse := raylib.GetMousePosition()
	if raylib.CheckCollisionPointRec(mouse, cb_rect) && raylib.IsMouseButtonPressed(.LEFT) {
		app.disclaimer_check = !app.disclaimer_check
	}

	btn_y := box_y + box_h - 48

	exit_btn := Buttom {
		rect  = {f32(box_x + 20), f32(btn_y), 110, f32(BTN_H)},
		label = "Exit",
	}
	proceed_btn := Buttom {
		rect  = {f32(box_x + box_w - 140), f32(btn_y), 120, f32(BTN_H)},
		label = "Proceed",
	}

	if draw_buttom(app, exit_btn) {
		app.running = false
	}

	if app.disclaimer_check {
		if draw_buttom(app, proceed_btn) {
			app.disclaimer_done = true
		}
	} else {
		raylib.DrawRectangleRec(proceed_btn.rect, raylib.Color{40, 40, 55, 255})
		raylib.DrawRectangleLinesEx(proceed_btn.rect, 1, raylib.Color{60, 60, 80, 255})
		raylib.DrawTextEx(
			app.font_sm,
			"Proceed",
			vec2(i32(proceed_btn.rect.x) + 28, i32(proceed_btn.rect.y) + 9),
			f32(FONT_SM),
			1,
			raylib.Color{80, 80, 100, 255},
		)
	}
}
