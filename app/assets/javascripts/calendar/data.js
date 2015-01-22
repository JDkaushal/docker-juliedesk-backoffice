Calendar.prototype.getCalendarsColors = function () {
    return {
        "0": {
            "background": "#999",
            "foreground": "#bbb"
        },
        "1": {
            "background": "#ac725e",
            "foreground": "#1d1d1d"
        },
        "2": {
            "background": "#d06b64",
            "foreground": "#1d1d1d"
        },
        "3": {
            "background": "#f83a22",
            "foreground": "#1d1d1d"
        },
        "4": {
            "background": "#fa573c",
            "foreground": "#1d1d1d"
        },
        "5": {
            "background": "#ff7537",
            "foreground": "#1d1d1d"
        },
        "6": {
            "background": "#ffad46",
            "foreground": "#1d1d1d"
        },
        "7": {
            "background": "#42d692",
            "foreground": "#1d1d1d"
        },
        "8": {
            "background": "#16a765",
            "foreground": "#1d1d1d"
        },
        "9": {
            "background": "#7bd148",
            "foreground": "#1d1d1d"
        },
        "10": {
            "background": "#b3dc6c",
            "foreground": "#1d1d1d"
        },
        "11": {
            "background": "#fbe983",
            "foreground": "#1d1d1d"
        },
        "12": {
            "background": "#fad165",
            "foreground": "#1d1d1d"
        },
        "13": {
            "background": "#92e1c0",
            "foreground": "#1d1d1d"
        },
        "14": {
            "background": "#9fe1e7",
            "foreground": "#1d1d1d"
        },
        "15": {
            "background": "#9fc6e7",
            "foreground": "#1d1d1d"
        },
        "16": {
            "background": "#4986e7",
            "foreground": "#1d1d1d"
        },
        "17": {
            "background": "#9a9cff",
            "foreground": "#1d1d1d"
        },
        "18": {
            "background": "#b99aff",
            "foreground": "#1d1d1d"
        },
        "19": {
            "background": "#c2c2c2",
            "foreground": "#1d1d1d"
        },
        "20": {
            "background": "#cabdbf",
            "foreground": "#1d1d1d"
        },
        "21": {
            "background": "#cca6ac",
            "foreground": "#1d1d1d"
        },
        "22": {
            "background": "#f691b2",
            "foreground": "#1d1d1d"
        },
        "23": {
            "background": "#cd74e6",
            "foreground": "#1d1d1d"
        },
        "24": {
            "background": "#a47ae2",
            "foreground": "#1d1d1d"
        }
    };
};
Calendar.prototype.getTimeZones = function () {
    return [
        ["MIT", "Midway Islands Time", -39600],
        ["HAST", "Hawaii Standard Time", -36000],
        ["AKST", "Alaska Standard Time", -32400],
        ["AKDT", "Alaska Daylight Saving Time", -28800],
        ["PST", "Pacific Standard Time", -28800],
        ["PDT", "Pacific Daylight Saving Time", -25200],
        ["MST", "Mountain Standard Time", -25200],
        ["MDT", "Mountain Daylight Saving Time", -21600],
        ["CST", "Central Standard Time", -21600],
        ["CDT", "Central Daylight Saving Time", -18000],
        ["EST", "Eastern Standard Time", -18000],
        ["EDT", "Eastern Daylight Saving Time", -14400],
        ["PRT", "Puerto Rico and US Virgin Islands Time", -14400],
        ["CNT", "Canada Newfoundland Time", -12600],
        ["AGT", "Argentina Standard Time", -10800],
        ["BET", "Brazil Eastern Time", -10800],
        ["CAT", "Central African Time", -3600],


        ["UTC/GMT", "Greenwich Mean Time", 0],
        ["WET", "Western European Time", 0],
        ["WEST", "Western European Summer Time", 3600],


        ["CET", "Central European Time", 3600],
        ["CEST", "Central European Summer Time", 7200],
        ["EET", "Eastern European Time", 7200],
        ["EEST", "Eastern European Summer Time", 10800],
        ["ART", "(Arabic) Egypt Standard Time", 7200],
        ["EAT", "Eastern African Time", 10800],
        ["MET", "Middle East Time", 12600],
        ["NET", "Near East Time", 14400],
        ["PLT", "Pakistan Lahore Time", 18000],
        ["IST", "India Standard Time", 19800],
        ["BST", "Bangladesh Standard Time", 21600],
        ["ICT", "Indochina Time", 25200],
        ["CTT", "China Taiwan Time", 28800],
        ["AWST", "Australia Western Time", 28800],
        ["JST", "Japan Standard Time", 32400],
        ["ACST", "Australia Central Time", 34200],
        ["AEST", "Australia Eastern Time", 36000],
        ["SST", "Solomon Standard Time", 39600],
        ["NZST", "New Zealand Standard Time", 43200],
        ["NZDT", "New Zealand Daylight Saving Time", 46800]
    ];
};