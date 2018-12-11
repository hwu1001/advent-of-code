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
        try coords.append(Point{.x = x, .y = y, .area = 0, .infinite = false});
    }

    var i: usize = 0;
    while(i <= largest_num) : (i += 1) {
        var j: usize = 0;
        while(j <= largest_num) : (j += 1) {
            try closestPoint(coords.toSlice(), i, j, largest_num, &direct_alloc.allocator);
        }
    }
    var n: usize = 0;
    var largest_area: usize = 0;
    for (coords.toSlice()) |coord, x| {
        // assuming no duplicate coordinates
        if (!coord.infinite and coord.area > largest_area) {
            largest_area = coord.area;
            n = x;
            std.debug.warn("{}\n", coord);
        }
    }
    std.debug.warn("largest area {}\n", coords.at(n));
}

fn closestPoint(coords: []Point, x: usize, y: usize, largest_num: usize, alloc: *std.mem.Allocator) !void {
    var add: bool = true;
    var lowest: usize = std.math.maxInt(usize);
    var index: usize = undefined;
    
    var dists = std.ArrayList(usize).init(alloc);
    defer dists.deinit();

    for (coords) |coord, i| {
        var manhattan_dist = calcManhattanDist(coord.x, coord.y, x, y);
        if (manhattan_dist <= lowest) {
            try dists.append(manhattan_dist);
            lowest = manhattan_dist;
            index = i;
        }
    }
    // If another coordinate has the same as the lowest one then throw an error so we don't log this point
    var count: usize = 0;
    for (dists.toSlice()) |val| {
        if (val == lowest) {
            count += 1;
        }
        if (count > 1) {
            add = false;
            break;
        }
    }

    if (add) {
        if (x == 0 or y == 0 or x == largest_num or y == largest_num) {
            coords[index].infinite = true;
        }
        coords[index].area += 1;
    }
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
    area: usize,
    infinite: bool,
};

const PointIndex = struct {
    index: usize,
    add: bool,
};