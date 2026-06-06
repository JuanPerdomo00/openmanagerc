// Openmanagerc
// Copyright (C) 2026 jakepys
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


import raylib "vendor:raylib"

FPS :: i32(60)

main :: proc() {
	raylib.InitWindow(WINDOW_W, WINDOW_H, "OpenManagerRC")
	defer raylib.CloseWindow()
	raylib.SetTargetFPS(FPS)


	app := App {
		running      = true,
		active_tab   = .Services,
		selected_row = -1,
	}

	app.font = raylib.LoadFontEx("font.ttf", 16, nil, 0)
	app.font_sm = raylib.LoadFontEx("font.ttf", 13, nil, 0)
	defer raylib.UnloadFont(app.font)
	defer raylib.UnloadFont(app.font_sm)

	raylib.SetTextureFilter(app.font.texture, .BILINEAR)
	raylib.SetTextureFilter(app.font_sm.texture, .BILINEAR)
	app.services = load_services()
	defer free_services(&app.services)

	init_logs(&app)
	defer free_logs(&app)

	buttons := []Buttom {
		{rect = {20, f32(WINDOW_H - 48), 100, f32(BTN_H)}, label = "Start"},
		{rect = {130, f32(WINDOW_H - 48), 100, f32(BTN_H)}, label = "Stop"},
		{rect = {240, f32(WINDOW_H - 48), 110, f32(BTN_H)}, label = "Delete"},
		{rect = {360, f32(WINDOW_H - 48), 110, f32(BTN_H)}, label = "Refresh"},
	}

	log_timer := 0
	for !raylib.WindowShouldClose() {
		log_timer += 1
		if log_timer >= 60 {
			poll_logs(&app)
			visible := int((WINDOW_H - TABLE_Y - 54) / ROW_H)
			max_s := len(app.log_lines) - visible
			if max_s > 0 do app.log_scroll = max_s
			log_timer = 0
		}
		raylib.BeginDrawing()
		raylib.ClearBackground(COLOR_BG)


		if !app.disclaimer_done {
			draw_disclaimer(&app)
		} else {

			draw_tabs(&app)

			switch app.active_tab {
			case .Services:
				draw_table(&app)

				for btn, i in buttons {
					if draw_buttom(&app, btn) {
						switch i {
						case 0:
							if app.selected_row >= 0 {
								service_action(app.services[app.selected_row].name, "start")
								free_services(&app.services)
								app.services = load_services()
							}
						case 1:
							if app.selected_row >= 0 {
								service_action(app.services[app.selected_row].name, "stop")
								free_services(&app.services)
								app.services = load_services()
							}
						case 2:
							if app.selected_row >= 0 {
								svc := app.services[app.selected_row]
								service_del(svc.name, svc.runlevel)
								free_services(&app.services)
								app.services = load_services()
								app.selected_row = -1
							}
						case 3:
							free_services(&app.services)
							app.services = load_services()
							app.selected_row = -1
						}
					}
				}

			case .Logs:
				draw_logs(&app)
			}}

		raylib.EndDrawing()
	}
}
