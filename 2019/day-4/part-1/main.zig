const std = @import("std");

pub fn main() !void {
    var low: usize = 382345;
    var high: usize = 843167;
    var buf = try std.Buffer.init(std.heap.page_allocator, "");
    var count: usize = 0;
    while (low <= high) : (low += 1) {
        try std.fmt.formatIntValue(low, "", std.fmt.FormatOptions{}, &buf, @typeOf(std.Buffer.append).ReturnType.ErrorSet, std.Buffer.append);
        var two_digit_seq = false;
        var always_increasing = true; 
        var prev_digit: u8 = buf.toSliceConst()[0];
        for (buf.toSliceConst()[1..]) |digit| {
            if (!always_increasing) {
                break;
            }
            if (!two_digit_seq) {
                two_digit_seq = digit == prev_digit;
            }
            always_increasing = prev_digit <= digit;
            prev_digit = digit;
        }
        if (two_digit_seq and always_increasing) {
            count += 1;
        }
        buf.shrink(0);
    }
    std.debug.warn("Number of passwords: {}\n", count);
}