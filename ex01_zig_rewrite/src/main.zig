const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(allocator, "my_image.png", read_buffer[0..]);
    defer image.deinit(allocator);

    // Do something with your image
}
