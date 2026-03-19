const std = @import("std");
const my_lib = @import("ImageProcessing");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const file = try std.fs.cwd().openFile("a.pgm", .{});
    var buffer: [1024]u8 = undefined;
    var reader_file = file.reader(&buffer);

    var img = try my_lib.Netpbm.readPgmFromReader(allocator, &reader_file.interface);
    switch (img) {
        .grayscale_u8 => |*gray_img| {
            std.debug.print("height={} width={} ", .{ gray_img.height, gray_img.width });
            gray_img.deinit();
        },
        else => {
            std.debug.print("Is not grayscale", .{});
        },
    }
}
