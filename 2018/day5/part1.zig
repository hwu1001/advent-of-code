const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();
    
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();

    const file_in_stream = &file.inStream().stream;
    var done: bool = false;
    while(!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', std.math.maxInt(usize)) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
    }
    var reacting: bool = true;
    var marked_for_del = std.AutoHashMap(usize, void).init(&direct_alloc.allocator);
    defer marked_for_del.deinit();
    while (reacting) {
        reacting = false;
        // I think we can delete more than two at a time if they're not adjacent, but just going with the naive approach
        var start: usize = 0;
        // find where to start based on "deletions"
        while (marked_for_del.contains(start) and buf.len() > 0 and start < buf.len() - 1) {
            start += 1;
        }
        if (buf.len() > 0 and start == buf.len() - 1) {
            break;
        }
        var prev_char = buf.list.at(start);
        var prev_index: usize = start;
        start += 1;
        while (start < buf.len()) : (start += 1) {
            if (marked_for_del.contains(start)) {
                // If it's been previously "deleted" then ignore
                continue;
            }
            if (charMatch(buf.list.at(start), prev_char)) {
                // Put the indices in the map
                _ = try marked_for_del.put(prev_index, {});
                _ = try marked_for_del.put(start, {});
                reacting = true;
                break;
            }
            prev_char = buf.list.at(start);
            prev_index = start;
        }
    }

    if (buf.len() > marked_for_del.count()) {
        var remain: usize = undefined;
        remain = buf.len() - marked_for_del.count();
        std.debug.warn("{}\n", remain);
    }
}

fn charMatch(a: u8, b: u8) bool {
    return switch(a) {
        'A'...'Z' => b == a + 32,
        'a'...'z' => b == a - 32,
        else => false
    };
}

fn isUpper(char: u8) bool {
    return switch(char) {
        'A'...'Z' => true,
        'a'...'z' => false,
        else => false
    };
}