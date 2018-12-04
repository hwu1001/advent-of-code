const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var one_line = std.ArrayList(u8).init(&direct_alloc.allocator);
    defer one_line.deinit();

    // Based on the prompt we know how large the entire rectangle can be
    var rect = [][1000]usize{([]usize{0} ** 1000)} ** 1000;
    var count: usize = 0;

    var done: bool = false;
    while (!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch (err) {
            error.EndOfStream => done = true,
            else => return err,
        };

        var from_left: usize = 0;
        var from_top: usize = 0;
        var width: usize = 0;
        var length: usize = 0;
        var claim = Claim {
            .from_left = undefined,
            .from_top = undefined,
            .width = undefined,
            .length = undefined,
        };
        var index: usize = 0;
        var state = State.Continue;
        var prev_state = state;

        // Parse the string and save the claim
        // This string parsing is terrible I should have just done it with four loops (no pun intended)
        while(index < buf.len()) {
            var save: bool = false;
            switch(buf.list.at(index)) {
                '@' => state = State.FromLeft,
                ',' => state = State.FromTop,
                ':' => state = State.Width,
                'x' => state = State.Length,
                '0'...'9' => save = true,
                else => {},
            }
            if (save and state != State.Continue) {
                try one_line.append(buf.list.at(index));
            }
            if (prev_state != state and prev_state != State.Continue) {
                // If state switches then save the contents of our string of numbers
                // and free up the memory in it
                switch(prev_state) {
                    State.FromLeft => {
                        claim.from_left = try std.fmt.parseInt(usize, one_line.toSlice(), 10);
                        one_line.shrink(0);
                    },
                    State.FromTop => {
                        claim.from_top = try std.fmt.parseInt(usize, one_line.toSlice(), 10);
                        one_line.shrink(0);
                    },
                    State.Width => {
                        claim.width = try std.fmt.parseInt(usize, one_line.toSlice(), 10);
                        one_line.shrink(0);
                    },
                    else => {},
                }
            }
            prev_state = state;
            index += 1;
        }
        // flush the buffer at the end
        claim.length = try std.fmt.parseInt(usize, one_line.toSlice(), 10);
        one_line.shrink(0);

        // process claim
        var i: usize = 0;
        while (i < claim.width) : (i += 1) {
            var j: usize = 0;
            while (j < claim.length) : (j += 1) {
                rect[i + claim.from_left][j + claim.from_top] += 1;
            }
        }
    }

    // For display on test_input.txt
    // var a: usize = 0;
    // while (a < 8) : (a += 1) {
    //     var b: usize = 0;
    //     while (b < 8) : (b += 1) {
    //         std.debug.warn("{} ", rect[a][b]);
    //     }
    //     std.debug.warn("\n");
    // }

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        var j: usize = 0;
        while (j < 1000) : (j += 1) {
            if (rect[i][j] >= 2) {
                count += 1;
            }
        }
    }
    std.debug.warn("count {}\n", count);
}

const State = enum {
    Continue,
    FromLeft,
    FromTop,
    Width,
    Length,
};

const Claim = struct {
    from_left: usize,
    from_top: usize,
    width: usize,
    length: usize,
};