const std = @import("std");
pub const Netpbm = @import("formats//Netpbm.zig");
const Allocator = std.mem.Allocator;

pub const ColorSpace = enum {
    grayscale,
    rgb,
    rgba,

    pub fn channels(self: ColorSpace) usize {
        return switch (self) {
            .grayscale => 1,
            .rgb => 3,
            .rgba => 4,
        };
    }
};

pub fn Image(comptime color_space: ColorSpace, comptime Component: type) type {
    const Pixel = [color_space.channels()]Component;
    return struct {
        const Self = @This();
        pub const pixel_format = color_space;
        pub const component_type = Component;

        width: usize,
        height: usize,
        data: []Pixel,
        allocator: Allocator,

        pub fn init(allocator: Allocator, width: usize, height: usize) !Self {
            const data = try allocator.alloc(Pixel, width * height);
            return Self{
                .width = width,
                .height = height,
                .data = data,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn getPixel(self: Self, x: usize, y: usize) Pixel {
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            return self.data[y * self.width + x];
        }

        pub fn setPixel(self: *Self, x: usize, y: usize, val: Pixel) void {
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            self.data[y * self.width + x] = val;
        }
    };
}

pub const DynamicImage = union(enum) {
    rgb_u8: Image(.rgb, u8),
    rgb_u16: Image(.rgb, u16),
    grayscale_u8: Image(.grayscale, u8),
    grayscale_u1: Image(.grayscale, u1),
    grayscale_u16: Image(.grayscale, u16),
};

test "Image initialization and pixel access" {
    const allocator = std.testing.allocator;
    const RgbImage = Image(.rgb, u8);

    var img = try RgbImage.init(allocator, 10, 10);
    defer img.deinit();

    try std.testing.expectEqual(@as(usize, 10), img.width);
    try std.testing.expectEqual(@as(usize, 10), img.height);

    const color = [_]u8{ 255, 128, 0 };
    img.setPixel(5, 5, color);
    const retrieved = img.getPixel(5, 5);

    try std.testing.expectEqual(color[0], retrieved[0]);
    try std.testing.expectEqual(color[1], retrieved[1]);
    try std.testing.expectEqual(color[2], retrieved[2]);
}

test "Grayscale image with float components" {
    const allocator = std.testing.allocator;
    const GrayImage = Image(.grayscale, f32);

    var img = try GrayImage.init(allocator, 2, 2);
    defer img.deinit();

    const val = [_]f32{0.5};
    img.setPixel(1, 1, val);
    try std.testing.expectEqual(val[0], img.getPixel(1, 1)[0]);
}
