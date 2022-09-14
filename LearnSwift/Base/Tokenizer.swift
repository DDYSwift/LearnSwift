//
//  Tokenizer.swift
//  LearnSwift
//
//  Created by ddy on 2022/9/13.
//

import Foundation
import NaturalLanguage
import CoreText

// [iOS 分词处理](https://www.jianshu.com/p/6539b0aee5c2)
// iOS 自带两种分词方式 NaturalLanguage 及 CFStringTokenizer
extension String {
    @available(iOS 12.0, *)
    public func NLTokenizer() -> [String] {
        let tokenizer = NaturalLanguage.NLTokenizer(unit: .word)
        tokenizer.string = self
        var keyWords: [String] = []

        tokenizer.enumerateTokens(in: startIndex..<endIndex) { tokenRange, _ in
            keyWords.append(String(self[tokenRange]))
            return true
        }
        return keyWords
    }
}

extension String {
    public func cStringTokenizer() -> [String] {
        let cString = self as CFString
        let nsString = self as NSString
        let cStringCount = nsString.length
        let ref = CFStringTokenizerCreate(
            nil,
            cString,
            CFRangeMake(0, cStringCount),
            kCFStringTokenizerUnitWord,
            CFLocaleCopyCurrent()
        )
        CFStringTokenizerAdvanceToNextToken(ref)
        var range: CFRange = CFStringTokenizerGetCurrentTokenRange(ref)
        var keywords: [String] = []
        var preTokenEndIndex: Int = -1
        while range.length > 0 {
            let defaultIndex = preTokenEndIndex + 1
            if defaultIndex < range.location {
                let ignoredRange = NSRange(
                    location: defaultIndex,
                    length: range.location - defaultIndex
                )
                let ignoredString = nsString
                    .substring(with: ignoredRange)
                keywords.append(ignoredString)
            }
            preTokenEndIndex = range.location + range.length - 1

            let keyWord = nsString
                .substring(with: NSRange(location: range.location, length: range.length))
            keywords.append(keyWord)

            CFStringTokenizerAdvanceToNextToken(ref)
            range = CFStringTokenizerGetCurrentTokenRange(ref)
        }

        if preTokenEndIndex + 1 < count {
            let ignoredLocation = preTokenEndIndex + 1
            let ignoredRange = NSRange(location: ignoredLocation, length: count - ignoredLocation)
            let ignoredString = nsString
                .substring(with: ignoredRange)
            keywords.append(ignoredString)
        }

        return keywords
    }
}
