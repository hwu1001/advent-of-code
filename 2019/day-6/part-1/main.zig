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
        }
    }
    var total: usize = 0;
    var orbit_it = orbit_map.iterator();
    while (orbit_it.next()) |orb_entry| {
        total += recurseVertices(orb_entry.key, &orbit_map);
    }

    std.debug.warn("total direct and indirect {}\n", total);
}

// TODO: Use an iterative traversal instead
fn recurseVertices(obj_name: []const u8, orbit_map: *ObjectMap) usize {
    var num_nodes: usize = 0;
    var obj_list = if (orbit_map.get(obj_name)) |entry| entry.value else return 0;
    for (obj_list.toSliceConst()) |o| {
        num_nodes += recurseVertices(o.toSliceConst(), orbit_map);
        num_nodes += 1;
    }
    return num_nodes;
}

const ObjectMap = std.StringHashMap(std.ArrayList(std.ArrayList(u8)));
