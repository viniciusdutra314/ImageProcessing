const std = @import("std");
const my_lib = @import("ImageProcessing");
const rl = @import("raylib");
const rg = @import("raygui");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 2) {
        std.debug.print("Uso: ex02 <caminho_para_o_arquivo>\n", .{});
        return;
    }
    const filepath = args[1];

    const original_img = try read_as_gray: {
        const rgb_attempt = my_lib.Netpbm.readNetbpmFromFilePathAs(
            my_lib.Image(.rgb, u8, .interleaved),
            allocator,
            filepath,
        );

        if (rgb_attempt) |img| {
            const gray_img = try img.toGrayscale(allocator);
            img.deinit(allocator);
            break :read_as_gray gray_img;
        } else |err| {
            if (err == my_lib.Netpbm.PgmError.IncompatibleOutputImageType) {
                const gray_img = try my_lib.Netpbm.readNetbpmFromFilePathAs(
                    my_lib.Image(.grayscale, u8, .interleaved),
                    allocator,
                    filepath,
                );
                break :read_as_gray gray_img;
            }
            break :read_as_gray err;
        }
    };
    defer original_img.deinit(allocator);

    var processed_img = try my_lib.Image(.grayscale, u8, .interleaved).init(allocator, original_img.width, original_img.height);
    defer processed_img.deinit(allocator);

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(1280, 720, "Processamento de Imagem - Contraste, Brilho e Limiar");
    defer rl.closeWindow();
    const rl_image = rl.Image{
        .data = @ptrCast(processed_img.getSliceMut()),
        .width = @intCast(processed_img.width),
        .height = @intCast(processed_img.height),
        .mipmaps = 1,
        .format = rl.PixelFormat.uncompressed_grayscale,
    };

    const texture = try rl.loadTextureFromImage(rl_image);
    defer rl.unloadTexture(texture);

    const rl_original_image = rl.Image{
        .data = @ptrCast(original_img.getSliceMut()),
        .width = @intCast(original_img.width),
        .height = @intCast(original_img.height),
        .mipmaps = 1,
        .format = rl.PixelFormat.uncompressed_grayscale,
    };
    const original_texture = try rl.loadTextureFromImage(rl_original_image);
    defer rl.unloadTexture(original_texture);

    var a_slider: f32 = 1.0;
    var b_slider: f32 = 0.0;
    var threshold_slider: f32 = 255.0;

    rl.setTargetFPS(0);

    while (!rl.windowShouldClose()) {
        var histogram = [_]usize{0} ** 256;
        for (original_img.getSlice(), processed_img.getSliceMut()) |old_pixel, *new_pixel| {
            const float_pixel: f32 = @floatFromInt(old_pixel[0]);
            if (float_pixel > threshold_slider) {
                new_pixel[0] = 0;
            } else {
                const new_float_pixel = std.math.clamp(a_slider * float_pixel + b_slider, 0.0, 255.0);
                new_pixel[0] = @intFromFloat(new_float_pixel);
                histogram[@intFromFloat(float_pixel)] += 1;
            }
        }
        rl.updateTexture(texture, processed_img.getSlice().ptr);
        var max_hist: usize = 0;
        for (histogram) |h| if (h > max_hist) {
            max_hist = h;
        };

        rl.beginDrawing();
        rl.clearBackground(.ray_white);

        const screen_w: f32 = @floatFromInt(rl.getScreenWidth());
        const screen_h: f32 = @floatFromInt(rl.getScreenHeight());
        const section_w = screen_w / 3.0;
        const screen_padding: f32 = 30.0;
        const max_display_w: f32 = section_w - (screen_padding * 2.0);
        const max_display_h: f32 = screen_h * 0.5;

        const scale = @min(max_display_w / @as(f32, @floatFromInt(original_img.width)), max_display_h / @as(f32, @floatFromInt(original_img.height)));

        const display_w = @as(f32, @floatFromInt(original_img.width)) * scale;
        const display_h = @as(f32, @floatFromInt(original_img.height)) * scale;

        // Imagem no centro
        const original_x = section_w + (section_w - display_w) / 2.0;
        rl.drawTexturePro(original_texture, .{ .x = 0, .y = 0, .width = @floatFromInt(original_texture.width), .height = @floatFromInt(original_texture.height) }, .{
            .x = original_x,
            .y = 60,
            .width = display_w,
            .height = display_h,
        }, .{ .x = 0, .y = 0 }, 0, rl.Color.white);
        rl.drawText("Original", @intFromFloat(section_w + screen_padding), 20, 24, rl.Color.black);

        // Imagem na direita
        const processed_x = (section_w * 2.0) + (section_w - display_w) / 2.0;
        rl.drawTexturePro(texture, .{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) }, .{
            .x = processed_x,
            .y = 60,
            .width = display_w,
            .height = display_h,
        }, .{ .x = 0, .y = 0 }, 0, rl.Color.white);
        rl.drawText("Processada", @intFromFloat(section_w * 2.0 + screen_padding), 20, 24, rl.Color.black);

        // Histograma
        const hist_x: f32 = screen_padding;
        const hist_width: f32 = max_display_w;
        const hist_height: f32 = max_display_h;
        const hist_y: f32 = 60 + hist_height;

        rl.drawText("Histograma", @intFromFloat(hist_x), 20, 24, rl.Color.black);
        rl.drawRectangleLinesEx(.{ .x = hist_x, .y = 60, .width = hist_width, .height = hist_height }, 2, rl.Color.gray);

        for (histogram, 0..) |count, i| {
            if (count == 0) continue;
            const h = (@as(f32, @floatFromInt(count)) / @as(f32, @floatFromInt(max_hist))) * hist_height;
            const bar_x = hist_x + (@as(f32, @floatFromInt(i)) / 256.0) * hist_width;
            rl.drawLineEx(.{ .x = bar_x, .y = hist_y }, .{ .x = bar_x, .y = hist_y - h }, 1, rl.Color.red);
        }

        // Sliders
        const drawSlider = struct {
            fn draw(rect: rl.Rectangle, comptime label_fmt: []const u8, value: *f32, min: f32, max: f32) !void {
                var buf: [64]u8 = undefined;
                const label = try std.fmt.bufPrintZ(&buf, label_fmt, .{value.*});
                _ = rg.slider(rect, "", label, value, min, max);
            }
        }.draw;

        const slider_h: f32 = 60;
        const sliders_start_y: f32 = screen_h * 0.65;
        const slider_spacing: f32 = (screen_h - sliders_start_y) / 4;
        const slider_width = section_w;
        const slider_x = screen_w / 2 - slider_width / 2;

        try drawSlider(.{ .x = slider_x, .y = sliders_start_y, .width = slider_width, .height = slider_h }, "Contraste (a): {d:.2}", &a_slider, 0.0, 3.0);
        try drawSlider(.{ .x = slider_x, .y = sliders_start_y + slider_spacing, .width = slider_width, .height = slider_h }, "Brilho (b): {d:.2}", &b_slider, -100.0, 100.0);
        try drawSlider(.{ .x = slider_x, .y = sliders_start_y + slider_spacing * 2, .width = slider_width, .height = slider_h }, "Limiar (Threshold): {d:.0}", &threshold_slider, 0.0, 255.0);

        if (rg.button(.{ .x = slider_x, .y = sliders_start_y + slider_spacing * 3 + 10, .width = slider_width, .height = 40 }, "Resetar Filtros")) {
            a_slider = 1.0;
            b_slider = 0.0;
            threshold_slider = 255.0;
        }

        rl.endDrawing();
    }
}
