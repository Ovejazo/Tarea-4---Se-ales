% Leer el archivo JSON
jsonStr = fileread('examples.json');
data = jsondecode(jsonStr);

% Obtener los nombres de los campos
nombresCampos = fieldnames(data);
totalArchivos = length(nombresCampos);

fprintf('Total de archivos encontrados en JSON: %d\n\n', totalArchivos);

% Iterar sobre cada archivo
for i = 1:totalArchivos
    try
        % Obtener el nombre del archivo del JSON
        nombreJSON = nombresCampos{i};
        fprintf('Procesando %d/%d: %s\n', i, totalArchivos, nombreJSON);
        
        % Convertir el nombre al formato del archivo WAV
        partes = split(nombreJSON, '_');
        nombreWAV = sprintf('%s_%s_%s-%s-%s.wav', ...
            partes{1}, partes{2}, partes{3}, partes{4}, partes{5});
        
        fprintf('Intentando leer: %s\n', nombreWAV);
        
        % Verificar si el archivo existe
        if ~exist(nombreWAV, 'file')
            fprintf('ERROR: El archivo %s no existe\n\n', nombreWAV);
            continue;
        end
        
        % Leer el archivo de audio
        [y, fs] = audioread(nombreWAV);
        fprintf('Archivo leído correctamente. Longitud: %d muestras, Fs: %d Hz\n\n', length(y), fs);
        
    catch e
        fprintf('Error en archivo %d: %s\n', i, e.message);
        fprintf('Detalles del error:\n');
        fprintf('Línea: %d\n', e.stack(1).line);
        fprintf('Función: %s\n\n', e.stack(1).name);
    end
end