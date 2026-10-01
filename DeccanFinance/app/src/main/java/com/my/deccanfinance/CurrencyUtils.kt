package com.my.deccanfinance

fun numberToWords(n: Int): String {
    val units = arrayOf("", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen")
    val tens = arrayOf("", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety")

    if (n == 0) return "Zero"
    if (n < 0) return "Minus " + numberToWords(-n)

    var words = ""
    var num = n

    if (num >= 10000000) {
        words += numberToWords(num / 10000000) + " Crore "
        num %= 10000000
    }

    if (num >= 100000) {
        words += numberToWords(num / 100000) + " Lakh "
        num %= 100000
    }

    if (num >= 1000) {
        words += numberToWords(num / 1000) + " Thousand "
        num %= 1000
    }

    if (num >= 100) {
        words += numberToWords(num / 100) + " Hundred "
        num %= 100
    }

    if (num > 0) {
        if (words != "") words += "and "
        if (num < 20) {
            words += units[num]
        } else {
            words += tens[num / 10]
            if (num % 10 > 0) words += "-" + units[num % 10]
        }
    }

    return words.trim()
}
