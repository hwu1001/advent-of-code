const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./day2_input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var hash_map = std.AutoHashMap(u8, i64).init(&direct_alloc.allocator);
    defer hash_map.deinit();

    var done: bool = false;
    var two_freq: i64 = 0;
    var three_freq: i64 = 0; 
    while (!done) {
        var found_two: bool = false;
        var found_three: bool = false;
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch (err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        // std.debug.warn("process one line\n");
        for (buf.toSlice()) |char| {
            var map_val = hash_map.get(char);
            if (map_val != null) {
                _ = try hash_map.put(char, map_val.?.value + 1);
            }
            else {
                _ = try hash_map.put(char, 1);
            }
        }
        var iter = hash_map.iterator();
        while (iter.next()) |entry| {
            if (entry.value == 2) {
                found_two = true;
            }
            if (entry.value == 3) {
                found_three = true;
            }
        }
        // std.debug.warn("{}\n", buf.toSlice());

        if (found_two) {
            two_freq += 1;
        }
        if (found_three) {
            three_freq += 1;
        }
        hash_map.clear();
        buf.shrink(0);
    }
    std.debug.warn("{}\n", two_freq * three_freq);
}