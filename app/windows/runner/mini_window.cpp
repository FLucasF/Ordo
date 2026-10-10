#include "mini_window.h"

#include <dwmapi.h>
#include <flutter/dart_project.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <cwchar>

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif

namespace {

constexpr wchar_t kClassName[] = L"TAREFAS_MINI_CALENDAR";

// Kept beside the app window's placement (flutter_window.cpp).
#ifdef NDEBUG
constexpr wchar_t kSettingsKey[] = L"Software\\dev.lucasfelipe\\Tarefas";
#else
// Debug builds keep their own, beside an installed app's.
constexpr wchar_t kSettingsKey[] = L"Software\\dev.lucasfelipe\\Tarefas\\Debug";
#endif
constexpr wchar_t kPlacementValue[] = L"MiniPlacement";
constexpr wchar_t kOpenValue[] = L"MiniOpen";

constexpr UINT_PTR kDesktopTimer = 1;

// Logical size of a new window, and the smallest it can be.
constexpr int kWidth = 340;
constexpr int kHeight = 420;
constexpr int kMinWidth = 240;
constexpr int kMinHeight = 180;

void SaveOpen(bool open) {
  const DWORD value = open ? 1 : 0;
  ::RegSetKeyValueW(HKEY_CURRENT_USER, kSettingsKey, kOpenValue, REG_DWORD, &value, sizeof(value));
}

// The desktop behind the windows (its icons and wallpaper).
bool IsDesktop(HWND hwnd) {
  if (hwnd == nullptr) {
    return false;
  }
  wchar_t name[32];
  if (::GetClassNameW(hwnd, name, 32) == 0) {
    return false;
  }
  return wcscmp(name, L"WorkerW") == 0 || wcscmp(name, L"Progman") == 0;
}

}  // namespace

MiniWindow::MiniWindow(std::function<void(const std::string&)> on_action) : on_action_(std::move(on_action)) {}

MiniWindow::~MiniWindow() { Destroy(); }

bool MiniWindow::WasOpen() {
  DWORD value = 0;
  DWORD size = sizeof(value);
  return ::RegGetValueW(HKEY_CURRENT_USER, kSettingsKey, kOpenValue, RRF_RT_REG_DWORD, nullptr, &value, &size) == ERROR_SUCCESS &&
         value == 1;
}

void MiniWindow::Open() {
  if (hwnd_ != nullptr) {
    ::ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
    if (layer_ != Layer::kDesktop) {
      ::SetForegroundWindow(hwnd_);
    }
    return;
  }
  static bool registered = false;
  if (!registered) {
    WNDCLASSW window_class{};
    window_class.lpfnWndProc = MiniWindow::WndProc;
    window_class.hInstance = ::GetModuleHandleW(nullptr);
    window_class.hCursor = ::LoadCursorW(nullptr, IDC_ARROW);
    window_class.lpszClassName = kClassName;
    registered = ::RegisterClassW(&window_class) != 0;
  }

  // Where it was, if that is still on a monitor; else the top right of the work area.
  RECT rect{};
  DWORD size = sizeof(rect);
  const bool saved = ::RegGetValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue, RRF_RT_REG_BINARY, nullptr, &rect, &size) ==
                         ERROR_SUCCESS &&
                     size == sizeof(rect) && ::MonitorFromRect(&rect, MONITOR_DEFAULTTONULL) != nullptr;
  if (!saved) {
    RECT work{};
    ::SystemParametersInfoW(SPI_GETWORKAREA, 0, &work, 0);
    const double scale = FlutterDesktopGetDpiForMonitor(::MonitorFromPoint({work.right - 1, work.top}, MONITOR_DEFAULTTOPRIMARY)) / 96.0;
    const int width = static_cast<int>(kWidth * scale);
    const int height = static_cast<int>(kHeight * scale);
    const int margin = static_cast<int>(24 * scale);
    rect = {work.right - width - margin, work.top + margin, work.right - margin, work.top + margin + height};
  }

  // No taskbar button and no Alt+Tab; a frame only to resize it (WM_NCCALCSIZE hides it).
  hwnd_ = ::CreateWindowExW(WS_EX_TOOLWINDOW, kClassName, L"Tarefas", WS_POPUP | WS_THICKFRAME | WS_CLIPCHILDREN, rect.left, rect.top,
                            rect.right - rect.left, rect.bottom - rect.top, nullptr, nullptr, ::GetModuleHandleW(nullptr), this);
  if (hwnd_ == nullptr) {
    return;
  }
  const BOOL dark = TRUE;
  ::DwmSetWindowAttribute(hwnd_, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, sizeof(dark));
  // Rounded corners on Windows 11 (DWMWCP_ROUND); Windows 10 ignores it.
  const int round = 2;
  ::DwmSetWindowAttribute(hwnd_, DWMWA_WINDOW_CORNER_PREFERENCE, &round, sizeof(round));
  ::SetWindowPos(hwnd_, nullptr, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  RECT client{};
  ::GetClientRect(hwnd_, &client);
  flutter::DartProject project(L"data");
  project.set_dart_entrypoint("miniCalendarMain");
  controller_ = std::make_unique<flutter::FlutterViewController>(client.right, client.bottom, project);
  if (!controller_->engine() || !controller_->view()) {
    controller_ = nullptr;
    HWND hwnd = hwnd_;
    hwnd_ = nullptr;
    ::DestroyWindow(hwnd);
    return;
  }
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(controller_->engine()->messenger(), "tarefas/mini",
                                                                               &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const flutter::MethodCall<flutter::EncodableValue>& call,
                                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    HandleCall(call, std::move(result));
  });
  HWND view = controller_->view()->GetNativeWindow();
  ::SetParent(view, hwnd_);
  ::MoveWindow(view, 0, 0, client.right, client.bottom, TRUE);
  // Shown once it has drawn, so it never flashes empty.
  controller_->engine()->SetNextFrameCallback([this]() {
    if (hwnd_ != nullptr) {
      ::ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
    }
  });
  controller_->ForceRedraw();
  SaveOpen(true);
}

void MiniWindow::Close() {
  if (hwnd_ == nullptr) {
    return;
  }
  SaveOpen(false);
  Destroy();
}

void MiniWindow::Destroy() {
  if (hwnd_ == nullptr) {
    return;
  }
  SavePlacement();
  ::KillTimer(hwnd_, kDesktopTimer);
  channel_ = nullptr;
  controller_ = nullptr;
  HWND hwnd = hwnd_;
  hwnd_ = nullptr;
  ::DestroyWindow(hwnd);
}

void MiniWindow::SavePlacement() {
  RECT rect{};
  if (hwnd_ != nullptr && ::GetWindowRect(hwnd_, &rect)) {
    ::RegSetKeyValueW(HKEY_CURRENT_USER, kSettingsKey, kPlacementValue, REG_BINARY, &rect, sizeof(rect));
  }
}

LRESULT CALLBACK MiniWindow::WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto* self = static_cast<MiniWindow*>(reinterpret_cast<CREATESTRUCTW*>(lparam)->lpCreateParams);
    ::SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    self->hwnd_ = hwnd;
  }
  auto* self = reinterpret_cast<MiniWindow*>(::GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  // Once destroyed (hwnd_ cleared first), its last messages go to Windows.
  if (self != nullptr && self->hwnd_ == hwnd) {
    return self->HandleMessage(message, wparam, lparam);
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

LRESULT MiniWindow::HandleMessage(UINT message, WPARAM wparam, LPARAM lparam) {
  if (controller_) {
    if (const auto result = controller_->HandleTopLevelWindowProc(hwnd_, message, wparam, lparam)) {
      return *result;
    }
  }
  switch (message) {
    case WM_NCCALCSIZE:
      // No visible frame: the view takes the whole window (the frame still lets it resize).
      if (wparam) {
        return 0;
      }
      break;
    case WM_GETMINMAXINFO: {
      const double scale = ::GetDpiForWindow(hwnd_) / 96.0;
      auto* info = reinterpret_cast<MINMAXINFO*>(lparam);
      info->ptMinTrackSize.x = static_cast<LONG>(kMinWidth * scale);
      info->ptMinTrackSize.y = static_cast<LONG>(kMinHeight * scale);
      return 0;
    }
    case WM_SIZE:
      if (controller_) {
        RECT client{};
        ::GetClientRect(hwnd_, &client);
        ::MoveWindow(controller_->view()->GetNativeWindow(), 0, 0, client.right, client.bottom, TRUE);
      }
      return 0;
    case WM_ACTIVATE:
      if (controller_) {
        ::SetFocus(controller_->view()->GetNativeWindow());
      }
      return 0;
    case WM_DPICHANGED: {
      const auto* rect = reinterpret_cast<RECT*>(lparam);
      ::SetWindowPos(hwnd_, nullptr, rect->left, rect->top, rect->right - rect->left, rect->bottom - rect->top,
                     SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
    case WM_EXITSIZEMOVE:
      SavePlacement();
      return 0;
    case WM_WINDOWPOSCHANGING:
      // On the desktop it stays below the other windows, even when clicked.
      if (layer_ == Layer::kDesktop && !above_desktop_) {
        auto* pos = reinterpret_cast<WINDOWPOS*>(lparam);
        if ((pos->flags & SWP_NOZORDER) == 0) {
          pos->hwndInsertAfter = HWND_BOTTOM;
        }
      }
      break;
    case WM_TIMER:
      if (wparam == kDesktopTimer) {
        FollowDesktop();
      }
      return 0;
    case WM_SYSCOMMAND:
      if ((wparam & 0xFFF0) == SC_MINIMIZE || (wparam & 0xFFF0) == SC_MAXIMIZE) {
        return 0;
      }
      break;
    case WM_CLOSE:
      Close();
      return 0;
  }
  return ::DefWindowProcW(hwnd_, message, wparam, lparam);
}

void MiniWindow::HandleCall(const flutter::MethodCall<flutter::EncodableValue>& call,
                            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const auto* arguments = call.arguments();
  if (method == "startDrag" || method == "startResize") {
    WPARAM hit = HTCAPTION;
    if (method == "startResize") {
      const auto* edge = std::get_if<int32_t>(arguments);
      if (edge == nullptr) {
        result->Error("bad_args", "startResize takes a hit-test code");
        return;
      }
      hit = static_cast<WPARAM>(*edge);
    }
    result->Success();
    // As if the frame were pressed: Windows moves or resizes it until the button is released.
    POINT cursor{};
    ::GetCursorPos(&cursor);
    ::ReleaseCapture();
    ::SendMessageW(hwnd_, WM_NCLBUTTONDOWN, hit, MAKELPARAM(cursor.x, cursor.y));
  } else if (method == "setLayer") {
    const auto* layer = std::get_if<int32_t>(arguments);
    if (layer == nullptr || *layer < 0 || *layer > 2) {
      result->Error("bad_args", "setLayer takes 0, 1 or 2");
      return;
    }
    SetLayer(static_cast<Layer>(*layer));
    result->Success();
  } else if (method == "close") {
    result->Success();
    // After the call returns: closing destroys the engine that made it.
    ::PostMessageW(hwnd_, WM_CLOSE, 0, 0);
  } else if (method == "action") {
    const auto* action = std::get_if<std::string>(arguments);
    if (action == nullptr) {
      result->Error("bad_args", "action takes a string");
      return;
    }
    result->Success();
    on_action_(*action);
  } else {
    result->NotImplemented();
  }
}

void MiniWindow::SetLayer(Layer layer) {
  layer_ = layer;
  above_desktop_ = false;
  ::KillTimer(hwnd_, kDesktopTimer);
  constexpr UINT flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;
  switch (layer) {
    case Layer::kTop:
      ::SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0, flags);
      break;
    case Layer::kNormal:
      ::SetWindowPos(hwnd_, HWND_NOTOPMOST, 0, 0, 0, 0, flags);
      break;
    case Layer::kDesktop:
      ::SetWindowPos(hwnd_, HWND_NOTOPMOST, 0, 0, 0, 0, flags);
      ::SetWindowPos(hwnd_, HWND_BOTTOM, 0, 0, 0, 0, flags);
      ::SetTimer(hwnd_, kDesktopTimer, 300, nullptr);
      break;
  }
}

void MiniWindow::FollowDesktop() {
  // "Mostrar a área de trabalho" may minimize it: it comes back.
  if (::IsIconic(hwnd_)) {
    ::ShowWindow(hwnd_, SW_SHOWNOACTIVATE);
  }
  // The desktop in front (Win + D, or a click on it) brings the window above everything until
  // another window is used; a click on the window itself changes nothing.
  const HWND foreground = ::GetForegroundWindow();
  const bool desktop = foreground == hwnd_ ? above_desktop_ : IsDesktop(foreground);
  if (desktop == above_desktop_) {
    return;
  }
  above_desktop_ = desktop;
  constexpr UINT flags = SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE;
  if (desktop) {
    ::SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0, flags);
  } else {
    ::SetWindowPos(hwnd_, HWND_NOTOPMOST, 0, 0, 0, 0, flags);
    ::SetWindowPos(hwnd_, HWND_BOTTOM, 0, 0, 0, 0, flags);
  }
}
