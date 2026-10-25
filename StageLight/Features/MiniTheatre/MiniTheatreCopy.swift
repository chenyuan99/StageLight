import Foundation

enum MiniCopy {
    static func text(_ key: String, _ language: String) -> String {
        let index = language.hasPrefix("ja") ? 3 : language.hasPrefix("zh") ?
            (language.contains("Hant") || language.contains("TW") || language.contains("HK") ? 2 : 1) : 0
        return values[key]?[index] ?? key
    }
    static let values: [String: [String]] = [
        "tab": ["Mini Theatre", "小剧场", "小劇場", "小さな劇場"],
        "title": ["Mini Theatre", "掌上小剧场", "掌上小劇場", "小さな劇場"],
        "enable": ["Enable Mini Theatre", "开启掌上小剧场", "開啟掌上小劇場", "小さな劇場を有効にする"],
        "privacy": ["Optional. Props and outfits stay in a separate local store and do not sync with iCloud. Device backups may include them; reinstalling may lose them. Your diary keeps its existing private iCloud settings.", "可选功能。道具与装扮保存在独立本地存储，不通过 iCloud 同步；设备备份可能包含它们，重装可能丢失。日记仍沿用现有的私密 iCloud 设置。", "可選功能。道具與裝扮保存在獨立本機儲存，不透過 iCloud 同步；裝置備份可能包含它們，重新安裝可能遺失。日記仍沿用現有的私密 iCloud 設定。", "任意の機能です。小道具と衣装は別のローカル保存領域に保存され、iCloud同期されません。端末のバックアップに含まれる場合があり、再インストールで失われる可能性があります。日記のプライベートiCloud設定は変わりません。"],
        "shortcut": ["Show Collection shortcut", "在收藏显示入口", "在收藏顯示入口", "コレクションに入口を表示"],
        "haptics": ["Gentle haptics", "轻触反馈", "輕觸回饋", "触覚フィードバック"],
        "intro": ["Every performance leaves a little light.", "每一场，都留下点光。", "每一場，都留下點光。", "一公演ごとに、小さな光を。"],
        "name": ["Little Light", "小剧灯", "小劇燈", "あかり"],
        "props": ["My props", "我的道具", "我的道具", "小道具"],
        "welcome_pennant": ["Welcome pennant", "欢迎小旗", "歡迎小旗", "歓迎の旗"],
        "keepsake_ticket": ["Keepsake ticket", "纪念票根", "紀念票根", "思い出のチケット"],
        "golden_spotlight": ["Golden spotlight", "金色追光灯", "金色追光燈", "金色のスポットライト"],
        "velvet_curtain": ["Velvet curtain", "丝绒幕布", "絲絨幕布", "ベルベットの幕"],
        "memory_bouquet": ["Memory bouquet", "纪念花束", "紀念花束", "思い出の花束"],
        "theatre_suitcase": ["Theatre suitcase", "剧院旅行箱", "劇院旅行箱", "劇場のスーツケース"],
        "welcome": ["Enable Mini Theatre", "开启小剧场", "開啟小劇場", "小さな劇場を有効にする"],
        "visits_1": ["1 past performance", "记录 1 场往日演出", "記錄 1 場往日演出", "過去の公演を1回記録"],
        "visits_3": ["3 past performances", "记录 3 场往日演出", "記錄 3 場往日演出", "過去の公演を3回記録"],
        "visits_5": ["5 past performances", "记录 5 场往日演出", "記錄 5 場往日演出", "過去の公演を5回記録"],
        "visits_10": ["10 past performances", "记录 10 场往日演出", "記錄 10 場往日演出", "過去の公演を10回記録"],
        "venues_3": ["3 different theatres", "记录 3 家不同剧院", "記錄 3 家不同劇院", "異なる劇場を3か所記録"],
        "policy": ["Only dates before today count. Go at your own pace: props never expire. Turning this off keeps your collection.", "仅统计今天之前的演出。按自己的节奏记录，道具永不过期；关闭功能也会保留收藏。", "僅統計今天之前的演出。按自己的節奏記錄，道具永不過期；關閉功能也會保留收藏。", "今日より前の日付が対象です。自分のペースで。小道具は失効せず、機能をオフにしても保持されます。"],
        "equip": ["Equip", "摆放", "擺放", "配置する"],
        "unequip": ["Remove", "收起", "收起", "外す"],
        "locked": ["Locked", "未解锁", "未解鎖", "未獲得"],
        "owned": ["Collected", "已收集", "已收集", "獲得済み"],
        "new": ["New props are ready", "新道具已入库", "新道具已入庫", "新しい小道具を獲得しました"],
        "done": ["Done", "完成", "完成", "完了"],
        "retry": ["Retry", "重试", "重試", "再試行"],
        "error": ["Could not save Mini Theatre. Your diary is unaffected. Please retry. Nicknames must contain 1–24 characters.", "小剧场保存失败，不影响日记，请重试。昵称需为 1–24 个字符。", "小劇場儲存失敗，不影響日記，請重試。暱稱需為 1–24 個字元。", "保存できませんでした。日記には影響しません。再試行してください。名前は1〜24文字で入力してください。"],
        "nickname": ["Nickname", "昵称", "暱稱", "名前"],
        "save": ["Save name", "保存昵称", "儲存暱稱", "名前を保存"],
        "share": ["Share my theatre", "分享小剧场", "分享小劇場", "劇場をシェア"],
        "export": ["Share or save image", "分享或保存图片", "分享或儲存圖片", "画像を共有・保存"],
        "sharePrivacy": ["Only the bunny and outfit are shared. No nickname or diary details.", "仅分享小兔与装扮，不包含昵称或日记内容。", "僅分享小兔與裝扮，不包含暱稱或日記內容。", "うさぎと小道具だけを共有します。名前や日記の内容は含みません。"],
        "link": ["Include App Store link", "附上 App Store 链接", "附上 App Store 連結", "App Storeリンクを含める"],
        "reflect": ["What moment would you like to remember?", "有什么瞬间想留住？", "有什麼瞬間想留住？", "どんな瞬間を残したいですか？"],
        "note": ["Edit latest performance notes (optional)", "编辑最近演出的笔记（可选）", "編輯最近演出的筆記（可選）", "最近の公演のメモを編集（任意）"]
    ]
}
