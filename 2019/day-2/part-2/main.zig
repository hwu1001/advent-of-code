const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input2.txt", .{});
    defer file.close();
    const file_in_stream = &file.inStream().stream;

    var buf: [2048]u8 = undefined;
    var orig_codes: [2048]usize = undefined;
    var codes: [2048]usize = undefined;
    var len: usize = 0;

    // Save an original copy so we don't have to re-read the file each time
    while (try file_in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.separate(line, ",");
        while (iter.next()) |val| {
            orig_codes[len] = try std.fmt.parseInt(usize, val, 10);
            codes[len] = orig_codes[len];
            len += 1;
        }
    }

    var noun: usize = 0;
    while (noun < 100) : (noun += 1) {
        var verb: usize = 0;
        while (verb < 100) : (verb += 1) {
            codes[1] = noun;
            codes[2] = verb;

            var index: usize = 0;
            var pos: usize = 0;
            var int_code = IntCode {
                .opcode = undefined,
                .pos1 = undefined,
                .pos2 = undefined,
                .overwrite_pos = undefined,
            };
            while (index < len) {
                var val = codes[index];
                switch(pos) {
                    0 => {
                        if (val == 1 or val == 2 or val == 99) {
                            int_code.opcode = val;
                        } else {
                            std.debug.warn("!!! INVALID OPCODE: {} !!!", val);
                        }
                        if (int_code.opcode == 99) {
                            break;
                        }
                    },
                    1 => {
                        int_code.pos1 = val;
                    },
                    2 => {
                        int_code.pos2 = val;
                    },
                    3 => {
                        int_code.overwrite_pos = val;
                    },
                    else => unreachable,
                }
                pos += 1;
                index += 1;
                // If we're at the last position in the set - 3
                // then process the instructions and reset the int codes
                if (pos > 3) {
                    if (int_code.opcode == 1) {
                        codes[int_code.overwrite_pos] = codes[int_code.pos1] + codes[int_code.pos2];
                    } else if (int_code.opcode == 2) {
                        codes[int_code.overwrite_pos] = codes[int_code.pos1] * codes[int_code.pos2];
                    }
                    pos = 0;
                }
            }

            if (codes[0] == 19690720) {
                std.debug.warn("FOUND CODE, NOUN: {}, VERB: {}\n", codes[1], codes[2]);
                std.debug.warn("CODE: {}\n", 100 * codes[1] + codes[2]);
            }
            // Reset codes
            index = 0;
            while (index < len) : (index += 1) {
                codes[index] = orig_codes[index];
            }
        }
    }
}

const IntCode = struct {
    opcode: usize,
    pos1: usize,
    pos2: usize,
    overwrite_pos: usize,
};