// Ported from https://www.reddit.com/r/adventofcode/comments/a3wmnl/2018_day_7_solutions/eb9zzf8
const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    const file_in_stream = &file.inStream().stream;

    var successors = std.AutoHashMap(u8, std.ArrayList(u8)).init(&direct_alloc.allocator);
    defer successors.deinit();
    var predecessors = std.AutoHashMap(u8, std.ArrayList(u8)).init(&direct_alloc.allocator);
    defer predecessors.deinit();

    var done: bool = false;
    while(!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', std.math.maxInt(usize)) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        
        var src: u8 = undefined;
        var i: usize = 0;
        var iter = std.mem.split(buf.toSlice(), " ");
        var list: *std.ArrayList(u8) = undefined;
        // Add data to successors and predecessors
        while(iter.next()) |val| {
            if (i == 1) {
                src = val[0];
                if (!successors.contains(src)) {
                    _ = try successors.put(src, std.ArrayList(u8).init(&direct_alloc.allocator));
                }
            }
            if (i == 7) {
                list = &successors.get(src).?.value;
                try list.append(val[0]);
                if (!predecessors.contains(val[0])) {
                    // I'm not deallocating these lists since we're just running this program once
                    // then it terminates
                    _ = try predecessors.put(val[0], std.ArrayList(u8).init(&direct_alloc.allocator));
                }
                list = &predecessors.get(val[0]).?.value;
                try list.append(src);
            }
            i += 1;
        }
    }

    var prio_queue = std.ArrayList(u8).init(&direct_alloc.allocator);
    defer prio_queue.deinit();
    // Starting steps are ones with no predecessors
    // Create a set from our successors and predecessors
    var src_iter = successors.iterator();
    while (src_iter.next()) |src_entry| {
        var is_starter: bool = true;
        var pred_iter = predecessors.iterator();
        while(pred_iter.next()) |pred_entry| {
            if (pred_entry.key == src_entry.key) {
                is_starter = false;
                break;
            }
        }
        if (is_starter) {
            try prio_queue.append(src_entry.key);
        }
    }
    // Problem prompt says we get 5 workers
    var workers: [5]Worker() = undefined;
    for (workers) |*worker| {
        // There's a better way to do this but I'm not sure what it is yet
        worker.* = Worker().init();
    }

    // I don't know of a priority queue impl in std lib so using an array
    // and sorting it with any addition - the back of the arry is the "front"
    // of the queue
    std.sort.sort(u8, prio_queue.toSlice(), cmpRevAlpha);
    std.debug.warn("sorted starters {}\n", prio_queue.toSlice());
    
    var path = std.ArrayList(u8).init(&direct_alloc.allocator);
    defer path.deinit();
    var src_list: *std.ArrayList(u8) = undefined;
    var pred_list: *std.ArrayList(u8) = undefined;

    var seconds: usize = 0;

    // Change this comparison depending on how many total tasks in data
    // For test_input.txt it's != 6
    while (path.count() != 26) {
        // Set tasks for workers that have availability
        for (workers) |*worker| {
            if (worker.*.isBusy()) {
                continue;
            }
            if (prio_queue.count() > 0) {
                worker.*.setTask(prio_queue.pop());
            }
        }
        // Process a worker at each second, if the worker has completed
        // assigned task then check to see if tasks that come after that one
        // can be processed in the priority queue
        for (workers) |*worker| {
            worker.*.nextTimeStep();
            if (worker.*.done) {
                try path.append(worker.*.task);

                // For steps with no successors need to skip to avoid unwrapping null
                if (!successors.contains(worker.*.task)) {
                    continue;
                }
                src_list = &successors.get(worker.*.task).?.value;
                for (src_list.toSlice()) |step| {
                    // If we don't do this check the starting steps will attempt to unwrap null
                    // from the predecessors hash map
                    if (!predecessors.contains(step)) {
                        continue;
                    }
                    pred_list = &predecessors.get(step).?.value;
                    if (!valInSlice(step, path.toSlice()) and allPredsInPath(pred_list.toSlice(), path.toSlice())) {
                        try prio_queue.append(step);
                        std.sort.sort(u8, prio_queue.toSlice(), cmpRevAlpha);
                    }
                }
                worker.*.done = false;
            }
        }
        seconds += 1;
    }
    // Print the final order
    std.debug.warn("{}\n", path.toSlice());
    std.debug.warn("{}\n", seconds);
}

// reverse alphabetical order
fn cmpRevAlpha(left: u8, right: u8) bool {
    return left > right;
}

fn allPredsInPath(preds: []u8, path: []u8) bool {
    for (preds) |pred_step| {
        if (!valInSlice(pred_step, path[0..])) {
            return false;
        }
    }
    return true;
}

fn valInSlice(val: u8, s: []u8) bool {
    for (s) |char| {
        if (char == val) {
            return true;
        }
    }
    return false;
}

fn Worker() type {
    return struct {
        const Self = @This();
        task: u8,
        done: bool,
        task_duration: usize,

        pub fn init() Self {
            return Self {
                .task = undefined,
                .done = false,
                .task_duration = 0,
            };
        }

        pub fn setTask(self: *Self, t: u8) void {
            self.task = t;
            self.done = false;
            self.task_duration = (t - 'A' + 1) + 60;
        }

        pub fn isBusy(self: *Self) bool {
            return self.task_duration > 0;
        }

        pub fn nextTimeStep(self: *Self) void {
            if (self.isBusy()) {
                self.task_duration -= 1;
                if (self.task_duration == 0) {
                    self.done = true;
                }
            }
        }
    };
}