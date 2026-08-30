// Copyright 2026 The Chromium Authors, Alexander Frick, and The Slipstream
// Browser Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Brand-specific types and constants for Slipstream Browser.
// GUID registry of record: slipstream repo branding/brand.json — these values
// are PERMANENT after the first public release; changing them breaks upgrades
// and fights other Chromium-family installs over registry ownership.

#ifndef CHROME_INSTALL_STATIC_CHROMIUM_INSTALL_MODES_H_
#define CHROME_INSTALL_STATIC_CHROMIUM_INSTALL_MODES_H_

#include <array>

#include "chrome/app/chrome_dll_resource.h"
#include "chrome/common/chrome_icon_resources_win.h"
#include "chrome/install_static/install_constants.h"

namespace install_static {

// The brand-specific company name to be included as a component of the install
// and user data directory paths. May be empty if no such dir is to be used.
inline constexpr wchar_t kCompanyPathName[] = L"";

// The brand-specific product name to be included as a component of the install
// and user data directory paths.
inline constexpr wchar_t kProductPathName[] = L"Slipstream";

// The brand-specific safe browsing client name.
inline constexpr char kSafeBrowsingName[] = "slipstream";

// Note: This list of indices must be kept in sync with the brand-specific
// resource strings in chrome/installer/util/prebuild/create_string_rc.
enum InstallConstantIndex {
  CHROMIUM_INDEX,
  NUM_INSTALL_MODES,
};

inline constexpr auto kInstallModes = std::to_array<InstallConstants>({
    // The primary (and only) install mode for Slipstream.
    {
        .size = sizeof(InstallConstants),
        .index = CHROMIUM_INDEX,  // The one and only mode.
        .install_switch =
            "",  // No install switch for the primary install mode.
        .install_suffix =
            L"",  // Empty install_suffix for the primary install mode.
        .logo_suffix = L"",  // No logo suffix for the primary install mode.
        .app_guid = L"{CB543851-4002-4C3D-A06F-A5C7DEF178BF}",
        .base_app_name = L"Slipstream",              // A distinct base_app_name.
        .base_app_id = L"Slipstream",                // A distinct base_app_id.
        .browser_prog_id_prefix = L"SlipstreamHTM",  // Browser ProgID prefix.
        .browser_prog_id_description =
            L"Slipstream HTML Document",  // Browser ProgID description.
        .direct_launch_url_scheme = "slipstream",
        .pdf_prog_id_prefix = L"SlipstreamPDF",  // PDF ProgID prefix.
        .pdf_prog_id_description =
            L"Slipstream PDF Document",  // PDF ProgID description.
        .active_setup_guid =
            L"{9A5DCA22-CEDA-4FDB-9DDB-9D42462DBC6A}",  // Active Setup GUID.
        .toast_activator_clsid = {0x209EA79E,
                                  0x387A,
                                  0x4D35,
                                  {0xBF, 0xFA, 0xE2, 0x0E, 0x01, 0x4B, 0x45,
                                   0x82}},  // Toast Activator CLSID.
        .elevator_clsid = {0xA3886921,
                           0x7254,
                           0x47BC,
                           {0x97, 0xE7, 0x28, 0xEE, 0x70, 0x2B, 0x95,
                            0x0B}},  // Elevator CLSID.
        .elevator_iid = {0x0725683C,
                         0x13B5,
                         0x449F,
                         {0xA1, 0x4B, 0x13, 0xDD, 0x49, 0xF1, 0x1B,
                          0x28}},  // IElevator IID and TypeLib
        // {0725683C-13B5-449F-A14B-13DD49F11B28}.
        .tracing_service_clsid = {0x9CBEC7BC,
                                  0x3A99,
                                  0x47A0,
                                  {0x93, 0x1E, 0x36, 0xAC, 0xD5, 0x97, 0x97,
                                   0x17}},  // SystemTraceSession CLSID.
        .tracing_service_iid = {0x1B34AEC8,
                                0xFB17,
                                0x4FF1,
                                {0xB1, 0xAE, 0x13, 0xDF, 0x48, 0x10, 0x31,
                                 0x65}},  // ISystemTraceSessionChromium IID and
                                          // TypeLib
        // {1B34AEC8-FB17-4FF1-B1AE-13DF48103165}.
        .default_channel_name =
            L"",  // Empty default channel name since no update integration.
        .channel_strategy = ChannelStrategy::UNSUPPORTED,
        .supports_system_level = true,  // Supports system-level installs.
        .supports_set_as_default_browser =
            true,  // Supports in-product set as default browser UX.
        .app_icon_resource_index =
            icon_resources::kApplicationIndex,  // App icon resource index.
        .app_icon_resource_id = IDR_MAINFRAME,  // App icon resource id.
        .html_doc_icon_resource_index =
            icon_resources::kHtmlDocIndex,  // HTML doc icon resource index.
        .pdf_doc_icon_resource_index =
            icon_resources::kPDFDocIndex,  // PDF doc icon resource index.
        .sandbox_sid_prefix =
            L"S-1-15-2-1467491282-1195051149-1474757959-1724399613-"
            L"2116858157-"
            L"1332199264-1687040722-",  // App container sid prefix for sandbox.
    },
});

}  // namespace install_static

#endif  // CHROME_INSTALL_STATIC_CHROMIUM_INSTALL_MODES_H_
