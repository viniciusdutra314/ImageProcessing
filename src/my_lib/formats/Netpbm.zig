const std = @import("std");
const my_lib = @import("../my_lib.zig");
const Image = my_lib.Image;
const DynamicImage = my_lib.DynamicImage;

pub const PgmError = error{
    InvalidMagicNumber,
    InvalidHeader,
    UnsupportedFormat,
    AllocationFailed,
    EndOfStream,
};

fn readNextToken(reader: *std.io.Reader, buf: []u8) ![]const u8 {
    var i: usize = 0;
    while (true) {
        const b = reader.takeByte() catch |err| switch (err) {
            error.EndOfStream => {
                if (i > 0) return buf[0..i];
                return error.EndOfStream;
            },
            else => return err,
        };

        if (b == '#') {
            if (i > 0) return buf[0..i];
            while (true) {
                const cb = reader.takeByte() catch |err| switch (err) {
                    error.EndOfStream => return error.EndOfStream,
                    else => return err,
                };
                if (cb == '\n') break;
            }
            continue;
        }

        if (std.ascii.isWhitespace(b)) {
            if (i > 0) return buf[0..i];
            continue;
        }

        if (i < buf.len) {
            buf[i] = b;
            i += 1;
        } else {
            return error.TokenTooLong;
        }
    }
}

fn parseNextInt(reader: *std.Io.Reader, buffer: []u8) !usize {
    const token = try readNextToken(reader, buffer);
    return std.fmt.parseInt(usize, token, 10);
}

pub fn readPgmFromReader(
    allocator: std.mem.Allocator,
    reader: *std.Io.Reader,
) !DynamicImage {
    var buffer: [64]u8 = undefined;
    const magic = try readNextToken(reader, &buffer);
    const is_binary = if (std.mem.eql(u8, magic, "P5")) true else if (std.mem.eql(u8, magic, "P2")) false else return PgmError.InvalidMagicNumber;
    const width = try parseNextInt(reader, &buffer);
    const height = try parseNextInt(reader, &buffer);
    const max_val = try parseNextInt(reader, &buffer);

    if (max_val < 256) {
        var img = try Image(.grayscale, u8).init(allocator, width, height);
        errdefer img.deinit();

        if (is_binary) {
            try reader.readSliceAll(std.mem.sliceAsBytes(img.data));
        } else {
            for (img.data) |*pixel| {
                const val = try parseNextInt(reader, &buffer);
                pixel[0] = @intCast(val);
            }
        }
        return DynamicImage{ .grayscale_u8 = img };
    } else if (max_val < 65536) {
        var img = try Image(.grayscale, u16).init(allocator, width, height);
        errdefer img.deinit();
        if (is_binary) {
            const num_pixels = width * height;
            for (0..num_pixels) |i| {
                const val = try parseNextInt(reader, &buffer);
                img.data[i][0] = @intCast(val);
            }
        } else {
            for (img.data) |*pixel| {
                const val = try parseNextInt(reader, &buffer);
                pixel[0] = @intCast(val);
            }
        }
        return DynamicImage{ .grayscale_u16 = img };
    } else {
        return PgmError.UnsupportedFormat;
    }
}
