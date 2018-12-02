const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./day1_input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var res: i64 = 0;
    var done: bool = false;
    while (!done) {
        // TODO is there some other way to write this loop?
        // Also what should I be using as max_size here? What I expect the length of the largest
        // int in the file to be?
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 100) catch |err| switch (err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        res += try std.fmt.parseInt(i64, buf.toSlice(), 10);
        std.debug.warn("{}\n", res);
        buf.shrink(0); // reset for each line
    }
}