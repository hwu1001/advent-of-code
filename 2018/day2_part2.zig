const std = @import("std");

// Based on the problem prompt I'm making a few assumptions:
// 1. There are no duplicate IDs
// 2. There are not multiple IDs that are one character away
//    (meaning there's only one correct, unique pair)
pub fn main() !void {
    var file = try std.os.File.openRead("./day2_input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var list = std.ArrayList(std.ArrayList(u8)).init(&direct_alloc.allocator);
    defer list.deinit();

    var done: bool = false;
    while (!done) {
        // I think it would be more efficient to just read it all at once and use
        // std.mem.split on '\n' then iterate over that, but I started with this way
        // so I'll leave for now
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch (err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        // Clean this up later
        var one_line = std.ArrayList(u8).init(&direct_alloc.allocator);
        for (buf.toSliceConst()) |val| {
            try one_line.append(val);
        }
        try list.append(one_line);
    }
    
    var lowest_score: u64 = std.math.maxInt(u64);
    var index_one: usize = undefined;
    var index_two: usize = undefined;
    const slice = list.toSlice();
    for (slice) |line, i| {
        for (slice[i + 1..]) |line_two, j| {
            var score = getDiffCount(line.toSlice(), line_two.toSlice());
            if (score < lowest_score) {
                lowest_score = score;
                index_one = i;
                index_two = i + 1 + j;
            }
        }
    }
    std.debug.warn("{}\n", lowest_score);
    std.debug.warn("string {} index {}\n", list.at(index_one).toSlice(), index_one);
    std.debug.warn("string {} index {}\n", list.at(index_two).toSlice(), index_two);
    std.debug.warn("common letters\n");
    var temp: [1]u8 = undefined;
    for (list.at(index_one).toSlice()) |char, ndx| {
        if (char == list.at(index_two).at(ndx)) {
            // Bit of a hack, but debug.warn will print the unsigned integer
            // with just a u8, but with []u8 it prints the character
            temp[0] = char;
            std.debug.warn("{}", temp[0..]);
        }
    }
    std.debug.warn("\n");
    // cleanup
    for (list.toSlice()) |line| {
        line.deinit();
    }
}

// assumes that strings are of equal length
fn getDiffCount(str1: []u8, str2: []u8) u64 {
    var count: u64 = 0;
    var index: usize = 0;
    while (index < str1.len) : (index += 1) {
        count += @boolToInt(str1[index] != str2[index]);
    }
    return count;
}