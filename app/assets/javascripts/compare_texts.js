
function compareArrays(arrayA, arrayB, startIndexA) {
    var startIndexB = arrayB.indexOf(arrayA[startIndexA]);
    if(startIndexB > -1) {
        var [minIndexA, minIndexB] = findSimilaritiesUpOrDown(arrayA, arrayB, startIndexA, startIndexB, -1);
        var [maxIndexA, maxIndexB] = findSimilaritiesUpOrDown(arrayA, arrayB, startIndexA, startIndexB, 1);
        return [
            [
                [minIndexA, maxIndexA],
                [minIndexB, maxIndexB],
            ]
        ];
    }
    else {
        return [];
    }

}
function go(arrayA, arrayB, complexity) {
    var indexesA = chooseIndexes(arrayA.length, complexity);
    var totalCorrectIndexes = [];
    for(var i=0; i < indexesA.length; i++) {
        var indexA = indexesA[i];
        if(!indexIsInCorrectIndexes(indexA, totalCorrectIndexes, 0)) {

            var foundCorrectIndexes = compareArrays(arrayA, arrayB, indexA);
            for(var j=0; j<foundCorrectIndexes.length; j++) {
                totalCorrectIndexes.push(foundCorrectIndexes[j]);
            }
        }
    }
    return totalCorrectIndexes;
}

function chooseIndexes(arrayLength, numberOfIndexes) {
    var result = [];
    if(arrayLength <= numberOfIndexes) {
        for(var i=0; i<arrayLength; i++) {
            result.push(i);
        }
    }
    else {
        for(var i=0; i<numberOfIndexes; i++) {
            result.push(Math.floor(i*(arrayLength -1)/(numberOfIndexes -1)));
        }
    }
    return result;
}

function indexIsInCorrectIndexes(index, correctIndexes, offsetAOrB) {

    for(var i in correctIndexes) {
        var correctIndex = correctIndexes[i][0];
        if(correctIndex[0] <= index && correctIndex[1] >= index) {
            return true;
        }
    }
    return false;
}

function findSimilaritiesUpOrDown(arrayA, arrayB, indexA, indexB, dec) {
    if(indexA < 0 || indexB < 0 || indexA >= arrayA.length || indexB >= arrayB.length || arrayA[indexA] != arrayB[indexB]) {
        return [indexA - dec, indexB - dec];
    }
    else {
        return findSimilaritiesUpOrDown(arrayA, arrayB, indexA + dec, indexB + dec, dec);
    }
}

function compareTexts(textA, textB) {
    var arrayA = textA.split(" ");
    var arrayB = textB.split(" ");
    var correctIndexes = go(arrayA, arrayB, 10);
    var resultA = [];
    var resultB = [];
    for(var i=0; i<arrayA.length; i++) {
        var wordA = arrayA[i];
        if(indexIsInCorrectIndexes(i, correctIndexes, 0)) {
            resultA.push(wordA);
        }
        else {
            resultA.push("<span class='error'>" + wordA + "</span>")
        }
    }
    for(var i=0; i<arrayB.length; i++) {
        var wordB = arrayB[i];
        if(indexIsInCorrectIndexes(i, correctIndexes, 1)) {
            resultB.push(wordB);
        }
        else {
            resultB.push("<span class='error'>" + wordB + "</span>")
        }
    }
    return [
        resultA.join(" "),
        resultB.join(" "),
    ]
}

// var a = ['a', 'b', 'c', 'e'];
// var b = ['b', 'a', 'b', 'c', 'd'];
// ta = "Allow me to suggest John and Nicolas's availabilities for an appointment: (Paris time) - Today, Wednesday 23 November at 3:00am, 1:00pm or 4:00pm Which time works best for you?"
// tb = "Allow me to suggest Nicolas and John's availabilities for an appointment: (Paris time) - Today, wednesday, November 23 at 3:00 am, 1:00 pm or 4:00 pmWhich time works best for you?"
// JSON.stringify(compareTexts(ta, tb), null, 2);