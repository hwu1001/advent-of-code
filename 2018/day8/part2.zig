// ported from https://www.reddit.com/r/adventofcode/comments/a47ubw/2018_day_8_solutions/ebc99t8
// Couldn't figure out what was wrong with my original stack implementation
// This one should go left to right, top to bottom
const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();
    var list = std.ArrayList(usize).init(&direct_alloc.allocator);
    defer list.deinit();

    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    const file_in_stream = &file.inStream().stream;

    var done: bool = false;
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
    var child_stack = std.ArrayList(usize).init(&direct_alloc.allocator);
    defer child_stack.deinit();
    var meta_stack = std.ArrayList(usize).init(&direct_alloc.allocator);
    defer meta_stack.deinit();

    var children = std.ArrayList(std.ArrayList(usize)).init(&direct_alloc.allocator);
    defer children.deinit();
    var metadata = std.ArrayList(std.ArrayList(usize)).init(&direct_alloc.allocator);
    defer metadata.deinit();

    // Initialize for the root node
    try child_stack.append(list.at(0));
    try meta_stack.append(list.at(1));
    try children.append(std.ArrayList(usize).init(&direct_alloc.allocator));
    try metadata.append(std.ArrayList(usize).init(&direct_alloc.allocator));

    var i: usize = 2;
    while (child_stack.count() > 0) {
        if (child_stack.at(child_stack.count() - 1) > 0) {
            child_stack.items[child_stack.count() - 1] -= 1;
            try child_stack.append(list.at(i));
            try meta_stack.append(list.at(i + 1));
            // These lists get deallocated in the else
            try children.append(std.ArrayList(usize).init(&direct_alloc.allocator));
            try metadata.append(std.ArrayList(usize).init(&direct_alloc.allocator));
            i += 2;
        } else if (meta_stack.at(meta_stack.count() - 1) > 0) {
            try metadata.items[metadata.count() - 1].append(list.at(i));
            meta_stack.items[meta_stack.count() - 1] -= 1;
            i += 1;
        } else {
            var child = children.pop();
            var entries = metadata.pop();
            var val = if (child.count() > 0) sumParentNode(child.toSlice(), entries.toSlice()) else sumSlice(entries.toSlice());
            if (children.count() > 0) {
                try children.items[children.count() - 1].append(val);
            } else {
                std.debug.warn("{}\n", val);
                break;
            }
            _ = child_stack.pop();
            _ = meta_stack.pop();
            child.deinit();
            entries.deinit();
        }
    }
}

fn sumSlice(data: []usize) usize {
    var total: usize = 0;
    for (data) |val| {
        total += val;
    }
    return total;
}

fn sumParentNode(child_slice: []usize, metadata: []usize) usize {
    var total: usize = 0;
    for (metadata) |val| {
        if (1 <= val and val <= child_slice.len) {
            total += child_slice[val - 1];
        }
    }
    return total;
}
// 37453