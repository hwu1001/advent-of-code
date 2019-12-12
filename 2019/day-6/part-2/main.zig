// Couldn't figure this one out, looked at the comment here:
// https://www.reddit.com/r/adventofcode/comments/e6tyva/2019_day_6_solutions/f9t5fym/

const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();
    const file_in_stream = &file.inStream().stream;
    var buf: [1024]u8 = undefined;
    var orbit_map = ObjectMap.init(std.heap.page_allocator);
    defer orbit_map.deinit();

    while (try file_in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.separate(line, ")");

        while (iter.next()) |orbited| {
            var orbits = if (iter.next()) |orb| orb else continue;
            // Predecessor
            if (orbit_map.contains(orbited)) {
                var string = std.ArrayList(u8).init(std.heap.page_allocator);
                try string.appendSlice(orbits);
                var list = &orbit_map.get(orbited).?.value;
                try list.append(string);
            } else {
                // Allocate new memory to hold slice of key name
                var key = std.ArrayList(u8).init(std.heap.page_allocator);
                try key.appendSlice(orbited);
                
                var list = std.ArrayList(std.ArrayList(u8)).init(std.heap.page_allocator);
                var string = std.ArrayList(u8).init(std.heap.page_allocator);
                try string.appendSlice(orbits);
                try list.append(string);
                _ = try orbit_map.put(key.toSliceConst(), list);
            }

            // Successor
            if (orbit_map.contains(orbits)) {
                var string = std.ArrayList(u8).init(std.heap.page_allocator);
                try string.appendSlice(orbited);
                var list = &orbit_map.get(orbits).?.value;
                try list.append(string);
            } else {
                // Allocate new memory to hold slice of key name
                var key = std.ArrayList(u8).init(std.heap.page_allocator);
                try key.appendSlice(orbits);
                
                var list = std.ArrayList(std.ArrayList(u8)).init(std.heap.page_allocator);
                var string = std.ArrayList(u8).init(std.heap.page_allocator);
                try string.appendSlice(orbited);
                try list.append(string);
                _ = try orbit_map.put(key.toSliceConst(), list);
            }
        }
    }

    var distance_map = std.StringHashMap(usize).init(std.heap.page_allocator);
    defer distance_map.deinit();
    var queue = std.TailQueue(Object).init();

    var obj = try Object.init(std.heap.page_allocator, "YOU", 0);
    var node = try queue.createNode(obj, std.heap.page_allocator);
    queue.append(node);
    while (queue.len > 0) {
        var orbit_obj = queue.popFirst().?.data;
        if (distance_map.contains(orbit_obj.name.toSliceConst())) {
            continue;
        }
        _ = try distance_map.put(orbit_obj.name.toSliceConst(), orbit_obj.distance);
        var list = orbit_map.get(orbit_obj.name.toSliceConst()).?.value;
        for (list.toSliceConst()) |obj_name| {
            var o = try Object.init(std.heap.page_allocator, obj_name.toSliceConst(), orbit_obj.distance + 1);
            var n = try queue.createNode(o, std.heap.page_allocator);
            queue.append(n);
        }
    }

    std.debug.warn("steps {}\n", distance_map.get("SAN").?.value - 2);
}

const Object = struct {
    distance: usize,
    name: std.ArrayList(u8),
    
    pub fn init(allocator: *std.mem.Allocator, name: []const u8, dist: usize) !Object {
        var obj = Object {
            .name = std.ArrayList(u8).init(allocator),
            .distance = dist
        };
        try obj.name.appendSlice(name);
        return obj;
    }
};

const ObjectMap = std.StringHashMap(std.ArrayList(std.ArrayList(u8)));
