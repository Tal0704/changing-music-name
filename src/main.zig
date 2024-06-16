const std = @import("std");
const testing = std.testing;
const fs = std.fs;
const mem = std.mem;
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for(args, 0..) |arg, i| {
        if(i == 0) continue;
        var workingDir = try fs.cwd().openDir(arg, .{.iterate = true});
        defer workingDir.close();

        var walker = try workingDir.walk(allocator);
        defer walker.deinit();
        while(try walker.next()) |entry| {
            var newName: [std.math.maxInt(u8)]u8 = undefined;
            const len = getNewName(entry.basename, &newName);
            const newPath = newName [0..len];
            if(mem.eql(u8, newPath, entry.basename)) continue;
            print("Are you sure you want to change \"{s}\" to \"{s}\"?\n", .{entry.basename, newPath});
            if(try isSure()) {
                try workingDir.rename(entry.basename, newPath);
                print("Changed name succesfully!\n", .{});
            }
        }
    }
}

fn isSure() !bool {
    var buff:[2] u8 = undefined;
    for(0..buff.len) |i| buff[i] = 0;

    if (try stdin.readUntilDelimiterOrEof(&buff, '\n')) |answer| {
        return std.mem.eql(u8, answer, "y");
    }
    else {
        return false;
    }
}

fn getNewName(path: [] const u8, newPath: []u8) u8 {
    for(0..newPath.len) |i| {
        newPath[i] = 0;
    }

    var newlen: u8 = 0;
    for (path, 0..) |char, i| {
        if ((char <= 'z' and char >= 'a') or (char <= 'Z' and char >= 'A')) {
            for (i..path.len) |j| {
                newPath[j - i] = path[j];
                newlen += 1;
            }
            return newlen;
        }
    }
    return 0;
}
