//
//  main.swift
//  Math Statistic
//
//  Created by Акбар Уметов on 03.06.2020.
//  Copyright © 2020 aumetov. All rights reserved.
//

import Foundation
import CSV

// MARK: - Import CSV to Array

let inputStream = InputStream(fileAtPath: "/Users/aumetov/Downloads/array5.csv")!
let inputCsv = try! CSVReader(stream: inputStream)
var array = Array<String>()

while let row = inputCsv.next() {
    array.append(contentsOf: row)
}

var sampleArray = array.compactMap(Double.init)

sampleArray.sort()

var minDigit: Double = sampleArray.min()!
let maxDigit: Double = sampleArray.max()!

let rangeOfVariation = maxDigit - minDigit
print("Размах вариации: \(rangeOfVariation)")

let numberOfInterval = 20
print("Число интервалов: \(numberOfInterval)")

let h = (maxDigit - minDigit) / Double(numberOfInterval)
print("Длина частичного интервала: \(h)")

// MARK: - Class Interval (maybe problems with teoreticRate)

class Interval {
    var leftBorder: Double?
    var rightBorder: Double?
    var array: Array<Double>?
    var middleOfInterval: Double?
    var teoreticRate: Double?
    
    init(leftBorder: Double, rightBorder: Double, array: Array<Double>) {
        self.leftBorder = leftBorder
        self.rightBorder = rightBorder
        self.array = array
        self.middleOfInterval = (leftBorder + rightBorder) / 2
    }
    
    init(teoreticRate: Double) {
        self.teoreticRate = teoreticRate
    }
}

var intervalArray = Array<Interval>()

// MARK: - Categorized sample to intervals

var length = 0

for _ in 0..<numberOfInterval {
    var bordersOfIntervals = Array<Double>()
    
    while length < sampleArray.count && sampleArray[length] >= minDigit && minDigit + h >= sampleArray[length] {
        bordersOfIntervals.append(sampleArray[length])
        
        length += 1
    }

    intervalArray.append(Interval(leftBorder: minDigit, rightBorder: minDigit + h, array: bordersOfIntervals))
    
    minDigit += h
}

// MARK: - Write to .csv func

func writeChangedArray(intervalArray: [Interval]) {
    let outputStream = OutputStream(toFileAtPath: "/Users/aumetov/Documents/changedArray.csv", append: false)!
    let outputCsv = try! CSVWriter(stream: outputStream)
    
    try! outputCsv.write(field: "Левая граница")
    try! outputCsv.write(field: "Правая граница")
    try! outputCsv.write(field: "Частота попадания")
    try! outputCsv.write(field: "Теоретическая частота")
    
    for interval in intervalArray {
        try! outputCsv.write(row: [String(format: "%.3f", interval.leftBorder!),
                                   String(format: "%.3f", interval.rightBorder!),
                                   String(interval.array!.count),
                                   String(format: "%.3f", interval.teoreticRate!)])
    }
}

func writeArray(intervalArray: [Interval]) {
    let outputStream = OutputStream(toFileAtPath: "/Users/aumetov/Documents/array.csv", append: false)!
    let outputCsv = try! CSVWriter(stream: outputStream)
    
    try! outputCsv.write(field: "Левая граница")
    try! outputCsv.write(field: "Правая граница")
    try! outputCsv.write(field: "Частота попадания")
    
    for interval in intervalArray {
        try! outputCsv.write(row: [String(format: "%.3f", interval.leftBorder!),
                                   String(format: "%.3f", interval.rightBorder!),
                                   String(interval.array!.count)])
    }
}

writeArray(intervalArray: intervalArray)

// MARK: - Solve the pointExpectation, sampleVariance, imrovedVariance, and %ConfidenceInterval

var (sum, squareSum) = (0.0, 0.0)

var pointExpectation: Double?
var sampleVariance: Double?
var improvedVariance: Double?
var standartDeviation: Double?
var leftConfidenceInterval: Double?
var rightConfidenceInterval: Double?

for interval in intervalArray {
    var (expressionForExpectation, expressionForVariance) = (0.0, 0.0)
    
    expressionForExpectation = Double(interval.array!.count) * interval.middleOfInterval!
    expressionForVariance = Double(interval.array!.count) * pow(interval.middleOfInterval!, 2)
    
    sum += expressionForExpectation
    squareSum += expressionForVariance
}

pointExpectation = sum/Double(sampleArray.count)
print("Точечное математическое ожидание: \(String(format: "%.3f", pointExpectation!))")

sampleVariance = (squareSum / Double(sampleArray.count)) - pow((sum / Double(sampleArray.count)), 2)
print("Выборочная дисперсия: \(String(format: "%.3f", sampleVariance!))")

improvedVariance = (Double(sampleArray.count) / Double(sampleArray.count - 1)) * sampleVariance!
print("Исправленная дисперсия: \(String(format: "%.3f", improvedVariance!))")

standartDeviation = sqrt(improvedVariance!) // Выборочное среднее квадратическое отклонение
leftConfidenceInterval = pointExpectation! - (1.96 * standartDeviation! / sqrt(Double(sampleArray.count)))
rightConfidenceInterval = pointExpectation! + (1.96 * standartDeviation! / sqrt(Double(sampleArray.count)))
print("Доверительный интервал для математического ожидания: [\(String(format: "%.3f", leftConfidenceInterval!)); \(String(format: "%.3f", rightConfidenceInterval!))]")

// MARK: - Solve teoretic rate

var (singnificantLevel, gaussFunction, u) = (0.95, 0.0, 0.0)

for interval in intervalArray {
    u = (interval.middleOfInterval! - pointExpectation!) / standartDeviation!
    gaussFunction = (1 / (sqrt(2 * .pi))) * pow(M_E, -(pow(u, 2) / 2))
    interval.teoreticRate = ((Double(sampleArray.count) * h) / standartDeviation!) * gaussFunction
}
 
 // MARK: - Add borders

var i = 0

while i < intervalArray.count - 1 {
    if intervalArray[i].array!.count < 6 && intervalArray[i + 1].array!.count < 6 {
        var someArray = Array<Double>()

        someArray.append(contentsOf: intervalArray[i].array!)
        someArray.append(contentsOf: intervalArray[i + 1].array!)

        let interval = Interval(leftBorder: intervalArray[i].leftBorder!, rightBorder: intervalArray[i + 1].rightBorder!, array: someArray)
        interval.teoreticRate = intervalArray[i].teoreticRate! + intervalArray[i + 1].teoreticRate!
        
        intervalArray.remove(at: i)
        intervalArray[i] = interval

        i -= 1
    }

    i += 1
}

// MARK: - Solve ovservedValueOfCriterion

var observedValueOfCriterion = 0.0

for interval in intervalArray {
    observedValueOfCriterion += pow(Double(interval.array!.count) - interval.teoreticRate! ,2) / interval.teoreticRate!
}

var criticalPoint = 8.67

print("Хи квадрат для k-порядка: \(criticalPoint)")
print("Найденный Хи квадрат: \(String(format: "%.3f", observedValueOfCriterion))")

if observedValueOfCriterion > criticalPoint {
    print("Гипотеза о нормальном распределении опровергнута")
} else {
    print("Гипотеза о нормальном распределении не имеет оснований быть опровергнутой")
}

writeChangedArray(intervalArray: intervalArray)
