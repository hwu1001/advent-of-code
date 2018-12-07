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
    var copy = std.ArrayList(u8).init(&direct_alloc.allocator);
    defer copy.deinit();
    var shortest_len: usize = std.math.maxInt(usize);
    var shortest_char: u8 = undefined;
    var char: u8 = 'a';
    var temp: [1]u8 = undefined;
    while (char <= 'z') : (char += 1) {
        // Make an actual copy
        // var copy = buf; will point to the actual object
        // and all changes to copy will affect buf
        for (buf.toSlice()) |val| {
            try copy.append(val);
        }
        copy.shrink(removeChar(copy.toSlice(), copy.count(), char));    
        copy.shrink(reactPolymer(copy.toSlice(), copy.count()));
        if (copy.count() < shortest_len) {
            shortest_len = copy.count();
            shortest_char = char;
        }
        temp[0] = shortest_char;
        std.debug.warn("{} {}\n", shortest_len, temp[0..]);
        copy.shrink(0); // reset for each letter
    }
}

fn removeChar(p: []u8, p_len: usize, char: u8) usize {
    var length = p_len;
    var i: usize = 0;
    while (i < length) : (i += 1) {
        if (toUpper(p[i]) == toUpper(char)) {
            for (p[i + 1..length]) |val, j| {
                p[i + j] = val;
            }
            if (i > 0 and length > 0) {
                length -= 1;
                i -= 1;
            }
        }
    }
    return length;
}

fn reactPolymer(polymer: [] u8, polymer_len: usize) usize {
    var len_copy: usize = polymer_len;
    reacting: while (true) {
        for (polymer[0..len_copy]) |letter, i| {
            if (charMatch(letter, polymer[i + 1])) {
                for (polymer[i + 2..len_copy]) |val, j| {
                    polymer[i + j] = val;
                }
                len_copy -= 2;
                continue :reacting; // is this go-to like syntax bad style?
            }
        }
        break;
    }
    return len_copy;
}

// only a-zA-Z so no special handling
fn toUpper(char: u8) u8 {
    return switch(char) {
        'a'...'z' => char - 32,
        else => char,
    };
}

fn charMatch(a: u8, b: u8) bool {
    return switch(a) {
        'A'...'Z' => b == a + 32,
        'a'...'z' => b == a - 32,
        else => false
    };
}