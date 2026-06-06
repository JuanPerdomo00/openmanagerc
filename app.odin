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

import raylib "vendor:raylib"


COLOR_BG :: raylib.Color{30, 30, 35, 255} //  #1E1E23
COL_TAB_BAR :: raylib.Color{22, 22, 30, 255} // #16161E
COL_TAB_ACT :: raylib.Color{50, 70, 130, 255} // #324682
COL_TAB_LINE :: raylib.Color{100, 140, 255, 255} // #648CFF
COL_TEXT :: raylib.Color{220, 220, 220, 255} // #DCDCDC
COL_DIM :: raylib.Color{130, 130, 150, 255} // #828296
COL_BTN :: raylib.Color{50, 70, 120, 255} // #324678
COL_BTN_HOV :: raylib.Color{70, 100, 170, 255} //  #4664AA
COL_ROW_A :: raylib.Color{28, 28, 38, 255} //  #1C1C26
COL_ROW_B :: raylib.Color{33, 33, 45, 255} // #21212D
COL_ROW_SEL :: raylib.Color{55, 75, 140, 255} //  #370F8C
COL_HEADER :: raylib.Color{40, 45, 65, 255} // #282D41
COL_GREEN :: raylib.Color{80, 200, 120, 255} // #50C878
COL_RED :: raylib.Color{200, 80, 80, 255} // #C85050
COL_YELLOW :: raylib.Color{200, 180, 60, 255} //  #C8B43C


WINDOW_W :: i32(850)
WINDOW_H :: i32(550)
TAB_H :: i32(38)
ROW_H :: i32(26)
BTN_H :: i32(34)
FONT_SIZE :: i32(16)
FONT_SM :: i32(13)

TABLE_Y :: i32(42)
COL_NAME_W :: i32(300)
COL_LEVEL_W :: i32(160)

Tab :: enum {
	Services,
	Logs,
}

App :: struct {
	running:          bool,
	active_tab:       Tab,
	services:         [dynamic]Service,
	selected_row:     int,
	scroll_offset:    int,
	font:             raylib.Font,
	font_sm:          raylib.Font,
	log_lines:        [dynamic]string,
	log_size:         i64,
	log_scroll:       int,
	disclaimer_done:  bool,
	disclaimer_check: bool,
}
