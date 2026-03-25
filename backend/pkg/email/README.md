# Email Module

這個模組提供了一個輕量、靈活且易於移植的 Go 電子郵件發送方案。

## 目錄結構

- `config.go`: SMTP 配置結構。
- `mailer.go`: 核心 SMTP 發送邏輯（基於 `net/smtp`）。
- `template.go`: 使用 `html/template` 與 `embed` 進行樣板渲染。
- `service.go`: 高階業務邏輯（例如發送驗證碼、密碼重置等）。
- `templates/`: HTML 電子郵件樣板。

## 使用方式

### 1. 初始化

```go
import "summitmate/pkg/email"

// 配置 SMTP
cfg := email.SMTPConfig{
    Host:     "smtp.gmail.com",
    Port:     "587",
    Username: "your-email@gmail.com",
    Password: "your-app-password",
    From:     "SummitMate <noreply@summitmate.com>",
}

// 建立元件
mailer := email.NewMailer(cfg)
tmplMgr, _ := email.NewTemplateManager()
emailService := email.NewEmailService(mailer, tmplMgr)

// 發送電子郵件
err := emailService.SendVerificationCode("user@example.com", "123456", 10)
```

### 2. 環境變數配置

在專案中，建議透過 `internal/config` 載入以下環境變數：

- `SMTP_HOST`: SMTP 伺服器位置 (預設: `smtp.gmail.com`)
- `SMTP_PORT`: 連接埠 (預設: `587`)
- `SMTP_USER`: 帳號 (Gmail 地址)
- `SMTP_PASS`: 密碼 (**必須使用 Google 應用程式密碼**)
- `SMTP_FROM`: 寄件者名稱與地址

## 如何設定 Google 應用程式密碼 (App Password)

為了安全性，Google 不允許直接使用帳戶密碼發送信件，必須建立「應用程式密碼」：

1. 登入 Google 帳戶，進入「安全性」設定。
2. 確保已開啟「兩步驟驗證」。
3. 在搜尋框輸入「應用程式密碼」(App Passwords)。
4. 建立一個新的應用程式（例如：SummitMate Backend）。
5. 產生的 16 位數密碼即為 `SMTP_PASS`。

## 移植到其他專案

只需將整個 `pkg/email` 資料夾複製到新專案的 `pkg` 目錄下，並根據需要修改 `go.mod` 中的 module 名稱即可。
