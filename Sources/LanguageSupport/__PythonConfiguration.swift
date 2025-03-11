//
//  PythonConfiguration.swift
//
//
//  Created by [Your Name] on [Date].
//
//  This configuration attempts to handle Python 3 language features as thoroughly as possible
//  in the style of the other language configurations.
//


//
//  JavaScriptTypeScriptCAndCxxConfigurations.swift
//
//  Created by [Your Name] on [Date].
//

import Foundation
import RegexBuilder

// ===========================================================================
// MARK: - JavaScript
// ===========================================================================

private let jsReservedKeywords: [String] = [
    // ECMAScript Keywords
    "break", "case", "catch", "class", "const", "continue",
    "debugger", "default", "delete", "do", "else",
    "export", "extends", "finally", "for", "function",
    "if", "import", "in", "instanceof",
    "new", "return", "super", "switch",
    "this", "throw", "try", "typeof",
    "var", "void", "while", "with", "yield",
    // Additional strict mode / future reserved
    "enum", "implements", "interface", "let", "package", "private",
    "protected", "public", "static", "await"
]

private let jsReservedOperators: [String] = [
    // Common operators (simplified)
    "+", "-", "*", "/", "%", "**",
    "++", "--",
    "=", "+=", "-=", "*=", "/=", "%=", "**=",
    "&=", "|=", "^=", ">>=", ">>>=", "<<=",
    // Comparison
    "==", "!=", "===", "!==", ">", "<", ">=", "<=",
    // Logical
    "&&", "||", "!", "??",
    // Bitwise
    "&", "|", "^", "~", ">>", ">>>", "<<",
    // Arrow
    "=>"
]

// JavaScript numeric literal (simplified):
//  - Optional sign
//  - Binary (0b...), octal (0o...), hex (0x...), decimal with optional exponent
//  - Optional BigInt suffix 'n' if integer
private let jsNumberRegex = Regex {
    // Optional sign
    Optionally { CharacterClass(.anyOf("+-")) }
    ChoiceOf {
        // Binary: 0b...
        Regex {
            "0"
            CharacterClass(.anyOf("bB"))
            OneOrMore(.anyOf("01"))
            ZeroOrMore {
                "_"
                OneOrMore(.anyOf("01"))
            }
            Optionally { "n" } // BigInt suffix
        }
        // Octal: 0o...
        Regex {
            "0"
            CharacterClass(.anyOf("oO"))
            OneOrMore(.anyOf("01234567"))
            ZeroOrMore {
                "_"
                OneOrMore(.anyOf("01234567"))
            }
            Optionally { "n" }
        }
        // Hex: 0x...
        Regex {
            "0"
            CharacterClass(.anyOf("xX"))
            OneOrMore(.hexDigit)
            ZeroOrMore {
                "_"
                OneOrMore(.hexDigit)
            }
            Optionally { "n" }
        }
        // Decimal or float, possibly with exponent, or BigInt
        // Examples: 123, 123.456, .456, 123e10, etc.
        Regex {
            ChoiceOf {
                // Full numeric form: digits (dot digits)? exponent? or plain integer
                Regex {
                    OneOrMore(.digit)
                    ZeroOrMore {
                        "_"
                        OneOrMore(.digit)
                    }
                    // Optional .digits
                    Optionally {
                        "."
                        OneOrMore(.digit)
                        ZeroOrMore {
                            "_"
                            OneOrMore(.digit)
                        }
                    }
                    // Optional exponent
                    Optionally {
                        CharacterClass(.anyOf("eE"))
                        Optionally { CharacterClass(.anyOf("+-")) }
                        OneOrMore(.digit)
                        ZeroOrMore {
                            "_"
                            OneOrMore(.digit)
                        }
                    }
                    // Optional BigInt suffix, but only if there's no decimal/exponent
                    NegativeLookahead {
                        "." // no decimal
                    }
                    NegativeLookahead {
                        CharacterClass(.anyOf("eE"))
                    }
                    Optionally { "n" }
                }
                // Leading dot float: e.g. .123, .123e10
                Regex {
                    "."
                    OneOrMore(.digit)
                    ZeroOrMore {
                        "_"
                        OneOrMore(.digit)
                    }
                    Optionally {
                        CharacterClass(.anyOf("eE"))
                        Optionally { CharacterClass(.anyOf("+-")) }
                        OneOrMore(.digit)
                        ZeroOrMore {
                            "_"
                            OneOrMore(.digit)
                        }
                    }
                }
            }
        }
    }
}

// JavaScript string literals (simplified):
//  - Single quotes
//  - Double quotes
//  - Backtick (template strings, ignoring internal `${}` expansions)
private let jsStringRegex = Regex {
    ChoiceOf {
        // Double-quoted
        Regex {
            "\""
            ZeroOrMore {
                ChoiceOf {
                    "\\\""              // Escaped quote
                    NegativeLookahead { "\"" }
                    /./
                }
            }
            "\""
        }
        // Single-quoted
        Regex {
            "'"
            ZeroOrMore {
                ChoiceOf {
                    "\\'"               // Escaped quote
                    NegativeLookahead { "'" }
                    /./
                }
            }
            "'"
        }
        // Backtick (template) - ignoring expansions
        Regex {
            "`"
            ZeroOrMore {
                ChoiceOf {
                    "\\`"
                    NegativeLookahead { "`" }
                    /./
                }
            }
            "`"
        }
    }
}

private let jsIdentifierRegex = Regex {
    LanguageConfiguration.identifierHeadCharacters
    ZeroOrMore {
        LanguageConfiguration.identifierCharacters
    }
}

extension LanguageConfiguration {
    /// Language configuration for JavaScript
    public static func javascript(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        return LanguageConfiguration(
            name: "JavaScript",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: false,
            stringRegex: jsStringRegex,
            characterRegex: nil,      // JavaScript doesn't have a distinct char literal
            numberRegex: jsNumberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),
            identifierRegex: jsIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: jsReservedKeywords,
            reservedOperators: jsReservedOperators,
            languageService: languageService
        )
    }
}


// ===========================================================================
// MARK: - TypeScript
// ===========================================================================
private let tsReservedKeywords: [String] = [
    // Include JavaScript keywords
    "break", "case", "catch", "class", "const", "continue",
    "debugger", "default", "delete", "do", "else",
    "export", "extends", "finally", "for", "function",
    "if", "import", "in", "instanceof",
    "new", "return", "super", "switch",
    "this", "throw", "try", "typeof",
    "var", "void", "while", "with", "yield",
    "enum", "implements", "interface", "let", "package",
    "private", "protected", "public", "static", "await",
    // TypeScript-specific additions
    "abstract", "as", "asserts", "any", "bigint", "boolean",
    "declare", "enum", "from", "global", "infer", "is",
    "keyof", "module", "namespace", "never", "readonly",
    "require", "number", "object", "readonly", "string",
    "symbol", "type", "unique", "unknown"
]

private let tsReservedOperators = jsReservedOperators

// For TypeScript, most lexical rules are identical or very similar to JavaScript
// We'll reuse the same regex components from JavaScript.
extension LanguageConfiguration {
    /// Language configuration for TypeScript
    public static func typescript(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        return LanguageConfiguration(
            name: "TypeScript",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: false,
            stringRegex: jsStringRegex,
            characterRegex: nil,
            numberRegex: jsNumberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),
            identifierRegex: jsIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: tsReservedKeywords,
            reservedOperators: tsReservedOperators,
            languageService: languageService
        )
    }
}


// ===========================================================================
// MARK: - C
// ===========================================================================

private let cReservedKeywords: [String] = [
    "auto", "break", "case", "char", "const", "continue",
    "default", "do", "double", "else", "enum", "extern",
    "float", "for", "goto", "if", "inline", "int", "long",
    "register", "restrict", "return", "short", "signed",
    "sizeof", "static", "struct", "switch", "typedef",
    "union", "unsigned", "void", "volatile", "while",
    // C11
    "_Alignas", "_Alignof", "_Atomic", "_Bool", "_Complex",
    "_Generic", "_Imaginary", "_Noreturn", "_Static_assert", "_Thread_local"
]

private let cReservedOperators: [String] = [
    // Arithmetic + assignment
    "+", "-", "*", "/", "%",
    "=", "+=", "-=", "*=", "/=", "%=",
    // Increment / decrement
    "++", "--",
    // Bitwise
    "<<", ">>", "&", "|", "^", "~",
    "<<=", ">>=", "&=", "|=", "^=",
    // Logical
    "&&", "||", "!",
    // Comparison
    "==", "!=", ">", "<", ">=", "<=",
    // Ternary
    "?", ":",
    // Pointer
    "*", "&"
]

// C numeric literals (simplified):
//  - Optional sign
//  - Hex, octal, decimal
//  - Float with optional exponent
private let cNumberRegex = Regex {
    Optionally { CharacterClass(.anyOf("+-")) }
    ChoiceOf {
        // Hex: 0[xX], then hex digits, optional fraction and exponent
        Regex {
            "0"
            CharacterClass(.anyOf("xX"))
            OneOrMore(.hexDigit)
            ZeroOrMore {
                "_"
                OneOrMore(.hexDigit)
            }
            // Optional . followed by hex digits (hex float)
            Optionally {
                "."
                OneOrMore(.hexDigit)
                ZeroOrMore {
                    "_"
                    OneOrMore(.hexDigit)
                }
            }
            // Optional exponent: [pP][+-]?digits
            Optionally {
                CharacterClass(.anyOf("pP"))
                Optionally { CharacterClass(.anyOf("+-")) }
                OneOrMore(.digit)
            }
            // Optional type suffix (f, F, l, L, u, U, etc.) - very simplified
            ZeroOrMore {
                CharacterClass(.anyOf("fFlLuU"))
            }
        }
        // Octal: 0[0-7]...
        Regex {
            "0"
            OneOrMore(.anyOf("01234567"))
            ZeroOrMore {
                CharacterClass(.anyOf("fFlLuU")) // optional suffix
            }
        }
        // Decimal / float
        Regex {
            OneOrMore(.digit)
            ZeroOrMore {
                "_"
                OneOrMore(.digit)
            }
            // Optional decimal fraction
            Optionally {
                "."
                OneOrMore(.digit)
                ZeroOrMore {
                    "_"
                    OneOrMore(.digit)
                }
            }
            // Optional exponent
            Optionally {
                CharacterClass(.anyOf("eE"))
                Optionally { CharacterClass(.anyOf("+-")) }
                OneOrMore(.digit)
                ZeroOrMore {
                    "_"
                    OneOrMore(.digit)
                }
            }
            // Optional suffix
            ZeroOrMore {
                CharacterClass(.anyOf("fFlLuU"))
            }
        }
    }
}

// C string literals:
//  - Double-quoted, possibly with escapes
//  - We skip wide string (L"..."), UTF-8 (u8"..."), etc. in this simple example
private let cStringRegex = Regex {
    ChoiceOf {
        // "..."
        Regex {
            "\""
            ZeroOrMore {
                ChoiceOf {
                    "\\\""
                    NegativeLookahead { "\"" }
                    /./
                }
            }
            "\""
        }
    }
}

// C character literal: 'a', '\n', etc., or wide/UTF forms (L'a', u8'a', etc.)
// We'll do a simplified approach ignoring complexities of multi-char literals.
private let cCharRegex = Regex {
    ChoiceOf {
        // Optional prefix: L, u8, u, U
        Regex {
            ChoiceOf {
                "L"
                "u8"
                "u"
                "U"
            }
        }
        "'"
        ZeroOrMore {
            ChoiceOf {
                "\\'"
                NegativeLookahead { "'" }
                /./
            }
        }
        "'"
    }
}

// C identifier: [a-zA-Z_][a-zA-Z0-9_]*
private let cIdentifierHead = CharacterClass(
    "a"..."z",
    "A"..."Z",
    .anyOf("_")
)

private let cIdentifierBody = CharacterClass(
    "a"..."z",
    "A"..."Z",
    "0"..."9",
    .anyOf("_")
)

private let cIdentifierRegex = Regex {
    cIdentifierHead
    ZeroOrMore {
        cIdentifierBody
    }
}

extension LanguageConfiguration {
    /// Language configuration for C
    public static func c(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        return LanguageConfiguration(
            name: "C",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: false,
            stringRegex: cStringRegex,
            characterRegex: cCharRegex,
            numberRegex: cNumberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),  // Not truly "nested" in standard C
            identifierRegex: cIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: cReservedKeywords,
            reservedOperators: cReservedOperators,
            languageService: languageService
        )
    }
}



//
//  OtherLanguagesConfiguration.swift
//
//  Created by [Your Name] on [Date].
//

import Foundation
import RegexBuilder

extension LanguageConfiguration {
    
    // MARK: - HTML
    
    /// 簡易的なHTMLのLanguageConfiguration
    /// - コメント: `<!-- ... -->` (入れ子コメントは不可)
    /// - タグ・属性などの正規表現は最低限の簡易版
    /// - 文字列: シングルクォートまたはダブルクォート
    public static func html(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        // HTMLでは属性値などで使う文字列を最小限に定義
        let htmlStringRegex: Regex<Substring> = Regex {
            ChoiceOf {
                Regex {
                    "\""
                    ZeroOrMore {
                        ChoiceOf {
                            "\\\""          // バックスラッシュでエスケープされたダブルクォート
                            NegativeLookahead { "\"" }
                            /./
                        }
                    }
                    "\""
                }
                Regex {
                    "'"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'" }
                            /./
                        }
                    }
                    "'"
                }
            }
        }
        
        // タグ名や属性名の簡易的なもの (コロンやハイフンなども許容)
        let htmlIdentifierRegex = Regex {
            // 先頭: 英字, _, コロンなど
            CharacterClass("a"..."z", "A"..."Z", .anyOf("-_:"))
            ZeroOrMore {
                CharacterClass("a"..."z", "A"..."Z", "0"..."9", .anyOf("_-:."))
            }
        }
        
        return LanguageConfiguration(
            name: "HTML",
            supportsSquareBrackets: false,
            supportsCurlyBrackets: false,
            indentationSensitiveScoping: false,
            // 文字列としては属性値用のシンプルな定義を利用
            stringRegex: htmlStringRegex,
            characterRegex: nil,  // HTML独自のcharリテラルはなし
            numberRegex: nil,      // 数値リテラルの識別は特になし
            singleLineComment: nil, // HTMLにはシングルラインコメントが無いためnil
            nestedComment: (open: "<!--", close: "-->"), // HTMLコメント
            identifierRegex: htmlIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: [],
            reservedOperators: [],
            languageService: languageService
        )
    }
    
    // MARK: - CSS
    
    /// 簡易的なCSSのLanguageConfiguration
    /// - コメント: `/* ... */` (ネスト不可)
    /// - 文字列: シングル/ダブルクォートを最低限サポート
    /// - セレクタなどの識別子の正規表現は簡易版
    public static func css(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        // CSSでの文字列 (シンプル版)
        let cssStringRegex: Regex<Substring> = Regex {
            ChoiceOf {
                // "..."
                Regex {
                    "\""
                    ZeroOrMore {
                        ChoiceOf {
                            "\\\""
                            NegativeLookahead { "\"" }
                            /./
                        }
                    }
                    "\""
                }
                // '...'
                Regex {
                    "'"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'" }
                            /./
                        }
                    }
                    "'"
                }
            }
        }
        
        // CSSの識別子 (非常に簡略化: `-?[a-zA-Z_][a-zA-Z0-9_-]*`)
        let cssIdentifierRegex = Regex {
            Optionally {
                "-"
            }
            CharacterClass("a"..."z", "A"..."Z", .anyOf("_"))
            ZeroOrMore {
                CharacterClass("a"..."z", "A"..."Z", "0"..."9", .anyOf("_-"))
            }
        }
        
        // CSSの数値（単位含むなど細かい定義は省略し、簡易的なリテラルのみ）
        let cssNumberRegex: Regex<Substring> = Regex {
            optNegation
            ChoiceOf {
                // 整数または小数 (ex: 123, 123.45, .45)
                Regex {
                    OneOrMore(.digit)
                    Optionally {
                        "."
                        OneOrMore(.digit)
                    }
                }
                // 先頭が小数点の場合 (ex: .45)
                Regex {
                    "."
                    OneOrMore(.digit)
                }
            }
            // 単位などはここでは省略
        }
        
        return LanguageConfiguration(
            name: "CSS",
            supportsSquareBrackets: true,   // CSSの属性セレクタで [] を使うためtrueに
            supportsCurlyBrackets: true,    // CSSは {} を使う
            indentationSensitiveScoping: false,
            stringRegex: cssStringRegex,
            characterRegex: nil,
            numberRegex: cssNumberRegex,
            singleLineComment: nil,              // CSSにシングルラインコメントはなし
            nestedComment: (open: "/*", close: "*/"), // CSSのブロックコメント
            identifierRegex: cssIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: [],
            reservedOperators: [],
            languageService: languageService
        )
    }
    
    // MARK: - Java
    
    /// 簡易的なJavaのLanguageConfiguration
    /// - コメント: `// ...` (シングルライン), `/* ... */` (入れ子不可)
    /// - 数値: 2進数, 8進数, 10進数, 16進数をサポート (浮動小数点含む)
    /// - 文字列: `"..."`, 文字リテラル: `'...'`
    /// - 識別子: `[a-zA-Z_][a-zA-Z0-9_]*`
    /// - 予約語を定義
    public static func java(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        // Javaキーワードリスト
        let javaReservedKeywords = [
            "abstract", "assert", "boolean", "break", "byte",
            "case", "catch", "char", "class", "const",
            "continue", "default", "do", "double", "else",
            "enum", "extends", "final", "finally", "float",
            "for", "goto", "if", "implements", "import",
            "instanceof", "int", "interface", "long", "native",
            "new", "package", "private", "protected", "public",
            "return", "short", "static", "strictfp", "super",
            "switch", "synchronized", "this", "throw", "throws",
            "transient", "try", "void", "volatile", "while"
        ]
        
        let javaReservedOperators = [
            "=", "==", "===", "!", "!=", "<", "<=", ">", ">=",
            "++", "--", "+", "-", "*", "/", "%",
            "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "~",
            ">>", ">>>", "<<", ">>=", ">>>=", "<<=", "&", "|", "^",
            "&&", "||", "!", "??", "?", ":",
            "->", ".", "::", "=>"
        ]
        
        // Javaの数値: PythonやHaskellなどの例と同様に組み立て
        // (2進数 0b..., 8進数 0..., 16進数 0x..., 10進数, 浮動小数など)
        // ここでは既存の `optNegation`, `decimalLit`, `hexalLit`, `exponentLit` などを活用
        let javaNumberRegex = Regex {
            optNegation
            ChoiceOf {
                // バイナリ (Java 7以降でサポート 0b / 0B)
                Regex {
                    "0"
                    CharacterClass(.anyOf("bB"))
                    binaryLit
                }
                // 16進
                Regex {
                    "0"
                    CharacterClass(.anyOf("xX"))
                    // 0x1.2p3 のような浮動小数形態もJavaにはあるが、やや特殊なので割愛か簡易対応
                    ChoiceOf {
                        // 例: 0x1.2p3 -> 16進浮動小数
                        Regex {
                            hexalLit
                            "."
                            hexalLit
                            hexponentLit
                        }
                        // 例: 0xFF
                        hexalLit
                    }
                }
                // 10進 (浮動小数含む)
                Regex {
                    decimalLit
                    ChoiceOf {
                        // 例: 123.456
                        Regex {
                            "."
                            decimalLit
                            Optionally {
                                exponentLit
                            }
                        }
                        // 例: 123e45
                        exponentLit
                        // 例: 123 (整数)
                        Regex{}
                    }
                }
            }
        }
        
        // Javaの文字列, 文字リテラル (簡易)
        let javaStringRegex = Regex {
            ChoiceOf {
                // "..."
                Regex {
                    "\""
                    ZeroOrMore {
                        ChoiceOf {
                            "\\\""
                            NegativeLookahead { "\"" }
                            /./
                        }
                    }
                    "\""
                }
                // '...'
                Regex {
                    "'"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'" }
                            /./
                        }
                    }
                    "'"
                }
            }
        }
        let javaCharRegex = Regex {
            ChoiceOf {
                // 'a' (シングルクォート)
                Regex {
                    "'"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'" }
                            /./
                        }
                    }
                    "'"
                }
            }
        }
        
        // Javaの識別子 (簡易): [a-zA-Z_][a-zA-Z0-9_]*
        let javaIdentifierRegex = Regex {
            ChoiceOf {
                CharacterClass("a"..."z", "A"..."Z")
                "_"
            }
            ZeroOrMore {
                ChoiceOf {
                    CharacterClass("a"..."z", "A"..."Z", "0"..."9")
                    "_"
                }
            }
        }
        
        return LanguageConfiguration(
            name: "Java",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: false,
            stringRegex: javaStringRegex,
            characterRegex: javaCharRegex,
            numberRegex: javaNumberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),
            identifierRegex: javaIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: javaReservedKeywords,
            reservedOperators: javaReservedOperators,
            languageService: languageService
        )
    }
    
    // MARK: - Dart
    
    /// 簡易的なDartのLanguageConfiguration
    /// - コメント: `// ...` (シングルライン), `/* ... */` (ネスト不可)
    /// - 数値: 2進, 8進, 10進, 16進をサポート
    /// - 文字列: シングル/ダブル/三重クォートなど多彩だが、ここではシンプルに
    /// - 識別子: [a-zA-Z_][a-zA-Z0-9_]*
    /// - 予約語も定義
    public static func dart(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        let dartReservedKeywords = [
            "abstract", "as", "assert", "async", "await",
            "break", "case", "catch", "class", "const",
            "continue", "covariant", "default", "deferred", "do",
            "dynamic", "else", "enum", "export", "extends",
            "extension", "external", "factory", "false", "final",
            "finally", "for", "function", "get", "hide",
            "if", "implements", "import", "in", "interface",
            "is", "late", "let", "library", "mixin",
            "native", "new", "null", "of", "on",
            "operator", "part", "required", "rethrow", "return",
            "sealed", "set", "show", "static", "super",
            "switch", "sync", "this", "throw", "true",
            "try", "typedef", "var", "void", "while",
            "with", "yield"
        ]
        
        // Dartオペレータの例
        let dartReservedOperators = [
            "+", "-", "*", "/", "~/", "%",
            "++", "--", "==", "!=", "<", "<=", ">", ">=",
            "&&", "||", "!", "?", "??", "??=",
            "&", "|", "^", "~", "<<", ">>",
            "+=", "-=", "*=", "/=", "~/=", "%=",
            "&=", "|=", "^=", ">>=", "<<=", "??"
        ]
        
        // Dartの数値 (Javaと似た形で)
        let dartNumberRegex = Regex {
            optNegation
            ChoiceOf {
                // 2進 (Dart 2.1~)
                Regex {
                    "0"
                    CharacterClass(.anyOf("bB"))
                    binaryLit
                }
                // 16進
                Regex {
                    "0"
                    CharacterClass(.anyOf("xX"))
                    // 0x1.2p3 などの表現はDartでもサポートされるが、簡易対応
                    ChoiceOf {
                        Regex {
                            hexalLit
                            "."
                            hexalLit
                            hexponentLit
                        }
                        hexalLit
                    }
                }
                // 10進 (浮動小数含む)
                Regex {
                    decimalLit
                    ChoiceOf {
                        Regex {
                            "."
                            decimalLit
                            Optionally {
                                exponentLit
                            }
                        }
                        exponentLit
                        Regex {}
                    }
                }
            }
        }
        
        // Dartの文字列はシングルクォート、ダブルクォート、三重クォートなど色々あるが
        // ここでは単純に "..." と '...' を合体した最低限版で対応
        let dartStringRegex = Regex {
            ChoiceOf {
                // """...""" (簡易)
                Regex {
                    "\"\"\""
                    ZeroOrMore {
                        ChoiceOf {
                            "\\\""
                            NegativeLookahead { "\"\"\"" }
                            /./
                        }
                    }
                    "\"\"\""
                }
                // '''...''' (簡易)
                Regex {
                    "'''"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'''" }
                            /./
                        }
                    }
                    "'''"
                }
                // "..."
                Regex {
                    "\""
                    ZeroOrMore {
                        ChoiceOf {
                            "\\\""
                            NegativeLookahead { "\"" }
                            /./
                        }
                    }
                    "\""
                }
                // '...'
                Regex {
                    "'"
                    ZeroOrMore {
                        ChoiceOf {
                            "\\'"
                            NegativeLookahead { "'" }
                            /./
                        }
                    }
                    "'"
                }
            }
        }
        
        // Dartの識別子 (簡易): [a-zA-Z_][a-zA-Z0-9_]*
        let dartIdentifierRegex = Regex {
            ChoiceOf {
                CharacterClass("a"..."z", "A"..."Z")
                "_"
            }
            ZeroOrMore {
                ChoiceOf {
                    CharacterClass("a"..."z", "A"..."Z", "0"..."9")
                    "_"
                }
            }
        }
        
        return LanguageConfiguration(
            name: "Dart",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: false,
            stringRegex: dartStringRegex,
            characterRegex: nil, // Dartにも単一文字リテラルは特にない
            numberRegex: dartNumberRegex,
            singleLineComment: "//",
            nestedComment: (open: "/*", close: "*/"),
            identifierRegex: dartIdentifierRegex,
            operatorRegex: nil,
            reservedIdentifiers: dartReservedKeywords,
            reservedOperators: dartReservedOperators,
            languageService: languageService
        )
    }
    
    // MARK: - JSON
    
    /// シンプルなJSONのLanguageConfiguration
    /// - コメント: JSONには公式にはコメントが無いためnil
    /// - 文字列: ダブルクォートのみ
    /// - 数値: JSONのフォーマットに準拠した簡易正規表現
    /// - true, false, null を予約語として扱う
    public static func json(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        // JSONの文字列 (基本的にダブルクォートのみ)
        // エスケープなど厳密にやろうとすると長くなるので簡易版
        let jsonStringRegex = Regex {
            "\""
            ZeroOrMore {
                ChoiceOf {
                    "\\\""         // \" のエスケープ
                    "\\\\"         // \\ のエスケープ
                    NegativeLookahead { "\"" }
                    /./
                }
            }
            "\""
        }
        
        // JSONの数値 (簡易):
        // -?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?
        // ただしここでは既存の部分を組み合わせてもOK
        let jsonNumberRegex = Regex {
            // オプションの負号
            optNegation
            ChoiceOf {
                // 0
                "0"
                // 先頭が1-9のとき後続に任意の桁
                Regex {
                    CharacterClass("1"..."9")
                    ZeroOrMore(.digit)
                }
            }
            // 小数部
            Optionally {
                "."
                OneOrMore(.digit)
            }
            // 指数部
            Optionally {
                exponentLit
            }
        }
        
        // JSONには「true」「false」「null」というリテラルがある
        let jsonReservedIdentifiers = ["true", "false", "null"]
        
        return LanguageConfiguration(
            name: "JSON",
            supportsSquareBrackets: true,    // JSON配列で使用
            supportsCurlyBrackets: true,     // JSONオブジェクトで使用
            indentationSensitiveScoping: false,
            stringRegex: jsonStringRegex,
            characterRegex: nil,
            numberRegex: jsonNumberRegex,
            singleLineComment: nil,  // 公式にはコメントなし
            nestedComment: nil,      // 同上
            // JSONには特に識別子という概念はないが、キーを"..."以外で書くのは非標準なので不要
            identifierRegex: nil,
            operatorRegex: nil,
            reservedIdentifiers: jsonReservedIdentifiers,
            reservedOperators: [],
            languageService: languageService
        )
    }
}
