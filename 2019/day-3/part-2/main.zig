const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();
    const file_in_stream = &file.inStream().stream;

    var buf: [2048]u8 = undefined;
    var wire_one = std.ArrayList(std.ArrayList(u8)).init(std.heap.page_allocator);
    defer wire_one.deinit();
    var wire_two = std.ArrayList(std.ArrayList(u8)).init(std.heap.page_allocator);
    defer wire_two.deinit();
    var first = true;

    // Create array of commands from file
    while (try file_in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.separate(line, ",");
        while (iter.next()) |val| {
            var list = std.ArrayList(u8).init(std.heap.page_allocator);
            for (val) |v| {
                try list.append(v);
            }
            if (first) {
                try wire_one.append(list);
            } else {
                try wire_two.append(list);
            }
        }
        first = false;
    }

    // Get hash map of all points for both wires
    var wire_one_pts = try getAllPoints(std.heap.page_allocator, &wire_one);
    defer wire_one_pts.deinit();
    var wire_two_pts = try getAllPoints(std.heap.page_allocator, &wire_two);
    defer wire_two_pts.deinit();

    // Get all points in common between both wires
    var pt_set = std.AutoHashMap(Point, i64).init(std.heap.page_allocator);
    defer pt_set.deinit();
    var it = wire_one_pts.iterator();
    while (it.next()) |val| {
        if (wire_two_pts.contains(val.key)) {
            var pt_two = wire_two_pts.get(val.key);
            // Put the sum of the steps into the common points
            _ = try pt_set.put(val.key, val.value + pt_two.?.value);
        }
    }

    var lowest_val: i64 = 0;
    var start = true;
    var it2 = pt_set.iterator();
    while (it2.next()) |kv| {
        var total_steps = kv.value;
        if (start) {
            start = false;
            lowest_val = total_steps;
        }
        if (total_steps < lowest_val) {
            lowest_val = total_steps;
        }
    }
    std.debug.warn("steps: {}\n", lowest_val);


    for (wire_one.toSlice()) |v| {
        v.deinit();
    }
    for (wire_two.toSlice()) |v| {
        v.deinit();
    }
}

fn getAllPoints(allocator: *std.mem.Allocator, wire: *std.ArrayList(std.ArrayList(u8))) !std.AutoHashMap(Point, i64) {
    // Steps can never be negative so i64 should really just be usize (that's probably true for some other values in here too)
    var map = std.AutoHashMap(Point, i64).init(allocator);
    var x: i64 = 0;
    var y: i64 = 0;
    var steps: i64 = 0;
    for (wire.toSliceConst()) |cmd| {
        var direction = switch(cmd.at(0)) {
            'L' => @enumToInt(Direction.Left),
            'R' => @enumToInt(Direction.Right),
            'U' => @enumToInt(Direction.Up),
            'D' => @enumToInt(Direction.Down),
            else => unreachable,
        };
        var dist = try std.fmt.parseInt(i64, cmd.toSliceConst()[1..], 10);
        var index: i64 = 0;
        while (index < dist) {
            x += DX[direction];
            y += DY[direction];
            steps += 1;
            var pt = Point {
                .x = x,
                .y = y,
            };
            if (!map.contains(pt)) {
                _ = try map.put(pt, steps);
            }
            index += 1;
        }
    }
    return map;
}

fn calcManhattanDist(a: i64, b: i64, c: i64, d: i64) i64 {
    var x = if (a > c) a - c else c - a;
    var y = if (b > d) b - d else d - b;
    return x + y;
}

const Direction = enum {
    Left = 0,
    Right = 1,
    Up = 2,
    Down = 3,
};

const Point = struct {
    x: i64,
    y: i64,
};

const DX = [_]i64{ -1, 1, 0, 0 };
const DY = [_]i64{ 0, 0, 1, -1 };