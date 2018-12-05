const std = @import("std");

pub fn main() !void {
    var file = try std.os.File.openRead("./input.txt");
    defer file.close();
    var direct_alloc = std.heap.DirectAllocator.init();
    defer direct_alloc.deinit();

    const file_in_stream = &file.inStream().stream;
    var buf = try std.Buffer.initSize(&direct_alloc.allocator, 0);
    defer buf.deinit();
    var hash_map = std.AutoHashMap(usize, SleepData).init(&direct_alloc.allocator);
    defer hash_map.deinit();
    var records = std.ArrayList(Record).init(&direct_alloc.allocator);
    defer records.deinit();
    var done: bool = false;
    while(!done) {
        file_in_stream.readUntilDelimiterBuffer(&buf, '\n', 1000) catch |err| switch(err) {
            error.EndOfStream => done = true,
            else => return err,
        };
        try records.append(try createRecord(buf));
    }

    std.sort.sort(Record, records.toSlice(), cmp);
    var temp_data: *SleepData = undefined;
    var guardId: usize = undefined;
    var asleep_minute: usize = undefined;
    for (records.toSlice()) |record| {
        if (record.action == Action.Begin) {
            guardId = record.id;
            if (!hash_map.contains(guardId)) {
                _ = try hash_map.put(guardId, SleepData{ .total_sleep = 0, .minutes = []usize{0} ** 60 });
                // I need this to update the array in the hash map
                // Looks like there's HashMap.getOrPut() but I don't know how to use that
            }
            temp_data = &hash_map.get(guardId).?.value;
        }
        else {
            if (record.action == Action.FallAsleep) {
                asleep_minute = record.minute;
            }
            else {
                // Upon wake up save the data
                var i = asleep_minute;
                // data should be good so don't need to check for i < 60
                while (i < record.minute) : (i += 1) {
                    temp_data.total_sleep += 1;
                    temp_data.minutes[i] += 1;
                }
                asleep_minute = 0;
            }
        }

    }
    var iter = hash_map.iterator();
    var sleepiest_guard = iter.next();
    while (iter.next()) |entry| {
        if (entry.value.total_sleep > sleepiest_guard.?.value.total_sleep) {
            sleepiest_guard = entry;
        }
    }
    var best_min: usize = 0;
    var best_min_index: usize = 0;
    for (sleepiest_guard.?.value.minutes[0..]) |min, ndx| {
        if (min > best_min) {
            best_min = min;
            best_min_index = ndx;
        }
    }
    std.debug.warn("Id {} Min {} res {}\n", sleepiest_guard.?.key, best_min_index, sleepiest_guard.?.key * best_min_index);
}

fn cmp(left: Record, right: Record) bool {
    var i: usize = 0;
    std.debug.warn("{}\n", left.date_str[0..]);
    std.debug.warn("{}\n", right.date_str[0..]);

    while(left.date_str[i] == right.date_str[i] and i < left.date_str.len - 1) : (i += 1){}
    return left.date_str[i] < right.date_str[i];
}

// only after I wrote this did I know you could use multiple delimiters in std.mem.split :(
fn createRecord(line: std.Buffer) !Record {
    var buf: [20]u8 = undefined;
    var index: usize = 0;
    var date_buf: [12]u8 = undefined;
    var date_index: usize = 0;
    var year: usize = undefined;
    var month: usize = undefined;
    var day: usize = undefined;
    var hour: usize = undefined;
    var minute: usize = undefined;
    var action: Action = undefined;
    var id: usize = undefined;
    var state = State.Year;
    var prev_state = state;

    for (line.toSlice()) |char| {
        if (state == State.Action and index > 0 and action != Action.Begin) {
            break;
        }
        switch(char) {
            '0'...'9' => {
                if (state != State.Action) {
                    buf[index] = char;
                    index += 1;
                    if (state != State.Id) {
                        date_buf[date_index] = char;
                        date_index += 1;
                    }
                }
            },
            '-' => {
                switch(state) {
                    State.Year => state = State.Month,
                    State.Month => state = State.Day,
                    else => {}
                }
            },
            ' ' => {
                switch(state) {
                    State.Day => state = State.Hour,
                    State.Minute => state = State.Action,
                    State.Id => state = State.End,
                    else => {}
                }
            },
            ':' => state = State.Minute,
            '#' => state = State.Id,
            'G', 'f', 'w' => {
                if (state == State.Action and index < 1) {
                    // buf[0] = char;
                    switch(char) {
                        'G' => action = Action.Begin,
                        'f' => action = Action.FallAsleep,
                        'w' => action = Action.Wake,
                        else => {}
                    }
                    // action = char;
                    index += 1;
                }
            },
            else => {}
        }
        // flush buffer
        if (prev_state != state) {
            var val = try std.fmt.parseInt(usize, buf[0..index], 10);
            switch(prev_state) {
                State.Year => year = val,
                State.Month => month = val,
                State.Day => day = val,
                State.Hour => hour = val,
                State.Minute => minute = val,
                // State.Action => action = buf[0],
                State.Id => id = val,
                else => {}
            }
            index = 0;
        }
        prev_state = state;

        if (state == State.End) {
            break;
        }
    }

    return Record {
        // I don't even need year, month, day, or hour - I should really read these prompts better
        // But I noticed this after writing the parsing code...
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .minute = minute,
        .date_str = date_buf,
        .action = action,
        .id = id
    };
}

const State = enum {
    Year,
    Month,
    Day,
    Hour,
    Minute,
    Action,
    Id,
    End,
};

const Action = enum {
    Begin,
    FallAsleep,
    Wake,
};

const Record = struct {
    year: usize,
    month: usize,
    day: usize,
    hour: usize,
    minute: usize,
    date_str: [12]u8, // yyyymmddhhmm
    action: Action, // Either 'G','f','w' (begin shift, fall asleep, wake up)
    id: usize,
};

const SleepData = struct {
    total_sleep: usize,
    minutes: [60]usize, // hour worth of data - prompt says only midnight hour matters
};

// Not used, just keeping for reference
fn parseDateStr(alloc: *std.heap.DirectAllocator, buf: std.Buffer) !std.ArrayList(u8) {
    var list = std.ArrayList(u8).init(&alloc.allocator);
    // defer list.deinit();
    var save: bool = false;
    for (buf.toSlice()) |char| {
        if (char == '[') {
            save = true;
            continue;
        }
        if (char == ']') {
            break;
        }
        if (save) {
            try list.append(char);
        }
    }
    // std.debug.warn("{}\n", list.toSlice());
    return list;
}

// fn cmp(left: std.ArrayList(u8), right: std.ArrayList(u8)) bool {
//     var i: usize = 0;
//     while(left.at(i) == right.at(i) and i < left.count()) : (i += 1){}
//     return left.at(i) < right.at(i);
// }
