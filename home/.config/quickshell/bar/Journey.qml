// The daily quote: one short classic line a day, with its author (all public domain). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var lines: [
        ["The impediment to action advances action.", "Marcus Aurelius"],
        ["Waste no more time arguing what a good man should be. Be one.", "Marcus Aurelius"],
        ["You have power over your mind, not outside events.", "Marcus Aurelius"],
        ["We suffer more often in imagination than in reality.", "Seneca"],
        ["While we wait for life, life passes.", "Seneca"],
        ["A journey of a thousand miles begins with a single step.", "Lao Tzu"],
        ["Nature does not hurry, yet everything is accomplished.", "Lao Tzu"],
        ["It does not matter how slowly you go, as long as you do not stop.", "Confucius"],
        ["Do nothing that is of no use.", "Miyamoto Musashi"],
        ["Perceive that which cannot be seen with the eye.", "Miyamoto Musashi"],
        ["Today is victory over yourself of yesterday.", "Miyamoto Musashi"],
        ["Fall seven times, stand up eight.", "Japanese proverb"],
        ["Every day is a journey, and the journey itself is home.", "Matsuo Bashō"],
        ["No man ever steps in the same river twice.", "Heraclitus"],
        ["Well begun is half done.", "Aristotle"],
        ["First say to yourself what you would be; then do what you have to do.", "Epictetus"],
        ["He who has a why to live can bear almost any how.", "Nietzsche"],
        ["The unexamined life is not worth living.", "Socrates"]
    ]
    readonly property var pick: {
        const d = new Date(), start = new Date(d.getFullYear(), 0, 0)
        return lines[Math.floor((d - start) / 86400000) % lines.length]
    }
    readonly property string quote: pick[0]
    readonly property string author: pick[1]
    function today() { return quote + "  — " + author }
}
