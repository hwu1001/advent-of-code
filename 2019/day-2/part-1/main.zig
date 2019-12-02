const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();
    const file_in_stream = &file.inStream().stream;
    var buf: [2048]u8 = undefined;
    var codes: [2048]usize = undefined;
    var len: usize = 0;



    while (try file_in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.separate(line, ",");
        while (iter.next()) |val| {
            codes[len] = try std.fmt.parseInt(usize, val, 10);
            len += 1;
        }
    }

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
    std.debug.warn("position 0: {}\n", codes[0]);
}

const IntCode = struct {
    opcode: usize,
    pos1: usize,
    pos2: usize,
    overwrite_pos: usize,
};