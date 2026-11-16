# Complete 17-Language Localization System

[← Back to Wiki Home](Home.md)

## 🌍 All 17 Supported Languages

SS-CCC is **100% localized** across all 11 views, submenus, tooltips (**Solaris Shorttip Banner**), the **12-chapter Click-to-Detail Help Center** (`⌘?`), the **Menu Bar Background Service popover**, and **17 repository READMEs**:

| # | Language | Native Name | Code | README File |
|---:|:---|:---|:---|:---|
| 1 | English | English | `en` | [`README.md`](../README.md) |
| 2 | German | Deutsch | `de` | [`README.de.md`](../README.de.md) |
| 3 | French | Français | `fr` | [`README.fr.md`](../README.fr.md) |
| 4 | Spanish | Español | `es` | [`README.es.md`](../README.es.md) |
| 5 | Portuguese | Português | `pt` | [`README.pt.md`](../README.pt.md) |
| 6 | Russian | Русский | `ru` | [`README.ru.md`](../README.ru.md) |
| 7 | Japanese | 日本語 | `ja` | [`README.ja.md`](../README.ja.md) |
| 8 | Chinese | 中文 | `zh` | [`README.zh.md`](../README.zh.md) |
| 9 | Dutch | Nederlands | `nl` | [`README.nl.md`](../README.nl.md) |
| 10 | Afrikaans | Afrikaans | `af` | [`README.af.md`](../README.af.md) |
| 11 | Polish | Polski | `pl` | [`README.pl.md`](../README.pl.md) |
| 12 | Czech | Čeština | `cs` | [`README.cs.md`](../README.cs.md) |
| 13 | Slovak | Slovenčina | `sk` | [`README.sk.md`](../README.sk.md) |
| 14 | Hungarian | Magyar | `hu` | [`README.hu.md`](../README.hu.md) |
| 15 | Korean | 한국어 | `ko` | [`README.ko.md`](../README.ko.md) |
| 16 | Hindi | हिन्दी | `hi` | [`README.hi.md`](../README.hi.md) |
| 17 | Tamil | தமிழ் | `ta` | [`README.ta.md`](../README.ta.md) |

---

## ⚙️ How Localization Works

- `app/Sources/Models/Localization.swift` defines `enum AppLanguage` (`CaseIterable`, 17 cases) with Foundation-only dictionaries (`L10n.text`, `L10n.tr`, and `L10nExtendedCatalog`) plus regex rules for dynamic interpolated strings (`NSRegularExpression`).
- `app/Sources/Views/HelpDocsView.swift` stores all 12 Help chapters with strictly identical chapter IDs across all 17 languages — automatically verified on every run by `tests/test_global_suite.py` (`test_15` & `test_25`) and `tests/run_swift_checks.swift`.
