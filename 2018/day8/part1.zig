const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();
    var list = std.ArrayList(usize).init(&direct_alloc.allocator);
    defer list.deinit();
    var nodes = std.ArrayList(Node).init(&direct_alloc.allocator);
    defer nodes.deinit();

    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    const file_in_stream = &file.inStream().stream;

    var done: bool = false;
    var temp: [1]u8 = undefined;
    while(!done) {
        if (file_in_stream.readByte()) |byte| {
            if (byte != ' ') {
                try buf.appendByte(byte);
            } else {
                try list.append(try std.fmt.parseInt(usize, buf.toSlice(), 10));
                buf.shrink(0);
            }
        } else |err| switch(err) {
            error.EndOfStream => {
                try list.append(try std.fmt.parseInt(usize, buf.toSlice(), 10));
                done = true;
            },
            else => return err,
        }
    }
    
    var total: usize = 0;
    var last_node: usize = 0;
    var state = State.ChildNodes;
    try nodes.append(Node { .children = list.at(0), .metadata = list.at(1) });
    if (nodes.at(last_node).children < 0) {
        state = State.Entries;
    }
    var temp_node_ptr: *Node = undefined;
    var temp_node: Node = undefined;
    var entry_count: usize = 0;
    for (list.toSlice()[2..]) |val| {
        switch(state) {
            State.ChildNodes => {
                try nodes.append(Node { .children = val, .metadata = 0 });
                state = State.MetadataCount;
            },
            State.MetadataCount => {
                nodes.items[last_node].metadata = val;
                // If there are more children then parse those nodes
                if (nodes.at(last_node).children > 0) {
                    state = State.ChildNodes;
                } else {
                    state = State.Entries;
                }
                // After going through each node update the depth
                if (nodes.items[last_node - 1].children > 0) {
                    nodes.items[last_node - 1].children -= 1;
                }
            },
            State.Entries => {
                // Add entries to total
                if (nodes.at(last_node).metadata > 0) {
                    total += val;
                    nodes.items[last_node].metadata -= 1;
                }
                // Figure out what to set state - if there's more metadata then
                // get those entries
                if (nodes.at(last_node).metadata > 0) {
                    state = State.Entries;
                } else {
                    // If we're at the last node then we're just going to parse entries, otherwise
                    // if there's more children then parse those nodes
                    if (nodes.count() > 0 and nodes.at(nodes.count() - 1).children > 0) {
                        state = State.ChildNodes;
                    } else {
                        state = State.Entries;
                    }
                }
            },
            else => {},
        }
        if (nodes.count() > 0) {
            last_node = nodes.count() - 1;
        }
    }
    std.debug.warn("total {}\n", total);
}

const State = enum {
    ChildNodes,
    MetadataCount,
    Entries,
};

const Node = struct {
    children: usize,
    metadata: usize,
};