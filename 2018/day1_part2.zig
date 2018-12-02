const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./day1_input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    // Prepare stream, buffer, hash, and list
    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var hash_map = std.AutoHashMap(i64, void).init(&direct_alloc.allocator);
    defer hash_map.deinit();
    // I don't know how to reset the stream to read the file again, so just save
    // to an array for now
    var list = std.ArrayList(i64).init(&direct_alloc.allocator);
    defer list.deinit();

    var done: bool = false;
    var found: bool = false;
    var freq: i64 = 0;
    while (!done) {
        // TODO is there some other way to write this loop?
        // Also what should I be using as max_size here? What I expect the length of the largest
        // int in the file to be?
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 100) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        const val = try std.fmt.parseInt(i64, buf.toSlice(), 10);
        freq += val;
        try list.append(val);
        if (hash_map.contains(freq)) {
            found = true;
            break;
        }
        _ = try hash_map.put(freq, {});
        buf.shrink(0); // reset for each line
    }
    while (!found) {
        for (list.toSlice()) |val| {
            freq += val;
            if (hash_map.contains(freq)) {
                found = true;
                break;
            }
            _ = try hash_map.put(freq, {});
        }
    }
    std.debug.warn("{}\n", freq);
}