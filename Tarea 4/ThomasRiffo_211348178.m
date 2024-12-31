% Leer el archivo JSON
jsonStr = fileread('examples.json');
data = jsondecode(jsonStr);

% Obtener los nombres de los campos
nombresCampos = fieldnames(data);
totalArchivos = length(nombresCampos);

% Inicializar contador de notas correctas
notasCorrectas = 0;

fprintf('Total de archivos encontrados en JSON: %d\n\n', totalArchivos);

% Iterar sobre cada archivo
for i = 1:totalArchivos
    try
        % Obtener el nombre del archivo del JSON
        nombreJSON = nombresCampos{i};
        
        % Convertir el nombre al formato del archivo WAV
        partes = split(nombreJSON, '_');
        nombreWAV = sprintf('%s_%s_%s-%s-%s.wav', ...
            partes{1}, partes{2}, partes{3}, partes{4}, partes{5});
        
        % Obtener el pitch esperado del nombre del archivo
        pitchEsperado = str2double(partes{4});
        
        % Verificar si el archivo existe
        if ~exist(nombreWAV, 'file')
            fprintf('ERROR: El archivo %s no existe\n\n', nombreWAV);
            continue;
        end
        
        % Leer el archivo de audio
        [y, fs] = audioread(nombreWAV);
        
        % Tomar solo los primeros 3 segundos donde la nota se mantiene
        muestras = min(length(y), round(fs * 3));
        y = y(1:muestras);
        
        % Aplicar ventana de Hann
        N = length(y);
        ventana = hann(N);
        y = y .* ventana;
        
        % Calcular la FFT
        Y = fft(y);
        
        % Calcular el espectro de magnitud (solo frecuencias positivas)
        P2 = abs(Y/N);
        P1 = P2(1:floor(N/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        % Vector de frecuencias
        f = fs*(0:(N/2))/N;
        
        % Encontrar la frecuencia fundamental
        % Filtrar frecuencias muy bajas (< 20 Hz) y muy altas (> 5000 Hz)
        freqMask = (f >= 20) & (f <= 5000);
        [~, maxIndex] = max(P1 .* freqMask');
        freqFundamental = f(maxIndex);
        
        % Convertir frecuencia a nota MIDI
        % MIDI = 69 + 12*log2(f/440)
        midiCalculado = round(69 + 12*log2(freqFundamental/440));
        
        % Asegurarse de que está en el rango válido (21-108)
        midiCalculado = min(max(midiCalculado, 21), 108);
        
        % Comparar con el pitch esperado
        if midiCalculado == pitchEsperado
            notasCorrectas = notasCorrectas + 1;
        end
        
        % Mostrar información
        fprintf('Archivo: %s\n', nombreWAV);
        fprintf('Pitch esperado: %d, Pitch calculado: %d\n', pitchEsperado, midiCalculado);
        fprintf('Frecuencia fundamental: %.2f Hz\n', freqFundamental);
        if midiCalculado == pitchEsperado
            fprintf('Acierto: Sí\n\n');
        else
            fprintf('Acierto: No\n\n');
        end
        
    catch e
        fprintf('Error en archivo %d: %s\n', i, e.message);
        fprintf('Detalles del error:\n');
        fprintf('Línea: %d\n', e.stack(1).line);
        fprintf('Función: %s\n\n', e.stack(1).name);
    end
end

% Mostrar resultados finales
fprintf('\nResultados finales:\n');
fprintf('Notas correctas: %d de %d (%.2f%%)\n', ...
    notasCorrectas, totalArchivos, (notasCorrectas/totalArchivos)*100);
