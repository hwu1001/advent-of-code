const std = @import("std");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("../input.txt", .{});
    defer file.close();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(allocator, 0);
    defer buf.deinit();

    var done: bool = false;
    var fuel_requirements: usize = 0;
    while (!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch (err) {
            error.EndOfStream => done = true,
            else => return err,
        };

        var mass = try std.fmt.parseInt(usize, buf.toSliceConst(), 10);
        var mass_greater_than_zero: bool = true;
        while (mass > 6) {
            // From the prompt:
            // take its mass, divide by three, round down, and subtract 2.
            var r = ((mass / 3) - 2);
            fuel_requirements += r;
            mass = r;
        }
    }
    std.debug.warn("fuel requirements {}\n", fuel_requirements);
}