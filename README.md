# Automatische Erkennung eines 4x6 Colorcheckers

## Beschreibung
Dieses MATLAB-Programm erkennt automatisch einen 4x6 Colorchecker in einem Bild, extrahiert die Farbwerte der einzelnen Felder und speichert diese in einer Textdatei. 

**Ausgabeformat der Textdatei:**
```
X-Koordinate  Y-Koordinate  R-Wert  G-Wert  B-Wert
```

Das Programm eignet sich besonders gut, wenn der Colorchecker gerade und nicht schräg aufgenommen wurde. Es kann nicht erkennen, ob ein Colorchecker fehlt.

## Funktionsweise
1. **Bildverarbeitung:**
   - Das Bild wird in Graustufen umgewandelt und geglättet.
   - Kanten werden mithilfe des Canny-Operators erkannt und nachbearbeitet.
   - Kleine Objekte werden entfernt.

2. **Erkennung der Farbfelder:**
   - Die Bounding Boxes potenzieller Farbfelder werden identifiziert.
   - Zu große oder zu kleine Rechtecke werden herausgefiltert.
   - Die verbleibenden Bounding Boxes werden analysiert und in ein regelmäßiges 4x6-Raster geordnet.

3. **Extraktion der Farbwerte:**
   - Die Farbwerte (R, G, B) an den erkannten Positionen werden ausgelesen.
   - Die Werte werden in einer Textdatei gespeichert.

## Anpassungen
- **Blurr-Faktor:** Zeile 27 (`imgaussfilt(gray, 0.2)`) kann angepasst werden.
- **Filterung von Rechtecken:** Zeilen 66 & 67 bestimmen, welche Rechtecke als valide Farbfelder gelten.

## Installation & Verwendung
### Voraussetzungen
- MATLAB (getestet mit MATLAB R2023a oder neuer)
- Ein Colorchecker-Bild als Eingabe

### Verwendung
1. Speichere das Skript `detect_colorchecker.m` in deinem MATLAB-Arbeitsverzeichnis.
2. Rufe die Funktion mit einem Bildpfad auf:
   ```matlab
   detect_colorchecker('Testbild3.CR2');
   ```
   Optional kann ein alternativer Name für die Ausgabedatei angegeben werden:
   ```matlab
   detect_colorchecker('Testbild3.CR2', 'output.txt');
   ```

3. Die erkannten Farbfelder und Farbwerte werden visualisiert und in `color_values.txt` gespeichert.

## Beispielbilder
Um das Programm zu testen, können verschiedene Testbilder verwendet werden:
```matlab
   detect_colorchecker('Testbild1.1.png');
   detect_colorchecker('Testbild2.png');
   detect_colorchecker('Testbild4.png');
   detect_colorchecker('Testbild5.png');
```

Die fünf Testbilder sind im Repository enthalten. Zusätzlich ist eine Beispiel-Ausgabedatei verfügbar, um die erwarteten Ergebnisse zu veranschaulichen.

## Autoren 
- Jan Ferber
- Teja Ebel

