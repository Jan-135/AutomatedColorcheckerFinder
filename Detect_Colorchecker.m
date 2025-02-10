clc; clear; close all;

% Funktionsweise:
% Das Programm erkennt automatisch einen 4x6 Colorchecker und findet die
% einzelnen Farben.
% Als Ausgabe erhält man eine Textdatei, in welcher die Farbwerte von den
% einzelnen Feldern gespeichert sind. 
% Format der Textdatei: x-Koordinate y-Koordinate R-Wert G-Wert B-Wert
% 
% Dieser automatische Colorchecker funktioniert besonders gut, wenn der
% Colorchecker gerade und nicht schräg aufgenommen wurde.
% Zudem muss ein Colorchecker vorhanden sein. Das Programm kann nicht
% erkennen, dass kein Colorchecker vorhanden ist.

% Anpassungen können an folgenden Stellen selber vorgenommen werden:
% Zeile 27: blurr-faktor
% Zeile 66 & 67: Hier werden mithilfe der Fläche eines Rechtecks zu große/zu
% kleine Rechtecke gefiltert



function detect_colorchecker(image_path, output_file)
    if nargin < 2
        output_file = 'coordinates.txt';
    end
    
    % Bild laden
    image = imread(image_path);
    gray = rgb2gray(image);
    
    % Bild glätten, um Details zu reduzieren
    blurred = imgaussfilt(gray, 0.2);
    
    % Kanten hervorheben mit festen Canny-Schwellenwerten
    edges = edge(blurred, 'Canny', [0.1, 0.3]);
    
    % Kantenbild erweitern und kleine Lücken schließen
    edges = imdilate(edges, strel('disk', 3));
    edges = imclose(edges, strel('disk', 5));
    
    % Kleine Objekte entfernen
    edges = bwareaopen(edges, 200);

    % Visualisierung der finalen Kantenerkennung
    figure;
    imshow(edges);
    title('Finale Kantenerkennung nach Filtern');
    
    % Konturen der Farbfelder finden
    stats = regionprops(edges, 'BoundingBox', 'Centroid', 'Area');
    
    % Nur quadratische Boxen behalten
    filtered_stats = [];
    areas = [];
    for k = 1:numel(stats)
        bbox = stats(k).BoundingBox;
        width = bbox(3);
        height = bbox(4);
        aspect_ratio = width / height;
        
        if aspect_ratio > 0.9 && aspect_ratio < 1.1  % Fast quadratische Objekte behalten
            filtered_stats = [filtered_stats; stats(k)];
            areas = [areas; width * height];
        end
    end
   

    % Durchschnittliche Fläche berechnen und Ausreißer filtern
    mean_area = mean(areas);
    area_threshold = mean_area * 0.2; % Untere Grenze 20% der Durchschnittsgröße
    upper_threshold = mean_area * 1.7; % Obere Grenze 170% der Durchschnittsgröße
    
    refined_stats = [];
    for k = 1:numel(filtered_stats)
        bbox = filtered_stats(k).BoundingBox;
        area = bbox(3) * bbox(4);
        if area > area_threshold && area < upper_threshold
            refined_stats = [refined_stats; filtered_stats(k)];
        end
    end

    % Visualisierung der erkannten Bounding Boxes nach Filtern
    figure;
    imshow(image);
    hold on;
    for k = 1:numel(refined_stats)
        rectangle('Position', refined_stats(k).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 2);
        plot(refined_stats(k).Centroid(1), refined_stats(k).Centroid(2), 'bx', 'MarkerSize', 8, 'LineWidth', 2);
    end
    hold off;
    title('Erkannte Bounding Boxes nach Filtern');
    
    % Zentren der verbleibenden Farbfelder extrahieren
    centroids = cat(1, refined_stats.Centroid);
    
    % Berechne dx und dy basierend auf direkten Nachbarn
    dx = []; dy = [];
    
    % Sortiere die Punkte nach y-Werten (Zeilenweise)
    [~, idx_y] = sort(centroids(:,2));
    centroids_sorted_y = centroids(idx_y, :);
    
    % Sortiere jede Zeile nach x-Werten
    rows = {}; 
    row_threshold = 50; 
    current_row = centroids_sorted_y(1, :);
    
    for i = 2:size(centroids_sorted_y, 1)
        if abs(centroids_sorted_y(i,2) - current_row(1,2)) < row_threshold
            current_row = [current_row; centroids_sorted_y(i, :)]; 
        else
            rows{end+1} = current_row; 
            current_row = centroids_sorted_y(i, :); 
        end
    end
    rows{end+1} = current_row; 
    
    % Berechne dx innerhalb jeder Zeile
    for r = 1:length(rows)
        row = rows{r};
        [~, idx_x] = sort(row(:,1)); 
        row_sorted_x = row(idx_x, :);
        for i = 1:size(row_sorted_x, 1) - 1
            dx = [dx, abs(row_sorted_x(i+1,1) - row_sorted_x(i,1))];
        end
    end
    
    % Berechne dy zwischen benachbarten Zeilen
    for r = 1:length(rows) - 1
        dy = [dy, abs(rows{r+1}(1,2) - rows{r}(1,2))]; 
    end
    
    avg_width = median(dx);
    avg_height = median(dy);

    % Rasterergänzung: 4 Zeilen x 6 Spalten
    expected_rows = 4;
    expected_cols = 6;
    
    % Bestimme das obere linke Feld als Referenzpunkt
    min_x = min(centroids(:,1));
    min_y = min(centroids(:,2));

    % Liste für das vollständige Raster
    complete_grid = [];

    % Erstelle das Raster basierend auf avg_width und avg_height
    for row = 0:expected_rows-1
        for col = 0:expected_cols-1
            new_x = min_x + col * avg_width;
            new_y = min_y + row * avg_height;
            
            % Prüfen, ob dieser Punkt schon existiert
            distances = sqrt((centroids(:,1) - new_x).^2 + (centroids(:,2) - new_y).^2);
            if min(distances) > 10  
                complete_grid = [complete_grid; new_x, new_y];
            else
                existing_idx = find(distances == min(distances), 1);
                complete_grid = [complete_grid; centroids(existing_idx, :)];
            end
        end
    end



    % Visualisierung des endgültigen Rasters
    figure;
    imshow(image);
    hold on;
    plot(complete_grid(:,1), complete_grid(:,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    title('Finale erkannte 24 Farbfelder');

    % RGB Werte extrahieren
    color_values = [];
    for i = 1:size(complete_grid, 1)
        x = round(complete_grid(i,1));
        y = round(complete_grid(i,2));
        
        % Sicherstellen, dass die Koordinaten im Bildbereich liegen
        if x > 0 && x <= size(image,2) && y > 0 && y <= size(image,1)
            rgb = image(y, x, :);
            color_values = [color_values; x, y, double(rgb(1)), double(rgb(2)), double(rgb(3))];
        end  
   
    end
    % Speichern der berechneten Koordinaten und Farben

    writematrix(color_values, 'color_values.txt', 'Delimiter', '\t');

    
end

% Beispielaufruf
%detect_colorchecker('Testbild4.png');
%detect_colorchecker('Testbild5.png');
%detect_colorchecker('Testbild1.1.png');
%detect_colorchecker('Testbild2.png');
detect_colorchecker('Testbild3.CR2')