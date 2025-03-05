//
//  PythonConfiguration.swift
//  CodeEditorView
//
//  Created by yuki on 2025/03/02.
//

import Foundation
import RegexBuilder

private let pythonReservedIdentifiers = [
    "False", "None", "True",
    "and", "as", "assert", "async", "await",
    "break", "class", "continue",
    "def", "del",
    "elif", "else", "except",
    "finally", "for", "from",
    "global",
    "if", "import", "in", "is",
    "lambda",
    "nonlocal", "not",
    "or",
    "pass",
    "raise", "return",
    "try",
    "while", "with",
    "yield",
    // Python 3.10+
    "match", "case"
]

private let pythonReservedOperators = [
    // Arithmetic
    "+", "-", "*", "**", "/", "//", "%",
    // Matrix multiplication
    "@",
    // Bitwise
    "&", "|", "^", "~", "<<", ">>",
    // Assignment expression
    ":=",
    // Comparison
    "<", ">", "<=", ">=", "==", "!="
]

private let optSign = Optionally {
    CharacterClass(.anyOf("+-"))
}

/// Captures a decimal integer literal with optional underscores (e.g. `123`, `1_000`, `42`).
///
/// Equivalent idea: `[0-9](_?[0-9])*`
private let pythonDecimalLit = Regex {
    OneOrMore(.digit)
    ZeroOrMore {
        "_"
        OneOrMore(.digit)
    }
}

/// Captures a binary literal after `0b` or `0B`, allowing underscores (e.g. `0b1101`, `0b1_101`).
///
/// Equivalent idea: `[0-1](_?[0-1])*`
private let pythonBinaryLit = Regex {
    OneOrMore(CharacterClass(.anyOf("01")))
    ZeroOrMore {
        "_"
        OneOrMore(CharacterClass(.anyOf("01")))
    }
}

/// Captures an octal literal after `0o` or `0O`, allowing underscores (e.g. `0o777`, `0o7_77`).
///
/// Equivalent idea: `[0-7](_?[0-7])*`
private let pythonOctalLit = Regex {
    OneOrMore(CharacterClass(.anyOf("01234567")))
    ZeroOrMore {
        "_"
        OneOrMore(CharacterClass(.anyOf("01234567")))
    }
}

/// Captures a hexadecimal literal after `0x` or `0X`, allowing underscores (e.g. `0x1f`, `0xAB_CD`).
///
/// Equivalent idea: `[0-9A-Fa-f](_?[0-9A-Fa-f])*`
private let pythonHexLit = Regex {
    OneOrMore(CharacterClass(.hexDigit))
    ZeroOrMore {
        "_"
        OneOrMore(CharacterClass(.hexDigit))
    }
}

/// Captures an exponent part for decimal floats, allowing underscores (e.g. `e+10`, `E-10`, `e10`, `e1_000`).
///
/// Equivalent idea: `[eE][+\-]?[0-9](_?[0-9])*`
private let pythonExponentLit = Regex {
    CharacterClass(.anyOf("eE"))
    Optionally {
        CharacterClass(.anyOf("+-"))
    }
    OneOrMore(.digit)
    ZeroOrMore {
        "_"
        OneOrMore(.digit)
    }
}

/// Regex to capture Python numeric literals, including:
///  - Optional sign
///  - Binary, octal, hex
///  - Integer, float (with optional exponent), or hex float
///
/// *Note:* Does not handle complex literals with a trailing `j`/`J`.
private let pythonNumberRegex = Regex {
    optSign
    ChoiceOf {
        // 0b / 0B binary
        Regex {
            "0"
            CharacterClass(.anyOf("bB"))
            pythonBinaryLit
        }
        // 0o / 0O octal
        Regex {
            "0"
            CharacterClass(.anyOf("oO"))
            pythonOctalLit
        }
        // 0x / 0X hex (int or possibly hex float)
        Regex {
            "0"
            CharacterClass(.anyOf("xX"))
            // Optionally a hex float: 0x1.2p3, 0x1.2p-3, etc.
            ChoiceOf {
                // Hex float: e.g. 0x1.2p3
                Regex {
                    pythonHexLit
                    "."
                    pythonHexLit
                    // The exponent in hex floats is `p` or `P`, optionally signed decimal
                    CharacterClass(.anyOf("pP"))
                    optSign
                    pythonDecimalLit
                }
                // Simple hex integer: e.g. 0x1f, 0xAB_CD
                pythonHexLit
            }
        }
        // Decimal float or integer:
        //  - 123.456 (with optional exponent)
        //  - 123e45
        //  - 123
        Regex {
            pythonDecimalLit
            ChoiceOf {
                // float: 123.456, 123.456e+10, etc.
                Regex {
                    "."
                    pythonDecimalLit
                    Optionally {
                        pythonExponentLit
                    }
                }
                // float with exponent only: 123e45
                pythonExponentLit
                // or just plain integer: 123
                Regex {}
            }
        }
    }
}

/// Python supports multiple ways of quoting strings:
///  - Single quotes: '...'
///  - Double quotes: "..."
///  - Triple single quotes: '''...'''
///  - Triple double quotes: """..."""
///  - Raw strings, f-strings, etc. (not fully distinguished here, but recognized as strings)
///
/// Below is a simplified single-regex approach using alternation for the main cases.
/// This handles basic escaping but doesn't cover all intricacies of multiline triple-quoted strings.
/// (In many editors, multiline handling may be done differently.)
private let pythonStringRegex: Regex<Substring> = Regex {
    ChoiceOf {
        // Triple double quotes (non-greedy)
        Regex {
            "\"\"\""
            ZeroOrMore {
                // Either a backslash-escaped anything or (negative lookahead for `"""`) any character
                ChoiceOf {
                    "\\\""
                    NegativeLookahead { "\"\"\"" }
                    /./
                }
            }
            "\"\"\""
        }
        // Triple single quotes (non-greedy)
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
        // Single double-quoted string
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
        // Single single-quoted string
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

/// Python identifiers:
///  - May begin with a letter (Unicode) or underscore
///  - Followed by any number of letters, digits, or underscores
///
/// Below is a simplified approach: `[a-zA-Z_][a-zA-Z0-9_]*`.
/// Real Python 3 supports a broader range of Unicode identifier chars, but this covers the basics.
private let pythonIdentifierRegex = Regex {
    // Head
    ChoiceOf {
        CharacterClass(.word)
        "_"
    }
    // Body
    ZeroOrMore {
        ChoiceOf {
            CharacterClass(.word, .digit)
            "_"
        }
    }
}

extension LanguageConfiguration {
    
    /// Language configuration for Python
    public static func python(_ languageService: LanguageService? = nil) -> LanguageConfiguration {
        // Python uses indentation to define scopes, so we set `indentationSensitiveScoping` to `true`.
        // Python certainly uses both square brackets `[]` (lists, indexing) and curly braces `{}` (dict, set),
        // although not for scoping. We enable bracket support for editor features such as matching.
        return LanguageConfiguration(
            name: "Python",
            supportsSquareBrackets: true,
            supportsCurlyBrackets: true,
            indentationSensitiveScoping: true,
            // Single-line and multiline strings handled by the multi-alternation above.
            stringRegex: pythonStringRegex,
            // Python has no dedicated character literal (use strings for single chars), so nil here.
            characterRegex: nil,
            numberRegex: pythonNumberRegex,
            // Single-line comment: `# ...`, no built-in block comment syntax in Python.
            singleLineComment: "#",
            nestedComment: nil,
            // Identifiers
            identifierRegex: pythonIdentifierRegex,
            operatorRegex: nil, // We can optionally define a custom operator regex if needed
            reservedIdentifiers: pythonReservedIdentifiers,
            reservedOperators: pythonReservedOperators,
            languageService: languageService
        )
    }
}
