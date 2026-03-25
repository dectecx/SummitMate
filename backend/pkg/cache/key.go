package cache

import "fmt"

// Module 定義了一個專屬型別，用於限制模組名稱。
type Module string

// 模組名稱定義，集中管理以防止命名衝突。
const (
	ModuleAuth    Module = "auth"
	ModuleTrip    Module = "trip"
	ModuleWeather Module = "weather"
)

// Key 代表一個結構化的快取 Key，用於防止碰撞並強制執行命名規範。
type Key struct {
	Module Module
	Domain string
	ID     string
}

// String 將 Key 轉換為符合規範的字串格式：summitmate:<module>:<domain>:<id>
func (k Key) String() string {
	return fmt.Sprintf("summitmate:%s:%s:%s", string(k.Module), k.Domain, k.ID)
}
