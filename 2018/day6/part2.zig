const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var coords = std.ArrayList(Point).init(&direct_alloc.allocator);
    defer coords.deinit();

    const file_in_stream = &file.inStream().stream;
    var done: bool = false;
    var largest_num: usize = 0;
    while(!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', std.math.maxInt(usize)) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        var iter = std.mem.split(buf.toSliceConst(), ",");
        var x: usize = undefined;
        var y: usize = undefined;
        var i: usize = 0;
        while(iter.next()) |val| {
            if (i == 0) {
                x = try std.fmt.parseInt(usize, val[0..], 10);
                if (x > largest_num) {
                    largest_num = x;
                }
            }
            else {
                y = try std.fmt.parseInt(usize, val[1..], 10); // skip the space
                if (y > largest_num) {
                    largest_num = y;
                }
            }
            i += 1;
        }
        try coords.append(Point{.x = x, .y = y});
    }
    var num_locations: usize = 0;
    var i: usize = 0;
    while(i <= largest_num) : (i += 1) {
        var j: usize = 0;
        while(j <= largest_num) : (j += 1) {
            if (isInRegion(coords.toSlice(), i, j)) {
                num_locations += 1;
            }
        }
    }
    std.debug.warn("num locations {}\n", num_locations);
}

fn isInRegion(coords: []Point, x: usize, y: usize) bool {
    var total: usize = 0;
    for (coords) |coord| {
        total += calcManhattanDist(coord.x, coord.y, x, y);
    }
    return total < TOTAL_DIST;
}

fn calcManhattanDist(a: usize, b: usize, c: usize, d: usize) usize {
    // couldn't find a math.abs in std lib and we're not dealing with negative
    // coordinates so this should work
    var x = if (a > c) a - c else c - a;
    var y = if (b > d) b - d else d - b;
    return x + y;
}

const Point = struct {
    x: usize,
    y: usize,
};

const TOTAL_DIST: usize = 10000; // for test_input.txt set to 32