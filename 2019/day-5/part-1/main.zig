const std = @import("std");

// This code is absolute spaghetti
pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();
    const file_in_stream = &file.inStream().stream;
    var buf: [4096]u8 = undefined;
    var codes = std.ArrayList(std.ArrayList(u8)).init(std.heap.page_allocator);
    defer codes.deinit();

    while (try file_in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.separate(line, ",");
        while (iter.next()) |code| {
            var list = std.ArrayList(u8).init(std.heap.page_allocator);
            for (code) |val| {
                try list.append(val);
            }
            try codes.append(list);
        }
    }

    var code_index: usize = 0; // which code we're processing
    var instruction_pos: usize = 0;
    var char: [1]u8 = undefined;
    // By default the parameter mode is 0 - position (rather than 1 - immediate)
    var int_code = IntCode {
        .opcode = undefined,
        .num_params = undefined,
        .param1 = undefined,
        .param1_mode = 0,
        .param2 = undefined,
        .param2_mode = 0,
        .overwrite_pos = undefined,
        .pos_mode = 0,
    };
    
    while (code_index < codes.count()) {
        var first_instruction = codes.at(code_index);
        var digits_in_inst = first_instruction.count();
        if (digits_in_inst == 1) {
            // If we just have one digit then we just have the opcode and all modes are 0
            char[0] = first_instruction.at(0);
            int_code.opcode = try std.fmt.parseInt(usize, char[0..], 10);
            int_code.param1_mode = 0;
            int_code.param2_mode = 0;
            int_code.pos_mode = 0;
            switch(int_code.opcode) {
                1, 2 => {
                    int_code.num_params = 3;
                },
                3, 4 => {
                    int_code.num_params = 1;
                },
                99 => {
                    int_code.num_params = 0;
                },
                else => unreachable,
            }
        } else {
            // Get the opcode (the first two digits from right to left)
            char[0] = first_instruction.at(first_instruction.count() - 2);
            const second_to_last = try std.fmt.parseInt(usize, char[0..], 10);
            char[0] = first_instruction.at(first_instruction.count() - 1);
            const last = try std.fmt.parseInt(usize, char[0..], 10);
            int_code.opcode = (second_to_last * 10) + last;
            switch(int_code.opcode) {
                1, 2 => {
                    int_code.num_params = 3;
                },
                3, 4 => {
                    int_code.num_params = 1;
                },
                99 => {
                    int_code.num_params = 0;
                },
                else => unreachable,
            }
            // Get the parameter modes (default is 0)
            var digits_left = first_instruction.count() - 2; // minutes two since the first two are always the opcode
            switch(digits_left) {
                0 => {
                    int_code.param1_mode = 0;
                    int_code.param2_mode = 0;
                    int_code.pos_mode = 0;
                },
                1 => {
                    char[0] = first_instruction.at(first_instruction.count() - 3);
                    int_code.param1_mode = try std.fmt.parseInt(usize, char[0..], 10);
                    int_code.param2_mode = 0;
                    int_code.pos_mode = 0;
                },
                2 => {
                    char[0] = first_instruction.at(first_instruction.count() - 3);
                    int_code.param1_mode = try std.fmt.parseInt(usize, char[0..], 10);
                    char[0] = first_instruction.at(first_instruction.count() - 4);
                    int_code.param2_mode = try std.fmt.parseInt(usize, char[0..], 10);
                    int_code.pos_mode = 0;
                },
                3 => {
                    char[0] = first_instruction.at(first_instruction.count() - 3);
                    int_code.param1_mode = try std.fmt.parseInt(usize, char[0..], 10);
                    char[0] = first_instruction.at(first_instruction.count() - 4);
                    int_code.param2_mode = try std.fmt.parseInt(usize, char[0..], 10);
                    char[0] = first_instruction.at(first_instruction.count() - 5);
                    int_code.pos_mode = try std.fmt.parseInt(usize, char[0..], 10);
                },
                else => unreachable,
            }
        }
        // Since we've finished with the first number in the instruction set increase position
        code_index += 1;
        var processed_params: usize = 0;
        while (processed_params < int_code.num_params) {
            var cur_instruction = codes.at(code_index);
            switch(processed_params) {
                0 => {
                    int_code.param1 = try std.fmt.parseInt(i64, cur_instruction.toSliceConst(), 10);
                },
                1 => {
                    int_code.param2 = try std.fmt.parseInt(i64, cur_instruction.toSliceConst(), 10);
                },
                2 => {
                    int_code.overwrite_pos = try std.fmt.parseInt(usize, cur_instruction.toSliceConst(), 10);
                },
                else => unreachable,
            }
            processed_params += 1;
            code_index += 1;
        }
        // Evaluate the instruction with the parameters and parameter modes
        switch(int_code.opcode) {
            1 => { // add
                var param1_val = try getParamValFromMode(&codes, int_code.param1_mode, int_code.param1);
                var param2_val = try getParamValFromMode(&codes, int_code.param2_mode, int_code.param2);
                var res = param1_val + param2_val;
                var size = numDigits(res);
                var list = codes.at(int_code.overwrite_pos);
                try list.resize(size);
                _ = bufPrintIntToSlice(list.toSlice(), res, 10, false, std.fmt.FormatOptions{});
                codes.set(int_code.overwrite_pos, list);
            },
            2 => { // multiply
                var param1_val = try getParamValFromMode(&codes, int_code.param1_mode, int_code.param1);
                var param2_val = try getParamValFromMode(&codes, int_code.param2_mode, int_code.param2);
                var res = param1_val * param2_val;
                var size = numDigits(res);
                var list = codes.at(int_code.overwrite_pos);
                try list.resize(size);
                _ = bufPrintIntToSlice(list.toSlice(), res, 10, false, std.fmt.FormatOptions{});
                codes.set(int_code.overwrite_pos, list);
            },
            3 => { // input
                var unsigned_val = usizeFromi64(int_code.param1);
                var target_inst = codes.at(unsigned_val);
                target_inst.shrink(0);
                try target_inst.append('1');
                codes.set(unsigned_val, target_inst);
            },
            4 => { // output
                var param1_val = try getParamValFromMode(&codes, int_code.param1_mode, int_code.param1);
                std.debug.warn("!!!output: {}\n", param1_val);
            },
            99 => {
                break;
            },
            else => unreachable,
        }
    }
    for (codes.toSlice()) |v| {
        v.deinit();
    }
}

fn getParamValFromMode(codes: *std.ArrayList(std.ArrayList(u8)), mode: usize, param_val: i64) !i64 {
    var ret = switch(mode) {
        0 => try std.fmt.parseInt(i64, codes.at(usizeFromi64(param_val)).toSliceConst(), 10),
        1 => param_val,
        else => unreachable,
    };
    return ret;
}

// There's probably a better way to do this, but works for this problem >:)
fn usizeFromi64(val: i64) usize {
    var ret: usize = 0;
    std.debug.assert(val >= 0);
    var v = val;
    while(v > 0) : (v -= 1) {
        ret += 1;
    }
    return ret;
}

fn numDigits(val: i64) usize {
    if (val == 0) {
        return 1;
    }
    var v = val;
    var count: usize = 0;
    while (v != 0) : (v = @divFloor(v, 10)) {
        count += 1;
    }
    return count;
}

fn bufPrintIntToSlice(buf: []u8, value: var, base: u8, uppercase: bool, options: std.fmt.FormatOptions) []u8 {
    return buf[0..std.fmt.formatIntBuf(buf, value, base, uppercase, options)];
}

const IntCode = struct {
    opcode: usize,
    num_params: usize,
    // Used with: input - 3 and output - 4
    param1: i64,
    param1_mode: usize,
    // Used with: add - 1 and multiply - 2
    param2: i64,
    param2_mode: usize,
    // Used with: add - 1 and multiply - 2
    overwrite_pos: usize,
    pos_mode: usize
};

// 3,7,1,7,6,6,98,5
// 1002,4,3,4,33
// 3,0,4,0,99
// 1101,100,-1,4,0