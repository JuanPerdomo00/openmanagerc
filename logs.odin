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

import "core:os"
import "core:strings"

LOG_PATH :: "/var/log/rc.log"

poll_logs :: proc(app: ^App) -> bool {
	info, err := os.stat(LOG_PATH, context.allocator)
	if err != os.ERROR_NONE do return false

	current_size := i64(info.size)
	if current_size == app.log_size do return false

	fd, open_err := os.open(LOG_PATH, os.O_RDONLY)
	if open_err != os.ERROR_NONE do return false
	defer os.close(fd)

	os.seek(fd, app.log_size, .Start)

	new_bytes := make([]byte, current_size - app.log_size)
	defer delete(new_bytes)

	n, _ := os.read(fd, new_bytes)
	if n <= 0 do return false

	app.log_size = current_size

	chunk := string(new_bytes[:n])
	lines := strings.split(chunk, "\n")
	defer delete(lines)

	for line in lines {
		line := strings.trim_space(line)
		if line == "" do continue
		append(&app.log_lines, strings.clone(line))
	}

	for len(app.log_lines) > 500 {
		delete(app.log_lines[0])
		ordered_remove(&app.log_lines, 0)
	}

	return true
}

free_logs :: proc(app: ^App) {
	for line in app.log_lines {
		delete(line)
	}
	delete(app.log_lines)
}

init_logs :: proc(app: ^App) {
	app.log_lines = make([dynamic]string)

	info, err := os.stat(LOG_PATH, context.allocator)
	if err != os.ERROR_NONE do return

	app.log_size = i64(info.size)

	fd, open_err := os.open(LOG_PATH, os.O_RDONLY)
	if open_err != os.ERROR_NONE do return
	defer os.close(fd)

	data := make([]byte, app.log_size)
	defer delete(data)

	n, _ := os.read(fd, data)
	if n <= 0 do return

	lines := strings.split(string(data[:n]), "\n")
	defer delete(lines)

	start := 0
	if len(lines) > 100 do start = len(lines) - 100

	for line in lines[start:] {
		line := strings.trim_space(line)
		if line == "" do continue
		append(&app.log_lines, strings.clone(line))
	}

	app.log_scroll = max(0, len(app.log_lines) - 1)
}
