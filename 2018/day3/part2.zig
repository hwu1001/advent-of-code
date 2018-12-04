const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var claims = std.ArrayList(Claim).init(&direct_alloc.allocator);
    defer claims.deinit();
    var rect = [][1000]usize{([]usize{0} ** 1000)} ** 1000;

    var done: bool = false;
    while(!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        var claim = try getClaim(buf);
        try claims.append(claim);
        updateRect(&rect, claim);
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
    for (claims.toSlice()) |claim| {
        var i: usize = 0;
        var found: bool = true;
        while (i < claim.width) : (i += 1) {
            var j: usize = 0;
            while (j < claim.length) : (j += 1) {
                if (rect[i + claim.from_left][j + claim.from_top] >= 2) {
                    found = false;
                    break;
                }
            }
            if (!found) {
                break;
            }
        }
        if (found) {
            std.debug.warn("{}\n", claim.id);
        }
    }
}

fn getClaim(buf: std.Buffer) !Claim {
    // The max size is 1000 per the prompt
    var num_buf = []u8 { '1', '0', '0', '0' };
    var ndx: usize = 0;
    var state = State.ClaimId;
    var prev_state = state;
    var id: usize = undefined;
    var from_left: usize = undefined;
    var from_top: usize = undefined;
    var width: usize = undefined;
    var length: usize = undefined;

    for (buf.toSlice()) |char| {
        var save: bool = false;
        switch (char) {
            '@' => state = State.FromLeft,
            ',' => state = State.FromTop,
            ':' => state = State.Width,
            'x' => state = State.Length,
            '0'...'9' => save = true,
            else => {},
        }
        if (save) {
            num_buf[ndx] = char;
            ndx += 1;
        }
        if (prev_state != state) {
            switch(prev_state) {
                State.ClaimId => {
                    id = try std.fmt.parseInt(usize, num_buf[0..ndx], 10);
                    ndx = 0;
                },
                State.FromLeft => {
                    from_left = try std.fmt.parseInt(usize, num_buf[0..ndx], 10);
                    ndx = 0;
                },
                State.FromTop => {
                    from_top = try std.fmt.parseInt(usize, num_buf[0..ndx], 10);
                    ndx = 0;
                },
                State.Width => {
                    width = try std.fmt.parseInt(usize, num_buf[0..ndx], 10);
                    ndx = 0;
                },
                else => {},
            }
        }
        prev_state = state;
    }
    length = try std.fmt.parseInt(usize, num_buf[0..ndx], 10);
    return Claim {
        .id = id,
        .from_left = from_left,
        .from_top = from_top,
        .width = width,
        .length = length
    };
}

fn updateRect(rect: *[1000][1000]usize, claim: Claim) void {
    var i: usize = 0;
    while (i < claim.width) : (i += 1) {
        var j: usize = 0;
        while (j < claim.length) : (j += 1) {
            rect[i + claim.from_left][j + claim.from_top] += 1;
        }
    }
}

const State = enum {
    ClaimId,
    FromLeft,
    FromTop,
    Width,
    Length,
};

const Claim = struct {
    id: usize,
    from_left: usize,
    from_top: usize,
    width: usize,
    length: usize,
};