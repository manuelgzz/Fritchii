// SPDX-License-Identifier: GPL-3.0-or-later

#include <array>
#include <cstdlib>
#include <optional>
#include <string>
#include <vector>
#include <catch2/catch_test_macros.hpp>
#include "common/settings.h"
#include "video_core/host1x/ffmpeg.h"
#include "video_core/host1x/nx2_video_decoder.h"

extern "C" {
#include <libavutil/hwcontext.h>
}

namespace {
// A synthetic 64x64 red frame, encoded with libaom-av1; no game data.
constexpr std::array<u8, 36> RedAv1{
    0x12, 0x00, 0x0a, 0x0a, 0x00, 0x00, 0x00, 0x02, 0xaf, 0xff, 0x9b, 0x5f,
    0x20, 0x08, 0x32, 0x14, 0x10, 0x00, 0xbc, 0x00, 0x00, 0x02, 0x40, 0x00,
    0x00, 0x03, 0xce, 0x22, 0x3d, 0x26, 0xa6, 0x53, 0x75, 0x43, 0xa9, 0x40,
};

struct Av1VaapiMode {
    std::optional<std::string> previous;
    explicit Av1VaapiMode(const char* mode) {
        if (const char* value = std::getenv("EDEN_NX2_AV1_VAAPI")) {
            previous = value;
        }
        Set(mode);
    }
    static void Set(const char* value) {
#ifdef _WIN32
        _putenv_s("EDEN_NX2_AV1_VAAPI", value ? value : "");
#else
        if (value) {
            setenv("EDEN_NX2_AV1_VAAPI", value, 1);
        } else {
            unsetenv("EDEN_NX2_AV1_VAAPI");
        }
#endif
    }
    ~Av1VaapiMode() {
        Set(previous ? previous->c_str() : nullptr);
    }
};

struct RestoreDecoderSetting {
    Settings::NvdecEmulation value{Settings::values.nvdec_emulation.GetValue()};
    ~RestoreDecoderSetting() {
        Settings::values.nvdec_emulation.SetValue(value);
    }
};
}

TEST_CASE("NX2 AV1 decodes synthetic frames with CPU and GPU preferences",
          "[video_core][ffmpeg][av1]") {
    RestoreDecoderSetting restore;
    for (const auto* av1_mode : {"0", "1"}) {
        Av1VaapiMode environment{av1_mode};
        CAPTURE(av1_mode);
        for (const auto mode : {Settings::NvdecEmulation::Cpu, Settings::NvdecEmulation::Gpu}) {
            CAPTURE(static_cast<int>(mode));
            Settings::values.nvdec_emulation.SetValue(mode);
            Tegra::Host1x::Nx2VideoDecoder decoder{"video/av01"};
            REQUIRE(decoder.IsOpen());
            std::vector<Tegra::Host1x::Nx2Picture> pictures;
            decoder.Decode(RedAv1, 12345, pictures);
            decoder.Drain(pictures);
            REQUIRE(pictures.size() == 1);
            REQUIRE(pictures[0].width == 64);
            REQUIRE(pictures[0].height == 64);
            REQUIRE(pictures[0].pts == 12345);
            const auto* frame = pictures[0].frame->GetFrame();
            REQUIRE(frame->data[0][0] >= 80);
            REQUIRE(frame->data[0][0] <= 82);
            std::array<u8, 64 * 64 * 4> rgba{};
            decoder.Render(pictures[0], Tegra::Host1x::Nx2PictureFormat::Rgba8,
                           64, 64, 64 * 4, 0, rgba);
            REQUIRE(rgba[0] >= 250);
            REQUIRE(rgba[1] <= 4);
            REQUIRE(rgba[2] <= 4);
            REQUIRE(rgba[3] == 255);
        }
    }
}

TEST_CASE("FFmpeg hardware format follows the initialized device",
          "[video_core][ffmpeg][av1]") {
    FFmpeg::Decoder decoder{Tegra::Host1x::NvdecCommon::VideoCodec::AV1, true};
    REQUIRE(decoder.GetCodec());
    AVPixelFormat pixel_format;
    if (!decoder.SupportsDecodingOnDevice(&pixel_format, AV_HWDEVICE_TYPE_VAAPI)) {
        SKIP("FFmpeg was built without AV1 VAAPI support");
    }
    AVBufferRef* device = av_hwdevice_ctx_alloc(AV_HWDEVICE_TYPE_VAAPI);
    REQUIRE(device);
    FFmpeg::DecoderContext context{decoder};
    context.InitializeHardwareDecoder(device, pixel_format);
    av_buffer_unref(&device);
    auto* codec_context = context.GetCodecContext();
    codec_context->pix_fmt = AV_PIX_FMT_YUV420P;
    constexpr std::array formats{AV_PIX_FMT_CUDA, AV_PIX_FMT_VAAPI,
                                 AV_PIX_FMT_YUV420P, AV_PIX_FMT_NONE};
    REQUIRE(codec_context->get_format(codec_context, formats.data()) == AV_PIX_FMT_VAAPI);
    REQUIRE(codec_context->hw_device_ctx);

    constexpr std::array cpu_formats{AV_PIX_FMT_YUV420P, AV_PIX_FMT_NONE};
    REQUIRE(codec_context->get_format(codec_context, cpu_formats.data()) == AV_PIX_FMT_YUV420P);
    REQUIRE_FALSE(codec_context->hw_device_ctx);

    constexpr std::array unavailable_formats{AV_PIX_FMT_CUDA, AV_PIX_FMT_NONE};
    REQUIRE(codec_context->get_format(codec_context, unavailable_formats.data()) == AV_PIX_FMT_NONE);
}
