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

import "core:fmt"
import "core:os"
import "core:strings"


Service :: struct {
	name:     string,
	runlevel: string,
	status:   string,
}


run_cmd :: proc(cmd: string, args: []string) -> (output: string, ok: bool) {
	full_args := make([]string, len(args) + 1)
	defer delete(full_args)

	full_args[0] = cmd

	for arg, i in args {
		full_args[i + 1] = arg
	}

	desc := os.Process_Desc {
		command = full_args,
	}


	state, stdout, _, err := os.process_exec(desc, context.allocator)

	if err != nil {
		fmt.eprintln("run_cmd error: ", err)
		return "", false
	}

	if !state.success {
		delete(stdout)
		return "", false
	}

	return string(stdout), true
}


load_services :: proc() -> [dynamic]Service {
	services := make([dynamic]Service)

	output, ok := run_cmd("rc-status", {"--all"})
	if !ok {
		fmt.eprintln("Error to run rc-status")
		return services
	}

	defer delete(output)

	current_runlevel := "unknown"
	lines := strings.split(output, "\n")
	defer delete(lines)

	for line in lines {
		line := strings.trim_space(line)
		if line == "" do continue

		if strings.contains(line, "Runlevel: ") {
			parts := strings.split(line, ":")
			defer delete(parts)

			if len(parts) >= 2 {
				current_runlevel = strings.clone(strings.trim_space(parts[1]))
			}
			continue
		}

		if strings.contains(line, "[") && strings.contains(line, "]") {
			bracket_index := strings.index(line, "[")
			name := strings.trim_space(line[:bracket_index])
			rest := line[bracket_index:]
			close_bracket := strings.index(rest, "]")
			status := strings.trim_space(rest[1:close_bracket])

			if name == "" do continue

			append(
				&services,
				Service {
					name = strings.clone(name),
					runlevel = strings.clone(current_runlevel),
					status = strings.clone(status),
				},
			)
		}
	}

	return services

}


free_services :: proc(services: ^[dynamic]Service) {
	for svc in services {
		delete(svc.name)
		delete(svc.runlevel)
		delete(svc.status)
	}

	delete(services^)
}

service_action :: proc(name: string, action: string) -> bool {
	_, ok := run_cmd("rc-service", {name, action})
	return ok
}


service_del :: proc(name: string, runlevel: string) -> bool {
	_, ok := run_cmd("rc-update", {"del", name, runlevel})
	return ok
}
