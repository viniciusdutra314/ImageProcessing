const std = @import("std");
const my_lib = @import("ImageProcessing");
const rl = @import("raylib");

fn brigthen(p: [3]u8) [3]u8 {
    return .{ p[0] +| 50, p[1] +| 50, p[2] +| 50 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    var img = try my_lib.Netpbm.readNetbpmFromFilePathAs(my_lib.Image(.rgb, u8, .planar), allocator, "image.ppm");
    defer img.deinit(allocator);

    std.debug.print("height={} width={} \n", .{ img.height, img.width });
    std.debug.print("size in memory {} KB\n", .{img.sizeInBytes() / (1024)});
    img.applyP2PTransformation(brigthen);
    try my_lib.Netpbm.saveNetbpmToFilePath(img, "saved_image.ppm");

}
