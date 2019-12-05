const std = @import("std");

pub fn main() !void {
    var low: usize = 382345;
    var high: usize = 843167;
    var buf = try std.Buffer.init(std.heap.page_allocator, "");
    defer buf.deinit();
    var count: usize = 0;
    var digit_buf: [6]u8 = undefined;
    var buf_len: usize = 0;

    while (low <= high) : (low += 1) {
        try std.fmt.formatIntValue(low, "", std.fmt.FormatOptions{}, &buf, @typeOf(std.Buffer.append).ReturnType.ErrorSet, std.Buffer.append);
        var two_digit_seq = false;
        var always_increasing = true;
        digit_buf[0] = buf.toSliceConst()[0];
        buf_len += 1;
        var prev_digit: u8 = buf.toSliceConst()[0];
        for (buf.toSliceConst()[1..]) |digit| {
            if (!always_increasing) {
                break;
            }
            if (digit == digit_buf[buf_len - 1]) {
                digit_buf[buf_len] = digit;
                buf_len += 1;
            } else {
                if (!two_digit_seq) {
                    two_digit_seq = buf_len == 2;
                }
                digit_buf[0] = digit;
                buf_len = 1;
            }
            always_increasing = prev_digit <= digit;
            prev_digit = digit;
        }
        // If there's a double at the end of the number then need to check for that
        if (!two_digit_seq) {
            two_digit_seq = buf_len == 2;
        }
        if (two_digit_seq and always_increasing) {
            count += 1;
        }
        buf.shrink(0);
        buf_len = 0;
    }
    std.debug.warn("Number of passwords: {}\n", count);
}

// Guess 126 didn't work - too low